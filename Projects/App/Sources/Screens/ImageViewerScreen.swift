import SwiftUI

struct ImageViewerScreen: View {
    let imageUrl: URL?

    @Environment(\.dismiss) private var dismiss;
    @State private var shareImage: UIImage? = nil;
    @State private var showShareSheet = false;

    // MARK: - Zoom / pan state

    private let minScale: CGFloat = 1.0;
    private let maxScale: CGFloat = 5.0;
    private let doubleTapScale: CGFloat = 2.5;

    @State private var scale: CGFloat = 1.0;
    @State private var lastCommittedScale: CGFloat = 1.0;
    @State private var offset: CGSize = .zero;
    @State private var lastCommittedOffset: CGSize = .zero;
    @State private var containerSize: CGSize = .zero;

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea();

            if let url = imageUrl {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        zoomableImage(image);
                    case .empty:
                        ProgressView()
                            .tint(.white);
                    case .failure(_):
                        if let placeholder = WWGImages.noImage {
                            Image(uiImage: placeholder)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: .infinity, maxHeight: .infinity);
                        }
                    @unknown default:
                        EmptyView();
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
                        .foregroundStyle(.white);
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { onShare(); } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(.white);
                }
            }
        }
        .toolbarBackground(Color.black, for: .navigationBar)
        .sheet(isPresented: $showShareSheet) {
            if let img = shareImage {
                ShareSheetView(items: [img]);
            }
        }
    }

    // MARK: - Zoomable image view

    @ViewBuilder
    private func zoomableImage(_ image: Image) -> some View {
        GeometryReader { geo in
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .scaleEffect(scale)
                .offset(offset)
                .gesture(dragGesture(in: geo.size))
                .gesture(magnificationGesture(in: geo.size))
                .onTapGesture(count: 2) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        if scale > 1.0 {
                            resetZoom();
                        } else {
                            scale = doubleTapScale;
                            lastCommittedScale = doubleTapScale;
                        }
                    }
                }
                .onAppear { containerSize = geo.size; }
        }
    }

    // MARK: - Gestures

    private func magnificationGesture(in size: CGSize) -> some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let proposed = lastCommittedScale * value;
                scale = min(max(proposed, minScale), maxScale);
            }
            .onEnded { value in
                let proposed = lastCommittedScale * value;
                let clamped = min(max(proposed, minScale), maxScale);
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    scale = clamped;
                    if clamped <= 1.0 {
                        resetZoom();
                    } else {
                        lastCommittedScale = clamped;
                        offset = clampedOffset(offset, scale: clamped, in: size);
                        lastCommittedOffset = offset;
                    }
                }
            }
    }

    private func dragGesture(in size: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                guard scale > 1.0 else { return };
                let proposed = CGSize(
                    width: lastCommittedOffset.width + value.translation.width,
                    height: lastCommittedOffset.height + value.translation.height
                );
                offset = clampedOffset(proposed, scale: scale, in: size);
            }
            .onEnded { _ in
                guard scale > 1.0 else {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        offset = .zero;
                        lastCommittedOffset = .zero;
                    }
                    return;
                }
                lastCommittedOffset = offset;
            }
    }

    // MARK: - Helpers

    private func clampedOffset(_ proposedOffset: CGSize, scale: CGFloat, in size: CGSize) -> CGSize {
        let maxX = ((scale - 1.0) / 2.0) * size.width;
        let maxY = ((scale - 1.0) / 2.0) * size.height;

        return CGSize(
            width: min(max(proposedOffset.width, -maxX), maxX),
            height: min(max(proposedOffset.height, -maxY), maxY)
        );
    }

    private func resetZoom() {
        scale = 1.0;
        lastCommittedScale = 1.0;
        offset = .zero;
        lastCommittedOffset = .zero;
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
