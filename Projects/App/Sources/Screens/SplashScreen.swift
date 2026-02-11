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
                    Image("Icons8")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                    Text("Icons8")
                        .font(.system(size: 17))
                        .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
                        .frame(width: 59, height: 21)
                        .padding(.leading, 8)
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
