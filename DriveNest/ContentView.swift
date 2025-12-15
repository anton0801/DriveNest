import SwiftUI
import WebKit
import StoreKit
import Combine

struct ContentView: View {
    @State private var cars: [Car] = [
        Car(name: "My Tesla", model: "Model S Plaid", mileage: 28420),
        Car(name: "Daily", model: "BMW M3 Competition", mileage: 58700, documentStatus: .soon)
    ]
    
    @State private var showingGlobalSettings = false
    @State private var showAddCar = false
    @StateObject private var carStore = AppData()
    
    var body: some View {
        NavigationStack {
            ZStack {
                BackgroundView()
                
                if carStore.cars.isEmpty {
                    VStack {
                        Text("No cars yet")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("Tap + to add your first beast")
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 24) {
                            ForEach(carStore.cars) { car in
                                NavigationLink(destination: CarDetailView(car: car)
                                    .environmentObject(carStore)) {
                                    CarRowView(car: car)
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                        }
                        .padding(20)
                    }
                }
                
                VStack {
                    Spacer()
                    Button {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                            showAddCar = true
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [.goldNeon, .goldDark], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 70, height: 70)
                                .shadow(color: .goldNeon.opacity(0.8), radius: 20, y: 10)
                            
                            Image(systemName: "plus")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.deepBlack)
                        }
                    }
                    .scaleEffect(showAddCar ? 0.9 : 1)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showAddCar)
                }
                .padding(.bottom, 30)
            }
            .navigationTitle("Drive Nest")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Drive Nest")
                        .font(.largeTitle.bold())
                        .foregroundColor(.goldNeon)
                        .shadow(color: .goldNeon.opacity(0.5), radius: 10)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingGlobalSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.goldNeon)
                    }
                }
            }
            .sheet(isPresented: $showingGlobalSettings) {
                GlobalSettingsView()
            }
            .sheet(isPresented: $showAddCar) {
                AddCarView { newCar in
                    carStore.addCar(newCar)
                }
            }
        }
    }
}

struct GlobalSettingsView: View {
    
    @Environment(\.requestReview) var requestReview
    
    var body: some View {
        NavigationStack {
            List {
                Button("Privacy Policy") {
                    if let url = URL(string: "https://driivenest.com/privacy-policy.html") {
                        UIApplication.shared.open(url)
                    }
                }
                
                Button("Rate Drive Nest") {
                    requestReview()
                }
                
                Button("Contact Us") {
                    if let url = URL(string: "https://driivenest.com/support.html") {
                        UIApplication.shared.open(url)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

struct BackgroundView: View {
    var body: some View {
        ZStack {
            Color.asphalt.ignoresSafeArea()
            
            // Золотисто-фиолетовые блики
            GeometryReader { geo in
                Circle()
                    .fill(RadialGradient(colors: [.purpleNeon.opacity(0.3), .clear], center: .topLeading, startRadius: 50, endRadius: 400))
                    .offset(x: -100, y: -100)
                
                Circle()
                    .fill(RadialGradient(colors: [.goldNeon.opacity(0.25), .clear], center: .bottomTrailing, startRadius: 100, endRadius: 500))
                    .offset(x: geo.size.width - 100, y: geo.size.height + 100)
            }
        }
    }
}

struct CarRowView: View {
    let car: Car
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color.deepBlack)
                        .shadow(color: .black.opacity(0.7), radius: 20, y: 10)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .strokeBorder(LinearGradient(colors: [.goldNeon.opacity(0.4), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5)
                )
            
            HStack(spacing: 20) {
                // 3D машина с отражением лапки
                ZStack {
                    if car.imageData == nil {
                        Image("car")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .goldNeon.opacity(0.6), radius: 15, y: 8)
                    } else {
                        if let image = UIImage(data: car.imageData!) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: .goldNeon.opacity(0.6), radius: 15, y: 8)
                        } else {
                            Image("car")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: .goldNeon.opacity(0.6), radius: 15, y: 8)
                        }
                    }
                    
                    
                    // Отражение лапки в фаре
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.goldNeon.opacity(0.4))
                        .offset(x: 35, y: 25)
                        .blur(radius: 3)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(car.name)
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    Text(car.model)
                        .font(.headline)
                        .foregroundColor(.goldNeon)
                    
                    HStack {
                        Label("\(Int(car.mileage)) km", systemImage: "road.lanes")
                        Spacer()
                        Circle()
                            .fill(statusColor)
                            .frame(width: 12, height: 12)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.goldNeon.opacity(0.6))
            }
            .padding(24)
        }
        .frame(height: 180)
    }
    
