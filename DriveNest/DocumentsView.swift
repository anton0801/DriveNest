import SwiftUI
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
