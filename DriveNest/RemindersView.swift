import SwiftUI

struct RemindersView: View {
    @State private var reminders = sampleReminders
    
    var body: some View {
        ZStack {
            BackgroundView()
            
            List {
                ForEach($reminders) { $reminder in
                    ReminderRow(reminder: $reminder)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
            }
            .listStyle(PlainListStyle())
        }
        .navigationTitle("Reminders")
    }
}

struct ReminderRow: View {
    @Binding var reminder: Reminder
    
    var body: some View {
        HStack {
            Image(systemName: reminder.isOn ? "bell.fill" : "bell.slash")
                .font(.system(size: 28))
                .foregroundColor(reminder.isOn ? .goldNeon : .secondary)
                .shadow(color: reminder.isOn ? .goldNeon.opacity(0.8) : .clear, radius: 10)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.name)
                    .font(.title3.bold())
                    .foregroundColor(.white)
                Text(reminder.interval)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $reminder.isOn)
                .tint(.goldNeon)
                .scaleEffect(1.3)
                .onChange(of: reminder.isOn) { newValue in
                    if newValue {
                        withAnimation(.spring()) {
                            // перо вспыхивает
                        }
                    }
                }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }
}

#Preview {
    RemindersView()
}

