import SwiftUI


struct SplashScreen: View {
    @Binding var isDone: Bool

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            // Company logo — centered, 2/3 screen width (matches launch screen constraint)
            GeometryReader { geo in
                Image("company")
                    .resizable()
                    .scaledToFit()
                    .frame(width: geo.size.width * 2/3)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }
            .ignoresSafeArea()

            // Attribution footer — matches launch screen layout
            VStack {
                Spacer()
                HStack(spacing: 0) {
                    Image("icon_tour_api")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 183, height: 44)
                }
                .padding(.trailing, 24)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.bottom, 40)
            }
        }
        .task {
            KakaoManager.initialize();
            try? await Task.sleep(for: .seconds(1));
            withAnimation {
                isDone = true;
            }
        }
    }
}
