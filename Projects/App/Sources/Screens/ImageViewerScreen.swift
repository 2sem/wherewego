import SwiftUI
import SDWebImage

struct ImageViewerScreen: View {
    let imageUrl: URL?

    @State private var loadedImage: UIImage? = nil;
    @State private var showShareSheet = false;

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            SDWebImageSwiftUIView(url: imageUrl, placeholder: WWGImages.noImage)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .aspectRatio(contentMode: .fit)
        }
        .navigationBarTitle("", displayMode: .inline)
        .navigationBarBackButtonHidden(false)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showShareSheet = true; } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(.white)
                }
            }
        }
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarForegroundStyle(.white, for: .navigationBar)
        .sheet(isPresented: $showShareSheet) {
            if let img = loadedImage {
                ShareSheetView(items: [img])
            }
        }
        .onAppear {
            guard let url = imageUrl else { return };
            SDWebImageManager.default.loadImage(with: url, options: .scaleDownLargeImages, progress: nil) { image, _, _, _, _, _ in
                loadedImage = image;
            };
        }
    }
}
