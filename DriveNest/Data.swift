import SwiftUI

//struct Car: Identifiable {
//    let id = UUID()
//    var name: String
//    var model: String
//    var mileage: Double
//    var imageName: String = "tesla"
//    var lastExpenses: Double = 0
//    var documentStatus: DocumentStatus = .ok
//}

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

struct Reminder: Identifiable {
    let id = UUID()
    var name: String
    var date: Date
    var interval: String
    var isOn: Bool
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
    Reminder(name: "Oil Check", date: Date().addingTimeInterval(30*86400), interval: "Monthly", isOn: true),
    Reminder(name: "Tire Pressure", date: Date().addingTimeInterval(7*86400), interval: "Weekly", isOn: false)
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
