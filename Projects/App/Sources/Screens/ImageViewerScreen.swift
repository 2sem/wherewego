import SwiftUI

struct ImageViewerScreen: View {
    let imageUrl: URL?

    @Environment(\.dismiss) private var dismiss;
    @State private var shareImage: UIImage? = nil;
    @State private var showShareSheet = false;

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let url = imageUrl {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    case .empty:
                        ProgressView()
                            .tint(.white)
                    case .failure(_):
                        if let placeholder = WWGImages.noImage {
                            Image(uiImage: placeholder)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    @unknown default:
                        EmptyView()
                    }
                }
            }
        }
        .navigationTitle("")
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.backward")
                        .foregroundStyle(.white)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { onShare(); } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(.white)
                }
            }
        }
        .toolbarBackground(Color.black, for: .navigationBar)
        .sheet(isPresented: $showShareSheet) {
            if let img = shareImage {
                ShareSheetView(items: [img])
            }
        }
    }

    // MARK: - Actions

    private func onShare() {
        guard let url = imageUrl else { return };
        Task {
            guard let (data, _) = try? await URLSession.shared.data(from: url),
                  let image = UIImage(data: data) else { return };
            shareImage = image;
            showShareSheet = true;
        }
    }
}
