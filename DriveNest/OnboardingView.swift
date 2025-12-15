import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding = false
    
    var body: some View {
        if hasSeenOnboarding {
            ContentView()
        } else {
            VStack {
                TabView(selection: $currentPage) {
                    OnboardingPage(
                        title: "Welcome to Drive Nest",
                        description: "Your car’s luxury home. Beautiful. Powerful. Private.",
                        image: "car.fill",
                        page: 0,
                        current: $currentPage
                    ).tag(0)
                    
                    OnboardingPage(
                        title: "Glossy Garage",
                        description: "3D cards, golden feathers, neon glows — every detail crafted for perfection.",
                        image: "sparkles",
                        page: 1,
                        current: $currentPage
                    ).tag(1)
                    
                    OnboardingPage(
                        title: "Everything in One Place",
                        description: "Mileage, refuels, expenses, maintenance, documents — all with stunning visuals.",
                        image: "gauge",
                        page: 2,
                        current: $currentPage
                    ).tag(2)
                    
                    OnboardingPage(
                        title: "Ready to Start?",
                        description: "Tap Get Started and add your first beast.",
                        image: "bolt.car",
                        page: 3,
                        current: $currentPage,
                        isLast: true,
                        onFinish: { hasSeenOnboarding = true }
                    ).tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .background(Color.deepBlack.ignoresSafeArea())
                
                HStack(spacing: 12) {
                    ForEach(0..<4, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.goldNeon : Color.goldNeon.opacity(0.2))
                            .frame(width: index == currentPage ? 12 : 8, height: index == currentPage ? 12 : 8)
                            .scaleEffect(index == currentPage ? 1.2 : 1.0)
                            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: currentPage)
                            .overlay(
                                Circle()
                                    .stroke(Color.goldNeon.opacity(index == currentPage ? 0.8 : 0), lineWidth: 2)
                                    .scaleEffect(index == currentPage ? 1.4 : 1.0)
                                    .opacity(index == currentPage ? 1 : 0)
                                    .animation(.easeOut(duration: 0.3), value: currentPage)
                            )
                            .shadow(color: .goldNeon.opacity(index == currentPage ? 0.8 : 0), radius: 10, y: 5)
                    }
                }
            }
        }
    }
}

struct OnboardingPage: View {
    let title: String
    let description: String
    let image: String
    let page: Int
    @Binding var current: Int
    var isLast = false
    var onFinish: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 40) {
            Image(systemName: image)
                .font(.system(size: 100))
                .foregroundColor(.goldNeon)
                .shadow(color: .goldNeon.opacity(0.8), radius: 30)
            
            Text(title)
                .font(.largeTitle.bold())
                .foregroundColor(.goldNeon)
                .multilineTextAlignment(.center)
            
            Text(description)
                .font(.title3)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
            
            if isLast {
                Button("Get Started") {
                    withAnimation { onFinish?() }
                }
                .buttonStyle(NeonButtonStyle())
                .padding(.horizontal, 60)
            }
        }
        .padding()
    }
}

#Preview {
    OnboardingView()
}
