import SwiftUI
import WebKit
import UniformTypeIdentifiers

struct DocumentsView: View {
    
    @EnvironmentObject var appData: AppData
    let car: Car
    
    private var documents: Binding<[CarDocument]> {
        Binding(
            get: { appData.cars.first(where: { $0.id == car.id })?.documents ?? [] },
            set: { newValue in
                if let index = appData.cars.firstIndex(where: { $0.id == car.id }) {
                    appData.cars[index].documents = newValue
                }
            }
        )
    }
    
    @State private var showingDocumentPicker = false
    @State private var showingAddCustom = false
    
    var body: some View {
        ZStack {
            BackgroundView()
                .overlay(
                    Image(systemName: "feather.fill")
                        .font(.system(size: 180))
                        .foregroundColor(.goldNeon.opacity(0.08))
                        .offset(x: 80, y: 220)
                )
            
            if documents.wrappedValue.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.goldNeon.opacity(0.4))
                    Text("No documents yet")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("Tap + to add insurance, registration, or any file")
                        .foregroundColor(.secondary.opacity(0.7))
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 18) {
                        ForEach(documents.wrappedValue) { doc in
                            DocumentRow(doc: doc, onDelete: {
                                documents.wrappedValue.removeAll { $0.id == doc.id }
                            })
                        }
                    }
                    .padding()
                }
            }
            
            VStack {
                Spacer()
                Button("Add Document") { showingDocumentPicker = true }
                    .buttonStyle(NeonButtonStyle())
                    .padding(.horizontal, 40)
                    .padding(.bottom, 30)
            }
        }
        .navigationTitle("Documents")
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPicker { url in
                let copyURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    .appendingPathComponent(url.lastPathComponent)
                
                try? FileManager.default.copyItem(at: url, to: copyURL)
                
                let newDoc = CarDocument(title: url.deletingPathExtension().lastPathComponent, fileURL: copyURL)
                documents.wrappedValue.append(newDoc)
            }
        }
    }
}

struct DocumentRow: View {
    let doc: CarDocument
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: doc.fileURL?.pathExtension.lowercased() == "pdf" ? "doc.richtext" : "photo")
                .font(.system(size: 36))
                .foregroundColor(.goldNeon)
                .frame(width: 60)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(doc.title)
                    .font(.title3.bold())
                    .foregroundColor(.white)
                
                if let date = doc.expirationDate {
                    Text("Expires: \(date, format: .dateTime.day().month().year())")
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button { onDelete() } label: {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28))
        .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color.goldNeon.opacity(0.3), lineWidth: 1))
    }
}


class NestNavigationManager: NSObject, WKNavigationDelegate, WKUIDelegate {
    
    private var redirectCounter = 0
    
    init(supervisor: NestSupervisor) {
        self.nestSupervisor = supervisor
        super.init()
    }
    
    private var nestSupervisor: NestSupervisor
    
    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for action: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard action.targetFrame == nil else { return nil }
        
        let newView = WKWebView(frame: .zero, configuration: configuration)
        configNewView(newView)
        setConstraintsFor(newView)
        
        nestSupervisor.extraNestViews.append(newView)
        
