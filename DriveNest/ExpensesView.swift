import SwiftUI

struct ExpensesView: View {
    @EnvironmentObject var appData: AppData
    let car: Car
    @State private var showingAddExpense = false
    
    private var expenses: [Expense] {
            (appData.cars.first(where: { $0.id == car.id })?.expenses ?? [])
                .sorted { $0.date > $1.date }
        }
    
    var totalThisMonth: Double {
            let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
            return expenses.filter { $0.date >= monthAgo }.reduce(0) { $0 + $1.amount }
        }
    
    var body: some View {
        ZStack {
            BackgroundView()
            
            VStack(spacing: 30) {
//                ExpensePieChartPlaceholder()
//                    .frame(height: 260)
                ExpensePieChart(expenses: expenses)
                    .frame(height: 280)
                
                if expenses.isEmpty {
                    Text("No expenses yet")
                        .font(.title2)
                        .foregroundColor(.secondary)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            ForEach(expenses) { expense in
                                ExpenseRow(expense: expense)
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
//                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
//                    ExpenseCategoryTile(category: "Fuel", amount: 1000, color: .orangeGloss)
//                    ExpenseCategoryTile(category: "Repair", amount: 850, color: .red)
//                    ExpenseCategoryTile(category: "Wash", amount: 120, color: .turquoise)
//                    ExpenseCategoryTile(category: "Parking", amount: 280, color: .purpleNeon)
//                }
//                .padding(.horizontal)
                
                Spacer()
                
                Button("Add Expense") {
                    showingAddExpense = true
                }
                    .buttonStyle(NeonButtonStyle())
                    .padding(.horizontal, 40)
            }
            .sheet(isPresented: $showingAddExpense) {
                AddExpenseView(car: car) { expense in
                    if let index = appData.cars.firstIndex(where: { $0.id == car.id }) {
                        appData.cars[index].expenses.append(expense)
                    }
                }
            }
            .padding(.top, 20)
        }
        .navigationTitle("Expenses")
    }
}

struct ExpenseRow: View {
    let expense: Expense
    
    var color: Color {
        switch expense.category {
        case "Fuel": return .orangeGloss
        case "Repair": return .red
        case "Wash": return .turquoise
        case "Parking": return .purpleNeon
        default: return .goldNeon
        }
    }
    
    var body: some View {
        HStack {
            Circle().fill(color).frame(width: 12)
            
            Text(expense.category)
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
            
            Text("$\(expense.amount, specifier: "%.2f")")
                .font(.title3.bold())
                .foregroundColor(color)
            
            Text(expense.date, format: .dateTime.day().month(.abbreviated))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(color.opacity(0.3), lineWidth: 1))
    }
}

struct ExpenseCategoryTile: View {
    let category: String
    let amount: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Text("$\(Int(amount))")
                .font(.title.bold())
                .foregroundColor(color)
                .shadow(color: color.opacity(0.8), radius: 10)
            
            Text(category)
                .font(.headline)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, minHeight: 100)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(color.opacity(0.4), lineWidth: 1.5))
    }
}

struct ExpensePieChartPlaceholder: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .shadow(color: .goldNeon.opacity(0.4), radius: 20, y: 10)
            
            VStack {
                Text("$2,850")
                    .font(.largeTitle.bold())
                    .foregroundColor(.goldNeon)
                Text("This month")
                    .foregroundColor(.secondary)
            }
        }
        .frame(height: 260)
        .overlay(
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(LinearGradient(colors: [.goldNeon, .orangeGloss], startPoint: .top, endPoint: .bottom), lineWidth: 16)
                .rotationEffect(.degrees(-90))
                .padding(30)
        )
    }
}

struct AddExpenseView: View {
    @Environment(\.dismiss) var dismiss
    let car: Car
    let onSave: (Expense) -> Void
    
    @State private var amount = ""
    @State var selectedCategory: String = "Fuel"
    let categories = ["Fuel", "Repair", "Wash", "Parking", "Fine", "Other"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.deepBlack.ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Text("New Expense")
                        .font(.largeTitle.bold())
                        .foregroundColor(.goldNeon)
                    
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(NeonTextFieldStyle())
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { Text($0) }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.goldNeon.opacity(0.4), lineWidth: 1))
                    
                    Button("Save") {
                        guard let a = Double(amount) else { return }
                        let expense = Expense(category: selectedCategory, amount: a)
                        onSave(expense)
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



struct ExpensePieChart: View {
    let expenses: [Expense]
    
    private var totalByCategory: [String: Double] {
        Dictionary(grouping: expenses, by: { $0.category })
            .mapValues { $0.reduce(0) { $0 + $1.amount } }
    }
    
    private var totalAmount: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        ZStack {
            // Фоновая круглая карточка
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 260, height: 260)
                .shadow(color: .goldNeon.opacity(0.4), radius: 20, y: 10)
            
            // Сама круговая диаграмма
            if totalAmount > 0 {
                PieChartView(data: totalByCategory)
                    .frame(width: 200, height: 200)
            }
            
            // Сумма в центре
            VStack(spacing: 4) {
                Text("$\(Int(totalAmount))")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.goldNeon)
                    .shadow(color: .goldNeon.opacity(0.8), radius: 12)
                
                Text("Total")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Вспомогательная PieChartView (полностью рабочая)
struct PieChartView: View {
    let data: [String: Double]
    
    private var segments: [PieSegment] {
        var startAngle: Angle = .degrees(0)
        let total = data.values.reduce(0, +)
        
        return data.map { category, value in
            let percentage = value / total
            let angle = Angle(degrees: 360 * percentage)
            let segment = PieSegment(
                startAngle: startAngle,
                endAngle: startAngle + angle,
                color: colorForCategory(category)
            )
            startAngle += angle
            return segment
        }
    }
    
    var body: some View {
        ZStack {
            ForEach(segments) { segment in
                PieSegmentShape(startAngle: segment.startAngle, endAngle: segment.endAngle)
                    .fill(segment.color)
                    .shadow(color: segment.color.opacity(0.8), radius: 12)
            }
            
            // Центральная дыра (необязательно, но красиво)
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 100, height: 100)
        }
    }
    
    private func colorForCategory(_ category: String) -> Color {
        switch category {
        case "Fuel": return .orangeGloss
        case "Repair": return .red
        case "Wash": return .turquoise
        case "Parking": return .purpleNeon
        case "Fine": return .red
        default: return .goldNeon
        }
    }
}

// MARK: - Структуры для диаграммы
struct PieSegment: Identifiable {
    let id = UUID()
    let startAngle: Angle
    let endAngle: Angle
    let color: Color
}

struct PieSegmentShape: Shape {
    var startAngle: Angle
    var endAngle: Angle
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        path.move(to: center)
        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.closeSubpath()
        
        return path
    }
}
