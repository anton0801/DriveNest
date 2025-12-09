import SwiftUI

struct FuelingsView: View {
    @State private var fuelings = sampleFuelings
    
    var body: some View {
        ZStack {
            backgroundView
            
            VStack {
                // Mini graph placeholder
                Text("Fuel Consumption Graph")
                    .foregroundColor(.purpleNeon)
                    .padding()
                
                List {
                    ForEach(fuelings) { fueling in
                        FuelingCardView(fueling: fueling)
                    }
                }
                .listStyle(PlainListStyle())
            }
            
            VStack {
                Spacer()
                Button("Add Refuel") {
                    // Add logic
                }
                .padding()
                .background(Color.goldenNeon)
                .cornerRadius(10)
                .foregroundColor(.darkAsphalt)
            }
            .padding(.bottom, 20)
        }
        .navigationTitle("Refuels")
    }
    
    var backgroundView: some View {
        LinearGradient(gradient: Gradient(colors: [.darkAsphalt, .turquoiseLight.opacity(0.3)]), startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
    }
}

struct FuelingCardView: View {
    let fueling: Fueling
    
    var body: some View {
        HStack {
            ZStack {
                Text("\(fueling.liters, specifier: "%.1f") L")
                Image(systemName: "pawprint")
                    .resizable()
                    .frame(width: 15, height: 15)
                    .foregroundColor(.goldenNeon.opacity(0.5))
                    .offset(x: 30, y: 20)
            }
            VStack(alignment: .leading) {
                Text("Price: $\(fueling.price, specifier: "%.2f")/L")
                Text("Total: $\(fueling.total, specifier: "%.2f")")
                Text("Mileage: \(fueling.mileage, specifier: "%.0f") km")
                Text(fueling.date, style: .date)
            }
            .font(.subheadline)
            .foregroundColor(.metallicOutline)
        }
        .padding()
        .background(Color.darkAsphalt.opacity(0.8))
        .cornerRadius(15)
        .shadow(color: .lightShadow, radius: 5)
    }
}

#Preview {
    FuelingsView()
}