        let swipeRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(processSwipe))
        swipeRecognizer.edges = .left
        newView.addGestureRecognizer(swipeRecognizer)
        
        func isRequestValid(_ request: URLRequest) -> Bool {
            guard let urlStr = request.url?.absoluteString,
                  !urlStr.isEmpty,
                  urlStr != "about:blank" else { return false }
            return true
        }
        
        if isRequestValid(action.request) {
            newView.load(action.request)
        }
        
        return newView
    }
    
    private var lastURL: URL?
    
    private let redirectMax = 70
    
    func webView(_ webView: WKWebView,
                 didReceive challenge: URLAuthenticationChallenge,
                 completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let serverTrust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
    
    private func configNewView(_ webView: WKWebView) {
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.scrollView.isScrollEnabled = true
        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.maximumZoomScale = 1.0
        webView.scrollView.bounces = false
        webView.scrollView.bouncesZoom = false
        webView.allowsBackForwardNavigationGestures = true
        webView.navigationDelegate = self
        webView.uiDelegate = self
        nestSupervisor.primaryNestView.addSubview(webView)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let scriptEnhance = """
        (function() {
            const vp = document.createElement('meta');
            vp.name = 'viewport';
            vp.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
            document.head.appendChild(vp);
            
            const rules = document.createElement('style');
            rules.textContent = 'body { touch-action: pan-x pan-y; } input, textarea { font-size: 16px !important; }';
            document.head.appendChild(rules);
            
            document.addEventListener('gesturestart', e => e.preventDefault());
            document.addEventListener('gesturechange', e => e.preventDefault());
        })();
        """
        
        webView.evaluateJavaScript(scriptEnhance) { _, error in
            if let error = error { print("Enhance script failed: \(error)") }
        }
    }
    
    @objc private func processSwipe(_ recognizer: UIScreenEdgePanGestureRecognizer) {
        guard recognizer.state == .ended,
              let swipedView = recognizer.view as? WKWebView else { return }
        
        if swipedView.canGoBack {
            swipedView.goBack()
        } else if nestSupervisor.extraNestViews.last === swipedView {
            nestSupervisor.stepBackNest(to: nil)
        }
    }
    
    private func storeData(from webView: WKWebView) {
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
            var dataDict: [String: [String: [HTTPCookiePropertyKey: Any]]] = [:]
            
            for cookie in cookies {
                var domainDict = dataDict[cookie.domain] ?? [:]
                if let properties = cookie.properties {
                    domainDict[cookie.name] = properties
                }
                dataDict[cookie.domain] = domainDict
            }
            
            UserDefaults.standard.set(dataDict, forKey: "preserved_grains")
        }
    }
    
    func webView(_ webView: WKWebView,
                 runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping () -> Void) {
        completionHandler()
    }
    
    func webView(_ webView: WKWebView,
                 didFailProvisionalNavigation navigation: WKNavigation!,
                 withError error: Error) {
        if (error as NSError).code == NSURLErrorHTTPTooManyRedirects,
           let safeURL = lastURL {
            webView.load(URLRequest(url: safeURL))
        }
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        redirectCounter += 1
        
        if redirectCounter > redirectMax {
            webView.stopLoading()
            if let safeURL = lastURL {
                webView.load(URLRequest(url: safeURL))
            }
            return
        }
        
        lastURL = webView.url
        storeData(from: webView)
    }
    
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        
        lastURL = url
        
        let schemeLower = (url.scheme ?? "").lowercased()
        let urlStringLower = url.absoluteString.lowercased()
        
        let internalSchemes: Set<String> = ["http", "https", "about", "blob", "data", "javascript", "file"]
        let internalPrefixes = ["srcdoc", "about:blank", "about:srcdoc"]
        
        let isInternal = internalSchemes.contains(schemeLower) ||
        internalPrefixes.contains { urlStringLower.hasPrefix($0) } ||
        urlStringLower == "about:blank"
        
        if isInternal {
            decisionHandler(.allow)
            return
        }
        
        UIApplication.shared.open(url, options: [:]) { _ in }
        
        decisionHandler(.cancel)
    }
    
    private func setConstraintsFor(_ webView: WKWebView) {
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: nestSupervisor.primaryNestView.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: nestSupervisor.primaryNestView.trailingAnchor),
            webView.topAnchor.constraint(equalTo: nestSupervisor.primaryNestView.topAnchor),
            webView.bottomAnchor.constraint(equalTo: nestSupervisor.primaryNestView.bottomAnchor)
        ])
    }
}


struct DocumentPicker: UIViewControllerRepresentable {
    var callback: (URL) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(callback)
    }
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf, .image])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var callback: (URL) -> Void
        
        init(_ callback: @escaping (URL) -> Void) {
            self.callback = callback
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            url.startAccessingSecurityScopedResource()
            callback(url)
            url.stopAccessingSecurityScopedResource()
        }
    }
}