    var statusColor: Color {
        switch car.documentStatus {
        case .ok: return .green
        case .soon: return .yellow
        case .expired: return .red
        }
    }
}

struct CarCardView: View {
    let car: Car
    
    var body: some View {
        NavigationLink(destination: CarDashboardView(car: car)) {
            HStack {
                ZStack {
                    Image(systemName: "car.fill")
                        .resizable()
                        .frame(width: 80, height: 40)
                        .foregroundColor(.metallicOutline)
                        .shadow(color: .whiteGlow, radius: 5)
                    Image(systemName: "pawprint")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.turquoiseLight.opacity(0.5))
                        .offset(x: 30, y: 10)
                }
                
                VStack(alignment: .leading) {
                    Text(car.name)
                        .font(.headline)
                        .foregroundColor(.whiteGlow)
                    Text("Mileage: \(car.mileage, specifier: "%.0f") km")
                        .font(.subheadline)
                        .foregroundColor(.metallicOutline)
                    Text("Last Expenses: $\(car.lastExpenses, specifier: "%.2f")")
                        .font(.subheadline)
                        .foregroundColor(.metallicOutline)
                    HStack {
                        Text("Documents:")
                        Circle()
                            .frame(width: 10, height: 10)
                            // .foregroundColor(statusColor(for: car.documentStatus))
                    }
                }
                .padding()
            }
            .background(Color.darkAsphalt.opacity(0.8))
            .cornerRadius(15)
            .shadow(color: .lightShadow, radius: 5)
        }
    }
    
    func statusColor(for status: StatusColor) -> Color {
        switch status {
        case .green: return .green
        case .yellow: return .yellow
        case .red: return .red
        }
    }
}


struct CarDetailView: View {
    let car: Car
    @State private var currentMileage: String = ""
    @EnvironmentObject var carStore: AppData
    
    @State private var showingMileageUpdate = false
    @State private var newMileage = ""
    
