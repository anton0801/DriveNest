import SwiftUI

struct RefuelsView: View {
    @EnvironmentObject var appData: AppData
    let car: Car
    @State private var showingAddRefuel = false
    
    private var fuelings: [Fueling] {
        (appData.cars.first(where: { $0.id == car.id })?.fuelings ?? [])
            .sorted { $0.date > $1.date }
    }
    
    var body: some View {
        ZStack {
            BackgroundView()
            
            VStack {
                // Мини-график расхода
                FuelChartView()
                    .frame(height: 200)
                    .padding()
                
                if fuelings.isEmpty {
                    VStack {
                        Text("No refuels yet")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("Add your first tank")
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(fuelings) { fueling in
                                RefuelRow(fueling: fueling)
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
            }
            
            VStack {
                Spacer()
                Button("Add Refuel") {
                    showingAddRefuel = true
                }
                    .buttonStyle(NeonButtonStyle())
                    .padding(.horizontal, 40)
                    .padding(.bottom, 30)
            }
        }
        .navigationTitle("Refuels")
        .fullScreenCover(isPresented: $showingAddRefuel) {
            AddRefuelView(car: car) { fueling in
                if let index = appData.cars.firstIndex(where: { $0.id == car.id }) {
                    appData.cars[index].fuelings.append(fueling)
                }
            }
        }
    }
}

struct RefuelRow: View {
    let fueling: Fueling
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.turquoise, .turquoise.opacity(0.6)], startPoint: .top, endPoint: .bottom))
                    .frame(width: 60, height: 60)
                    .shadow(color: .turquoise.opacity(0.7), radius: 12)
                
                Text("\(Int(fueling.liters))L")
                    .font(.title2.bold())
                    .foregroundColor(.deepBlack)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("$\(fueling.total, specifier: "%.2f")")
                    .font(.title3.bold())
                    .foregroundColor(.goldNeon)
                
                Text("\(fueling.date, format: .dateTime.month(.abbreviated).day()) • \(Int(fueling.mileage)) km")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "pawprint.fill")
                .foregroundColor(.goldNeon.opacity(0.4))
                .font(.system(size: 20))
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.turquoise.opacity(0.3), lineWidth: 1)
        )
    }
}

struct FuelChartView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(.ultraThinMaterial)
            .overlay(
                VStack {
                    Text("Avg. 7.4 L/100km")
                        .font(.title2.bold())
                        .foregroundColor(.turquoise)
                    Rectangle().fill(Color.turquoise.opacity(0.2)).frame(height: 80)
                }
                .padding()
            )
    }
}


struct AddRefuelView: View {
    @Environment(\.dismiss) var dismiss
    let car: Car
    let onSave: (Fueling) -> Void
    
    @State private var liters = ""
    @State private var pricePerLiter = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.deepBlack.ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Text("New Refuel")
                        .font(.largeTitle.bold())
                        .foregroundColor(.goldNeon)
                    
                    TextField("Liters", text: $liters)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(NeonTextFieldStyle())
                    
                    TextField("Price per liter", text: $pricePerLiter)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(NeonTextFieldStyle())
                    
                    Button("Save") {
                        guard let l = Double(liters),
                              let p = Double(pricePerLiter) else { return }
                        
                        let fueling = Fueling(
                            liters: l,
                            price: p,
                            total: l * p,
                            mileage: car.mileage
                        )
                        onSave(fueling)
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
