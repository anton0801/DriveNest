import SwiftUI

#Preview {
    DrivePermView {
        
    } onDecline: {
        
    }

}

struct DriveCarSplashView: View {
    @StateObject private var viewModel = DriveNestViewModel()
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if viewModel.currentDrivePhase == .ignition || viewModel.showPermissionScreen {
                DriveIgnitionScreen()
            }
            ActiveDriveContent(viewModel: viewModel)
                .opacity(viewModel.showPermissionScreen ? 0 : 1)
            if viewModel.showPermissionScreen {
                DrivePermView(
                    onGrant: viewModel.userAllowedPermission,
                    onDecline: viewModel.userSkippedPermission
                )
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct ActiveDriveContent: View {
    @ObservedObject var viewModel: DriveNestViewModel
    var body: some View {
        Group {
            switch viewModel.currentDrivePhase {
            case .ignition:
                EmptyView()
            case .organic:
                EmptyView()
            case .driving:
                if let _ = viewModel.nestURL {
                    DriveNestMainView()
                } else {
                    OnboardingView()
                }
            case .parked:
                OnboardingView()
            case .noSignal:
                DriveNoConnectionScreen()
            }
        }
        .transition(.opacity)
    }
}


struct DriveIgnitionScreen: View {
    var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            ZStack {
                Image(isLandscape ? "land_loading_bg" : "loading_background")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    Image("loading_icon")
                        .resizable()
                        .frame(width: 200, height: 50)
                    Spacer()
                    TreadProgressBar()
                        .frame(width: 350)
                        .padding(.bottom, 32)
                }
            }
        }
        .ignoresSafeArea()
    }
}

struct DriveNoConnectionScreen: View {
    var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            ZStack {
                Image(isLandscape ? "land_no_internet_back" : "no_internet_back")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .ignoresSafeArea()
                
                if isLandscape {
                    Image("no_internet_alert")
                        .resizable()
                        .frame(width: 270, height: 210)
                } else {
                    Image("no_internet_alert")
                        .resizable()
                        .frame(width: 270, height: 210)
                        .padding(.bottom, 102)
                }
            }
        }
        .ignoresSafeArea()
    }
}

struct DrivePermView: View {
    let onGrant: () -> Void
    let onDecline: () -> Void
    
    var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            
            ZStack {
                Image(isLandscape ? "land_push_bg" : "push_back")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .ignoresSafeArea()
                
                if isLandscape {
                    VStack {
                        Spacer()
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Allow notifications about bonuses and promos".uppercased())
                                    .font(.custom("Inter-Regular_Black", size: 24))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                                
                                Text("Stay tuned with best offers from our casino")
                                    .font(.custom("Inter-Regular_Bold", size: 18))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer()
                            VStack {
                                Button(action: onGrant) {
                                    Image("push_accept")
                                        .resizable()
                                        .frame(height: 60)
                                }
                                .frame(width: 350)
                                
                                Button(action: onDecline) {
                                    Image("push_skip")
                                        .resizable()
                                        .frame(height: 40)
                                }
                                .frame(width: 320)
                            }
                        }
                        .padding(.bottom, 24)
                        .padding(.horizontal, 62)
                    }
                } else {
                    VStack(spacing: isLandscape ? 5 : 10) {
                        Spacer()
                        
                        Text("Allow notifications about bonuses and promos".uppercased())
                            .font(.custom("Inter-Regular_Black", size: 20))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("Stay tuned with best offers from our casino")
                            .font(.custom("Inter-Regular_Bold", size: 15))
                            .foregroundColor(.white)
                            .padding(.horizontal, 52)
                            .multilineTextAlignment(.center)
                        
                        Button(action: onGrant) {
                            Image("push_accept")
                                .resizable()
                                .frame(height: 60)
                        }
                        .frame(width: 350)
                        .padding(.top, 12)
                        
                        Button(action: onDecline) {
                            Image("push_skip")
                                .resizable()
                                .frame(height: 40)
                        }
                        .frame(width: 320)
                        
                        Spacer()
                            .frame(height: isLandscape ? 30 : 50)
                    }
                    .padding(.horizontal, isLandscape ? 20 : 0)
                }
            }
        }
        .ignoresSafeArea()
    }
}

struct TreadProgressBar: View {
    @State private var progressValue: CGFloat = 0.0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(LinearGradient(gradient: Gradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.1)]), startPoint: .leading, endPoint: .trailing))
                    .frame(width: geometry.size.width, height: 8)
                    .shadow(color: Color.black.opacity(0.4), radius: 4, x: 0, y: 2)
                
                Capsule()
                    .fill(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .leading, endPoint: .trailing))
                    .frame(width: geometry.size.width * 0.35, height: 8)
                    .offset(x: progressValue * geometry.size.width - geometry.size.width * 0.35)
                    .blur(radius: 2)
                    .shadow(color: Color.blue.opacity(0.6), radius: 5, x: 0, y: 0)
                    .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: false), value: progressValue)
            }
        }
        .frame(height: 8)
        .clipShape(Capsule())
        .onAppear {
            progressValue = 1.0 + 0.35
        }
    }
}
