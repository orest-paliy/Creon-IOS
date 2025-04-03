import SwiftUI

struct MarqueeTextView: View {
    let tags: String
    let speed: CGFloat = 30
    let reverse: Bool

    @State private var textWidth: CGFloat = 0
    @State private var time: TimeInterval = 0

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { timeline in
                let now = timeline.date.timeIntervalSinceReferenceDate
                let delta = now - time
                let scroll = CGFloat(delta) * speed

                let totalScroll = textWidth + 50
                let baseOffset = scroll.truncatingRemainder(dividingBy: totalScroll)

                let offset = reverse
                    ? -(textWidth + 50) + baseOffset 
                    : -baseOffset

                HStack(spacing: 50) {
                    marqueeText
                    marqueeText
                }
                .offset(x: offset)
                .onAppear {
                    time = Date().timeIntervalSinceReferenceDate
                }
            }
        }
        .frame(height: 24)
        .clipped()
    }

    private var marqueeText: some View {
        Text(tags)
            .lineLimit(1)
            .fixedSize()
            .background(
                GeometryReader { proxy in
                    Color.clear.onAppear {
                        textWidth = proxy.size.width
                    }
                }
            )
    }
}
