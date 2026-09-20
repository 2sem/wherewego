import SwiftUI
import SDWebImage

/// UIViewRepresentable wrapper so SDWebImage's disk + memory caching is used in SwiftUI Lists.
struct SDWebImageSwiftUIView: UIViewRepresentable {
    let url: URL?
    let placeholder: UIImage?

    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView();
        imageView.contentMode = .scaleAspectFill;
        imageView.clipsToBounds = true;
        imageView.setContentHuggingPriority(.defaultLow, for: .horizontal);
        imageView.setContentHuggingPriority(.defaultLow, for: .vertical);
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal);
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical);
        return imageView;
    }

    func updateUIView(_ imageView: UIImageView, context: Context) {
        imageView.sd_setImage(with: url, placeholderImage: placeholder, options: .scaleDownLargeImages);
    }
}
