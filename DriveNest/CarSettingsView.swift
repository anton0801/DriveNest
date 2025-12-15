import SwiftUI

struct CarSettingsView: View {
    let car: Car
    
    var body: some View {
        ZStack {
            BackgroundView()
                .overlay(
                    Image(systemName: "feather.fill")
                        .font(.system(size: 120))
                        .foregroundColor(.goldNeon.opacity(0.1))
                        .offset(x: 140, y: 280)
                )
            
            Form {
                Section("Car Info") {
                    TextField("Name", text: .constant(car.name))
                        .disabled(true)
                    TextField("Model", text: .constant(car.model))
                        .disabled(true)
                    HStack {
                        Text("Mileage")
                        Spacer()
                        Text("\(Int(car.mileage)) km")
                            .foregroundColor(.goldNeon)
                    }
                }
                
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Settings")
    }
}
