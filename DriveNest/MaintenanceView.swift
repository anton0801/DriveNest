import SwiftUI

struct MaintenanceView: View {
    @EnvironmentObject var appData: AppData
    
    let car: Car
    @State private var showingAddTask = false
    
    private var tasks: [MaintenanceTask] {
            appData.cars.first(where: { $0.id == car.id })?.maintenanceTasks ?? []
        }
    
    var body: some View {
        ZStack {
            BackgroundView()
            
            if tasks.isEmpty {
                VStack {
                    Spacer()
                    Text("No maintenance tasks yet")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("Tap + to add oil change, brakes, etc.")
                        .foregroundColor(.secondary.opacity(0.7))
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 18) {
                        ForEach(tasks) { task in
                            MaintenanceTaskRow(task: task)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.top, 20)
                }
            }
            
            VStack {
                Spacer()
                Button("Add Task") {
                    showingAddTask = true
                }
                .buttonStyle(NeonButtonStyle())
                .padding(.horizontal, 40)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle("Maintenance")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddTask) {
            AddMaintenanceTaskView(car: car) { task in
                if let index = appData.cars.firstIndex(where: { $0.id == car.id }) {
                    appData.cars[index].maintenanceTasks.append(task)
                }
            }
        }
    }
}

struct MaintenanceTaskRow: View {
    let task: MaintenanceTask
    
    var body: some View {
        HStack {
            Image(systemName: taskIcon)
                .font(.system(size: 32))
                .foregroundColor(.goldNeon)
                .frame(width: 60)
                .shadow(color: .goldNeon.opacity(0.6), radius: 10)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(task.name)
                    .font(.title3.bold())
                    .foregroundColor(.white)
                
                HStack {
                    Text("Last: \(Int(task.lastMileage)) km")
                    Spacer()
                    Text("\(daysUntilNext) days")
                        .foregroundColor(daysUntilNext < 30 ? .yellow : .secondary)
                }
                .font(.caption)
            }
            
            Spacer()
            
            Circle()
                .fill(statusColor)
                .frame(width: 24, height: 24)
                .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 2))
                .shadow(color: statusColor.opacity(0.8), radius: 10)
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(LinearGradient(colors: [statusColor.opacity(0.4), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5)
        )
    }
    
    var taskIcon: String {
        switch task.name.lowercased() {
        case _ where task.name.contains("Oil"): return "drop.fill"
        case _ where task.name.contains("Brake"): return "exclamationmark.triangle.fill"
        case _ where task.name.contains("Filter"): return "gearshape.2.fill"
        default: return "wrench.fill"
        }
    }
    
    var statusColor: Color {
        switch task.status {
        case .green: return .green
        case .yellow: return .yellow
        case .red: return .red
        }
    }
    
    var daysUntilNext: Int {
        let components = Calendar.current.dateComponents([.day], from: Date(), to: task.nextDueDate)
        return max(0, components.day ?? 0)
    }
}

struct AddMaintenanceTaskView: View {
    @Environment(\.dismiss) var dismiss
    let car: Car
    let onSave: (MaintenanceTask) -> Void
    
    @State private var name = ""
    @State private var intervalKm = ""
    @State private var intervalDays = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.deepBlack.ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Text("New Maintenance Task")
                        .font(.largeTitle.bold())
                        .foregroundColor(.goldNeon)
                    
                    TextField("Task name (Oil, Brakes…)", text: $name)
                        .textFieldStyle(NeonTextFieldStyle())
                    
                    TextField("Interval (km)", text: $intervalKm)
                        .keyboardType(.numberPad)
                        .textFieldStyle(NeonTextFieldStyle())
                    
                    TextField("Interval (days)", text: $intervalDays)
                        .keyboardType(.numberPad)
                        .textFieldStyle(NeonTextFieldStyle())
                    
                    Button("Save") {
                        guard let km = Double(intervalKm),
                              let days = Int(intervalDays) else { return }
                        
                        let task = MaintenanceTask(
                            name: name.isEmpty ? "New Task" : name,
                            lastDate: Date(),
                            lastMileage: car.mileage,
                            intervalKm: km,
                            intervalDays: days
                        )
                        onSave(task)
                        dismiss()
                    }
                    .buttonStyle(NeonButtonStyle())
                    .padding(.horizontal, 40)
                }
                .padding()
            }
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.foregroundColor(.goldNeon) } }
        }
    }
}
