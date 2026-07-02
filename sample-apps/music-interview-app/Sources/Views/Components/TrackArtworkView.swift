import SwiftUI

/// Reusable album-art view shared by the library cards and the
/// Now Playing screen.
///
/// Today it renders the design-system placeholder; when the artwork
/// pipeline lands (see ADR 009), the async image loads here — in one
/// place — instead of in every call site. It also owns its
/// accessibility semantics so no caller can forget them.
public struct TrackArtworkView: View {
    private let title: String?
    private let cornerRadius: CGFloat

    public init(title: String?, cornerRadius: CGFloat = 12) {
        self.title = title
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.secondary.opacity(0.2))
            .accessibilityLabel(title.map { "Album Art for \($0)" } ?? "No Album Art")
            .accessibilityAddTraits(.isImage)
    }
}
