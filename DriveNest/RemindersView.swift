import SwiftUI

struct RemindersView: View {
    
    @EnvironmentObject var appData: AppData
    let car: Car
    
    private var reminders: Binding<[Reminder]> {
        Binding(
            get: { appData.cars.first(where: { $0.id == car.id })?.reminders ?? [] },
            set: { new in
                if let i = appData.cars.firstIndex(where: { $0.id == car.id }) {
                    appData.cars[i].reminders = new
                }
            }
        )
    }
    
    @State private var showingAdd = false
    
    var body: some View {
        ZStack {
            BackgroundView()
            
            if reminders.wrappedValue.isEmpty {
                // пусто
            } else {
                List {
                    ForEach(reminders.wrappedValue) { reminder in
                        ReminderRow(reminder: reminder)
                    }
                    .onDelete { reminders.wrappedValue.remove(atOffsets: $0) }
                }
                .listStyle(PlainListStyle())
            }
            
            VStack {
                Spacer()
                Button("Add Reminder") { showingAdd = true }
                    .buttonStyle(NeonButtonStyle())
                    .padding(.horizontal, 40)
                    .padding(.bottom, 30)
            }
        }
        .navigationTitle("Reminders")
        .sheet(isPresented: $showingAdd) {
            AddReminderView { new in reminders.wrappedValue.append(new) }
        }
    }
}

struct ReminderRow: View {
    var reminder: Reminder
    
    var body: some View {
        HStack {
            Image(systemName: reminder.isEnabled ? "bell.fill" : "bell.slash")
                .font(.system(size: 28))
                .foregroundColor(reminder.isEnabled ? .goldNeon : .secondary)
                .shadow(color: reminder.isEnabled ? .goldNeon.opacity(0.8) : .clear, radius: 10)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title)
                    .font(.title3.bold())
                    .foregroundColor(.white)
                Text(reminder.interval)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
//            Toggle("", isOn: reminder.isEnabled)
//                .tint(.goldNeon)
//                .scaleEffect(1.3)
//                .onChange(of: reminder.isEnabled) { newValue in
//                    if newValue {
//                        withAnimation(.spring()) {
//                           
//                        }
//                    }
//                }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }
}


struct AddReminderView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var title: String = ""
    @State private var selectedDate: Date = Date().addingTimeInterval(7 * 86400) // по дефолту +7 дней
    @State private var isEnabled: Bool = true
    
    let onSave: (Reminder) -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.deepBlack.ignoresSafeArea()
                
                VStack(spacing: 40) {
                    Text("New Reminder")
                        .font(.largeTitle.bold())
                        .foregroundColor(.goldNeon)
                        .shadow(color: .goldNeon.opacity(0.7), radius: 12)
                    
                    VStack(spacing: 24) {
                        // Название напоминания
                        TextField("Reminder title (e.g. Change oil, Check tires)", text: $title)
                            .font(.title2)
                            .padding(20)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(Color.goldNeon.opacity(0.4), lineWidth: 1.5)
                            )
                            .foregroundColor(.white)
                        
                        // Дата
                        DatePicker("Due date", selection: $selectedDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(GraphicalDatePickerStyle())
                            .padding()
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(Color.goldNeon.opacity(0.3), lineWidth: 1)
                            )
                            .tint(.goldNeon)
                        
                        // Включено/выключено
                        Toggle("Enabled", isOn: $isEnabled)
                            .font(.title3.bold())
                            .foregroundColor(.white)
                            .toggleStyle(SwitchToggleStyle(tint: .goldNeon))
                            .padding(.horizontal)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Кнопка Save
                    Button("Save Reminder") {
                        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        
                        let newReminder = Reminder(
                            title: title.trimmingCharacters(in: .whitespaces),
                            date: selectedDate,
                            interval: "",
                            isEnabled: isEnabled
                        )
                        
                        onSave(newReminder)
                        dismiss()
                    }
                    .font(.title2.bold())
                    .foregroundColor(.deepBlack)
                    .frame(maxWidth: .infinity)
                    .frame(height: 64)
                    .background(
                        LinearGradient(colors: [.goldNeon, .goldDark], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .clipShape(Capsule())
                    .shadow(color: .goldNeon.opacity(0.9), radius: 20, y: 10)
                    .padding(.horizontal, 40)
                }
                .padding(.top, 20)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.goldNeon)
                }
            }
        }
    }
}