    var body: some View {
        ZStack {
            BackgroundView()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Главная карточка машины с 3D-эффектом
                    VStack(spacing: 20) {
                        ZStack {
                            if let image = car.uiImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 240)
                                    .clipShape(RoundedRectangle(cornerRadius: 32))
                                    .shadow(color: .goldNeon.opacity(0.7), radius: 30, y: 15)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 32)
                                            .strokeBorder(LinearGradient(colors: [.goldNeon.opacity(0.6), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2)
                                    )
                            } else {
                                Image("car")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 240)
                                    .clipShape(RoundedRectangle(cornerRadius: 32))
                                    .shadow(color: .goldNeon.opacity(0.7), radius: 30, y: 15)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 32)
                                            .strokeBorder(LinearGradient(colors: [.goldNeon.opacity(0.6), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2)
                                    )
                            }
                            
                            // Гравированное перо на капоте
                            Image(systemName: "feather.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.goldNeon.opacity(0.25))
                                .offset(y: -60)
                                .shadow(color: .goldNeon.opacity(0.4), radius: 20)
                        }
                        
                        VStack(spacing: 12) {
                            Text("\(Int(car.mileage)) km")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundColor(.goldNeon)
                                .shadow(color: .goldNeon.opacity(0.6), radius: 10)
                            
                            Button {
                                newMileage = String(Int(car.mileage))
                                withAnimation(.easeInOut) {
                                    showingMileageUpdate = true
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "speedometer")
                                    Text("Update Mileage")
                                }
                                .font(.headline)
                                .foregroundColor(.deepBlack)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    LinearGradient(colors: [.goldNeon, .goldDark], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .clipShape(Capsule())
                                .shadow(color: .goldNeon.opacity(0.8), radius: 20, y: 10)
                            }
                            .padding(.horizontal, 40)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Быстрые показатели
                    VStack(spacing: 16) {
                        QuickStatRow(title: "Avg. Fuel Consumption", value: "7.4 L/100km", color: .turquoise)
                        QuickStatRow(title: "Monthly Expenses", value: "$1,240", color: .orangeGloss)
                        QuickStatRow(title: "Last Refuel", value: "2 days ago", color: .purpleNeon)
                        QuickStatRow(title: "Last Service", value: "28 days ago", color: .goldNeon)
                    }
                    .padding(.horizontal)
                    
                    // Кликабельные плитки
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                        NavigationLink(destination: MaintenanceView(car: car)
                            .environmentObject(carStore)) {
                            DashboardTile(title: "Maintenance", icon: "wrench.fill", gradient: [.orangeGloss, .red])
                        }
                        NavigationLink(destination: RefuelsView(car: car)
                            .environmentObject(carStore)) {
                            DashboardTile(title: "Refuels", icon: "fuelpump.fill", gradient: [.turquoise, .cyan])
                        }
                        NavigationLink(destination: ExpensesView(car: car)
                            .environmentObject(carStore)) {
                            DashboardTile(title: "Expenses", icon: "dollarsign.circle.fill", gradient: [.purpleNeon, .purpleDeep])
                        }
                        NavigationLink(destination: DocumentsView(car: car).environmentObject(carStore)) {
                            DashboardTile(title: "Documents", icon: "doc.text.fill", gradient: [.goldNeon, .goldDark])
                        }
                        NavigationLink(destination: RemindersView(car: car).environmentObject(carStore)) {
                            DashboardTile(title: "Reminders", icon: "bell.fill", gradient: [.pink, .red])
                        }
                        NavigationLink(destination: CarSettingsView(car: car)) {
                            DashboardTile(title: "Settings", icon: "gearshape.fill", gradient: [.gray, .white])
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 100)
                }
            }
        }
        .navigationTitle(car.model)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(car.model)
                    .font(.title2.bold())
                    .foregroundColor(.goldNeon)
            }
        }
        .sheet(isPresented: $showingMileageUpdate) {
            MileageUpdateView(
                currentMileage: car.mileage,
                onSave: { newMileage in
                    carStore.updateMileage(for: car.id, newMileage: newMileage)
                }
            )
        }
    }
}

struct MileageUpdateView: View {
    @Environment(\.dismiss) var dismiss
    let currentMileage: Double
    let onSave: (Double) -> Void
    @State private var mileageText = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.deepBlack.ignoresSafeArea()
                
                VStack(spacing: 50) {
                    Text("New Mileage")
                        .font(.largeTitle.bold())
                        .foregroundColor(.goldNeon)
                    
                    TextField("", text: $mileageText)
                        .font(.system(size: 64, weight: .bold))
                        .multilineTextAlignment(.center)
                        .keyboardType(.numberPad)
                        .foregroundColor(.goldNeon)
                        .padding(40)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 32))
                    
                    Button("Save") {
                        if let newValue = Double(mileageText), newValue >= currentMileage {
                            onSave(newValue)
                            dismiss()
                        }
                    }
                    .buttonStyle(NeonButtonStyle())
                    .padding(.horizontal, 60)
                }
            }
            .onAppear { mileageText = String(Int(currentMileage)) }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.goldNeon)
                }
            }
        }
    }
}

struct QuickStatRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.title3.bold())
                .foregroundColor(color)
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct DashboardTile: View {
    let title: String
    let icon: String
    let gradient: [Color]
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 40, weight: .medium))
                .foregroundColor(.white)
                .shadow(color: gradient[0].opacity(0.8), radius: 15)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(
            LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .shadow(color: gradient[0].opacity(0.7), radius: 20, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .strokeBorder(LinearGradient(colors: [.white.opacity(0.3), .clear], startPoint: .top, endPoint: .bottom), lineWidth: 1.5)
        )
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct NeonButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.deepBlack)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(colors: [.goldNeon, .goldDark], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .clipShape(Capsule())
            .shadow(color: .goldNeon.opacity(0.8), radius: 20, y: 10)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
    }
}

