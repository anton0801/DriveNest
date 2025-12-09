import SwiftUI

struct CarDashboardView: View {
    let car: Car
    // @State private var mileage = sampleCars[0].mileage // Sample
    
    var body: some View {
        ZStack {
            backgroundView
            
            ScrollView {
                VStack(spacing: 20) {
                    carCard
                    
                    quickStats
                    
                }
                .padding()
            }
        }
        .navigationTitle(car.name)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    var backgroundView: some View {
        LinearGradient(gradient: Gradient(colors: [.darkAsphalt, .purpleNeon.opacity(0.3)]), startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
    }
    
    var carCard: some View {
        ZStack {
            Image(systemName: "car.fill")
                .resizable()
                .scaledToFit()
                .frame(height: 150)
                .foregroundColor(.metallicOutline)
                .shadow(color: .whiteGlow, radius: 10)
            Image(systemName: "bird") // Feather approximation
                .resizable()
                .frame(width: 30, height: 30)
                .foregroundColor(.goldenNeon.opacity(0.7))
                .offset(x: 0, y: -50)
        }
        .overlay(
            VStack {
//                Text("Mileage: \(mileage, specifier: "%.0f") km")
//                    .foregroundColor(.whiteGlow)
                Button("Update Mileage") {
                    // Logic to update
                }
                .padding(8)
                .background(Color.turquoiseLight)
                .cornerRadius(8)
                .foregroundColor(.darkAsphalt)
            }
            .padding(.top, 160)
        )
        .background(Color.darkAsphalt.opacity(0.8))
        .cornerRadius(20)
        .shadow(color: .lightShadow, radius: 10)
    }
    
    var quickStats: some View {
        VStack(alignment: .leading) {
            Text("Average Fuel Consumption: 8.5 L/100km")
            Text("Monthly Expenses: $300")
            Text("Last Refuel: Today")
            Text("Last Maintenance: 1 month ago")
        }
        .font(.subheadline)
        .foregroundColor(.metallicOutline)
        .padding()
        .background(Color.darkAsphalt.opacity(0.8))
        .cornerRadius(15)
        .shadow(color: .lightShadow, radius: 5)
    }
    

}

struct SectionTile: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 40)
            Text(title)
                .foregroundColor(.whiteGlow)
            Spacer()
        }
        .padding()
        .background(Color.darkAsphalt.opacity(0.8))
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(color.opacity(0.5), lineWidth: 2)
                .shadow(color: color, radius: 5)
        )
    }
}
