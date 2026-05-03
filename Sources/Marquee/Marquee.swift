import SwiftUI

extension View {
    public func marquee(
        speed: Double = 50,
        holdDuration: Double = 5,
        delay: Double = 5
    ) -> some View {
        modifier(
            MarqueeModifier(
                speed: speed,
                holdDuration: holdDuration,
                delay: delay
            )
        )
    }
}

private struct MarqueeModifier: ViewModifier {
    let speed: Double  // Pixels per second
    let holdDuration: Double  // Seconds
    let delay: Double  // Seconds

    @State private var size: CGSize? = nil
    @State private var sizeOuter: CGSize? = nil
    @State private var startDate: Date? = nil

    @Environment(\.layoutDirection) private var layoutDirection

    private var isPaused: Bool {
        guard let size, let sizeOuter else { return true }
        return size.width < sizeOuter.width
    }

    private var endOffset: CGFloat {
        guard let size, let sizeOuter else { return 0 }
        return max(size.width - sizeOuter.width, 0)
    }

    private func offsetX(elapsed: CGFloat) -> CGFloat {
        guard elapsed >= 0 else { return 0 }
        guard let size, let sizeOuter else { return 0 }

        let distance = max(size.width - sizeOuter.width, 0)
        guard distance > 0 else { return 0 }

        let moveDuration = distance / speed
        let cycleDuration = 2 * (moveDuration + holdDuration)

        let t = elapsed.truncatingRemainder(dividingBy: cycleDuration)

        let directionBase: CGFloat = (layoutDirection == .leftToRight) ? -1 : 1

        switch t {
        case 0..<moveDuration:
            // forward
            return directionBase * (t * speed)

        case moveDuration..<(moveDuration + holdDuration):
            // hold at end
            return directionBase * distance

        case (moveDuration + holdDuration)..<(2 * moveDuration + holdDuration):
            // backward
            let t2 = t - (moveDuration + holdDuration)
            return directionBase * (distance - t2 * speed)

        default:
            // hold at start
            return 0
        }
    }

    func body(content: Content) -> some View {
        TimelineView(.animation(paused: isPaused)) { ctx in
            let elapsed = abs(ctx.date.timeIntervalSince(startDate ?? .now))

            GeometryReader { geo in
                content
                    .fixedSize(horizontal: true, vertical: false)
                    .background {
                        GeometryReader { geo2 in
                            Color.clear.onAppear {
                                size = geo2.size
                            }
                        }
                    }
                    .offset(x: offsetX(elapsed: elapsed - delay))
            }
            .frame(height: size?.height)
            .fixedSize(horizontal: false, vertical: true)
            .clipShape(Rectangle())
            .background {
                GeometryReader { geo in
                    Color.clear.onChange(of: geo.size) {
                        sizeOuter = geo.size
                    }
                }
            }
            .onAppear {
                startDate = ctx.date
            }
        }
    }
}

#Preview {
    HStack {
        Text(
            "START Lorem Lorem Lorem Lorem Lorem Lorem Lorem Lorem Lorem END"
        )
        .marquee()
        Circle()
            .fill(.red)
            .frame(width: 50)
    }
}

#Preview {
    HStack {
        HStack {
            ForEach(0..<10) { i in
                ZStack {
                    Circle()
                        .fill(.cyan)
                        .frame(width: 50, height: 50)
                    Text("\(i)")
                }
            }
        }
        .marquee()
        Circle()
            .fill(.red)
            .frame(width: 50)
    }
}