struct AddCarView: View {
    @Environment(\.dismiss) var dismiss
    @State private var carName = ""
    @State private var carModel = ""
    @State private var mileage = ""
    @State private var selectedImage: UIImage? = nil
    @State private var showingImagePicker = false
    
    var onCarAdded: (Car) -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.deepBlack.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        Text("Add Your Beast")
                            .font(.largeTitle.bold())
                            .foregroundColor(.goldNeon)
                            .shadow(color: .goldNeon.opacity(0.6), radius: 10)
                        
                        // Фото машины
                        Button {
                            showingImagePicker = true
                        } label: {
                            if let image = selectedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 220)
                                    .clipShape(RoundedRectangle(cornerRadius: 32))
                                    .overlay(RoundedRectangle(cornerRadius: 32).stroke(Color.goldNeon.opacity(0.6), lineWidth: 2))
                            } else {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 32)
                                        .fill(.ultraThinMaterial)
                                        .frame(height: 220)
                                    VStack {
                                        Image(systemName: "car.fill")
                                            .font(.system(size: 60))
                                            .foregroundColor(.goldNeon)
                                        Text("Tap to add photo")
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        .sheet(isPresented: $showingImagePicker) {
                            ImagePicker(image: $selectedImage)
                        }
                        
                        // Поля ввода
                        VStack(spacing: 20) {
                            TextField("Car Name (e.g. My Beast)", text: $carName)
                                .textFieldStyle(NeonTextFieldStyle())
                            
                            TextField("Model (e.g. Tesla Model S Plaid)", text: $carModel)
                                .textFieldStyle(NeonTextFieldStyle())
                            
                            TextField("Current Mileage (km)", text: $mileage)
                                .keyboardType(.numberPad)
                                .textFieldStyle(NeonTextFieldStyle())
                        }
                        .padding(.horizontal)
                        
                        Button {
                            guard let mileageDouble = Double(mileage),
                                  !carName.isEmpty,
                                  !carModel.isEmpty else { return }
                            
                            var newCar = Car(name: carName, model: carModel, mileage: mileageDouble)
                            newCar.uiImage = selectedImage
                            
                            onCarAdded(newCar)
                            dismiss()
                        } label: {
                            Text("Add to Garage")
                                .font(.title2.bold())
                                .frame(maxWidth: .infinity)
                                .frame(height: 60)
                                .background(
                                    LinearGradient(colors: [.goldNeon, .goldDark], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .clipShape(Capsule())
                                .shadow(color: .goldNeon.opacity(0.9), radius: 20, y: 10)
                        }
                        .padding(.horizontal, 40)
                    }
                    .padding()
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.goldNeon)
                }
            }
        }
    }
}

struct NeonTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.title3)
            .padding(20)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.goldNeon.opacity(0.4), lineWidth: 1))
            .foregroundColor(.white)
    }
}

// ImagePicker (обязательно добавь в проект)
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
    }
}


#Preview {
    ContentView()
}

extension Color {
    static let goldenNeon = Color(hex: "#FFD84A")
    static let orangeGloss = Color(hex: "#FF8A00")
    static let darkAsphalt = Color(hex: "#1E1E1E")
    static let turquoiseLight = Color(hex: "#3ED4C9")
    static let whiteGlow = Color(hex: "#FFFFFF")
    static let lightShadow = Color(hex: "#0A0A0A")
    static let metallicOutline = Color(hex: "#C8C8C8")
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension Color {
    static let asphalt      = Color(hex: "#1A1A1A")      // #1A1A1A
    static let deepBlack    = Color(hex: "#0F0F0F")    // #0F0F0F
    static let goldNeon     = Color(hex: "#FFD84A")     // #FFD84A
    static let goldDark     = Color(hex: "#E5B843")     // #E5B843
    static let purpleNeon   = Color(hex: "#9D7AFF")   // #9D7AFF
    static let purpleDeep   = Color(hex: "#6B4CFF")   // #6B4CFF
    static let turquoise    = Color(hex: "#3ED4C9")    // #3ED4C9
}

struct DriveNestMainView: View {
    
