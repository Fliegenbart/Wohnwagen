import SwiftUI

struct RoadSheetScaffold<Content: View>: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    let systemImage: String
    let content: Content

    init(
        eyebrow: String,
        title: String,
        subtitle: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) {
        self.eyebrow = eyebrow
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.content = content()
    }

    var body: some View {
        AppCanvas {
            VStack(spacing: 12) {
                RoadSheetHeader(
                    eyebrow: eyebrow,
                    title: title,
                    subtitle: subtitle,
                    systemImage: systemImage
                )
                content
                    .roadFormSurface()
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
        }
    }
}

private struct RoadFormModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .scrollContentBackground(.hidden)
            .background(Color.clear)
    }
}

extension View {
    func roadFormSurface() -> some View {
        modifier(RoadFormModifier())
    }
}
