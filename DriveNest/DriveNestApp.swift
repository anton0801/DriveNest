
import SwiftUI
import Combine
import Firebase
import UserNotifications
import AppsFlyerLib
import AppTrackingTransparency

@main
struct DriveNestApp: App {
    
    @UIApplicationDelegateAdaptor(DriveNestAppDelegate.self) var driveNestAppDelegate
    
    var body: some Scene {
        WindowGroup {
            DriveCarSplashView()
                .preferredColorScheme(.dark)
        }
    }
}

class DriveNestAppDelegate: UIResponder, UIApplicationDelegate, AppsFlyerLibDelegate, MessagingDelegate, UNUserNotificationCenterDelegate, DeepLinkDelegate {
    
    private var driveLinkData: [AnyHashable: Any] = [:]
    private var nestConversionInfo: [AnyHashable: Any] = [:]
    
    private let nestSentFlag = "trackingDataSent"
    
    private var mergeTimer: Timer?
    
    func application(
        _ app: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        UIApplication.shared.registerForRemoteNotifications()
        AppsFlyerLib.shared().appsFlyerDevKey = AppConstants.appsFlyerDevKey
        AppsFlyerLib.shared().appleAppID = AppConstants.appsFlyerAppID
        AppsFlyerLib.shared().delegate = self
        AppsFlyerLib.shared().deepLinkDelegate = self
        
        if let pushInfo = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            extractNestFromPush(pushInfo)
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(activateNestMonitoring),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        return true
    }
    
    private let mergeTimerKey = "mergeTimer"
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    @objc private func activateNestMonitoring() {
        if #available(iOS 14.0, *) {
            AppsFlyerLib.shared().waitForATTUserAuthorization(timeoutInterval: 60)
            ATTrackingManager.requestTrackingAuthorization { _ in
                DispatchQueue.main.async {
                    AppsFlyerLib.shared().start()
                }
            }
        }
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        extractNestFromPush(response.notification.request.content.userInfo)
        completionHandler()
    }
    
    private func extractNestFromPush(_ payload: [AnyHashable: Any]) {
        var extractedLink: String?
        if let directLink = payload["url"] as? String {
            extractedLink = directLink
        } else if let nestedData = payload["data"] as? [String: Any],
                  let nestedLink = nestedData["url"] as? String {
            extractedLink = nestedLink
        }
        if let validLink = extractedLink {
            UserDefaults.standard.set(validLink, forKey: "temp_url")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                NotificationCenter.default.post(
                    name: NSNotification.Name("LoadTempURL"),
                    object: nil,
                    userInfo: ["temp_url": validLink]
                )
            }
        }
    }
    
    private func startMergeTimer() {
        mergeTimer?.invalidate()
        mergeTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { [weak self] _ in
            self?.dispatchMergedInfo()
        }
    }
    
    
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        extractNestFromPush(userInfo)
        completionHandler(.newData)
    }
    
    
    func didResolveDeepLink(_ result: DeepLinkResult) {
        guard case .found = result.status,
              let resolvedLink = result.deepLink else { return }
        guard !UserDefaults.standard.bool(forKey: nestSentFlag) else { return }
        driveLinkData = resolvedLink.clickEvent
        NotificationCenter.default.post(name: Notification.Name("deeplink_values"), object: nil, userInfo: ["deeplinksData": driveLinkData])
        mergeTimer?.invalidate()
        if !nestConversionInfo.isEmpty {
            dispatchMergedInfo()
        }
    }
    
    private func dispatchMergedInfo() {
        var mergedInfo = nestConversionInfo
        for (key, value) in driveLinkData {
            if mergedInfo[key] == nil {
                mergedInfo[key] = value
            }
        }
        dispatchData(info: mergedInfo)
        UserDefaults.standard.set(true, forKey: nestSentFlag)
    }
    
    func onConversionDataSuccess(_ data: [AnyHashable: Any]) {
        nestConversionInfo = data
        startMergeTimer()
        if !driveLinkData.isEmpty {
            dispatchMergedInfo()
        }
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        messaging.token { [weak self] token, error in
            guard error == nil, let validToken = token else { return }
            UserDefaults.standard.set(validToken, forKey: "fcm_token")
            UserDefaults.standard.set(validToken, forKey: "push_token")
        }
    }
    
    
    func dispatchData(info: [AnyHashable: Any]) {
        NotificationCenter.default.post(
            name: Notification.Name("ConversionDataReceived"),
            object: nil,
            userInfo: ["conversionData": info]
        )
    }
    
    func onConversionDataFail(_ error: Error) {
        dispatchData(info: [:])
    }
    
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let payload = notification.request.content.userInfo
        extractNestFromPush(payload)
        completionHandler([.banner, .sound])
    }
    
}