    @State private var activeNestLink = ""
    
    var body: some View {
        ZStack {
            if let nestLink = URL(string: activeNestLink) {
                NestHostView(nestLink: nestLink)
                    .ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear(perform: configureStartLink)
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("LoadTempUrl"))) { _ in
            if let tempLink = UserDefaults.standard.string(forKey: "temp_url"), !tempLink.isEmpty {
                activeNestLink = tempLink
                UserDefaults.standard.removeObject(forKey: "temp_url")
            }
        }
    }
    
    private func configureStartLink() {
        let temp = UserDefaults.standard.string(forKey: "temp_url")
        let stored = UserDefaults.standard.string(forKey: "stored_config") ?? ""
        activeNestLink = temp ?? stored
        if temp != nil {
            UserDefaults.standard.removeObject(forKey: "temp_url")
        }
    }
}

struct NestHostView: UIViewRepresentable {
    let nestLink: URL
    
    @StateObject private var nestSupervisor = NestSupervisor()
    
    func makeCoordinator() -> NestNavigationManager {
        NestNavigationManager(supervisor: nestSupervisor)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        nestSupervisor.initPrimaryView()
        nestSupervisor.primaryNestView.uiDelegate = context.coordinator
        nestSupervisor.primaryNestView.navigationDelegate = context.coordinator
        
        nestSupervisor.fetchCachedData()
        nestSupervisor.primaryNestView.load(URLRequest(url: nestLink))
        
        return nestSupervisor.primaryNestView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

class NestSupervisor: ObservableObject {
    @Published var primaryNestView: WKWebView!
    
    private var subscriptionsSet = Set<AnyCancellable>()
    
    func initPrimaryView() {
        let configSetup = buildDefaultConfig()
        primaryNestView = WKWebView(frame: .zero, configuration: configSetup)
        setViewParams(on: primaryNestView)
    }
    
    private func buildDefaultConfig() -> WKWebViewConfiguration {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        
        let prefs = WKPreferences()
        prefs.javaScriptEnabled = true
        prefs.javaScriptCanOpenWindowsAutomatically = true
        config.preferences = prefs
        
        let pagePrefs = WKWebpagePreferences()
        pagePrefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = pagePrefs
        
        return config
    }
    
    private func setViewParams(on webView: WKWebView) {
        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.maximumZoomScale = 1.0
        webView.scrollView.bounces = false
        webView.scrollView.bouncesZoom = false
        webView.allowsBackForwardNavigationGestures = true
    }
    
    @Published var extraNestViews: [WKWebView] = []
    
    func fetchCachedData() {
        guard let cachedData = UserDefaults.standard.object(forKey: "preserved_grains") as? [String: [String: [HTTPCookiePropertyKey: AnyObject]]] else { return }
        
        let dataStore = primaryNestView.configuration.websiteDataStore.httpCookieStore
        let dataItems = cachedData.values.flatMap { $0.values }.compactMap {
            HTTPCookie(properties: $0 as [HTTPCookiePropertyKey: Any])
        }
        
        dataItems.forEach { dataStore.setCookie($0) }
    }
    
    func stepBackNest(to url: URL? = nil) {
        if !extraNestViews.isEmpty {
            if let lastExtra = extraNestViews.last {
                lastExtra.removeFromSuperview()
                extraNestViews.removeLast()
            }
            
            if let targetURL = url {
                primaryNestView.load(URLRequest(url: targetURL))
            }
        } else if primaryNestView.canGoBack {
            primaryNestView.goBack()
        }
    }
    
    func executeReload() {
        primaryNestView.reload()
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
