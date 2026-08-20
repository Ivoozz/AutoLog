import SwiftUI

public struct LiquidGlassModifier: ViewModifier {
    public var cornerRadius: CGFloat
    public var borderOpacity: Double
    public var glowColor: Color
    public var glowRadius: CGFloat

    public init(
        cornerRadius: CGFloat = 22,
        borderOpacity: Double = 0.35,
        glowColor: Color = Color.blue.opacity(0.15),
        glowRadius: CGFloat = 12
    ) {
        self.cornerRadius = cornerRadius
        self.borderOpacity = borderOpacity
        self.glowColor = glowColor
        self.glowRadius = glowRadius
    }

    public func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .background(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.12),
                                Color.white.opacity(0.03)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(borderOpacity),
                                Color.white.opacity(borderOpacity * 0.25),
                                Color.clear,
                                Color.white.opacity(borderOpacity * 0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.2
                    )
            )
            .shadow(color: glowColor, radius: glowRadius, x: 0, y: 6)
            .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
    }
}

public struct LiquidBackground: View {
    @State private var animate = false

    public init() {}

    public var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()

            // Ambient floating refractive orbs
            GeometryReader { proxy in
                let w = proxy.size.width
                let h = proxy.size.height

                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.blue.opacity(0.35), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: w * 0.45
                            )
                        )
                        .frame(width: w * 0.9, height: w * 0.9)
                        .offset(x: animate ? -w * 0.2 : w * 0.15, y: animate ? -h * 0.1 : h * 0.05)
                        .blur(radius: 60)

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.cyan.opacity(0.3), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: w * 0.4
                            )
                        )
                        .frame(width: w * 0.8, height: w * 0.8)
                        .offset(x: animate ? w * 0.25 : -w * 0.1, y: animate ? h * 0.2 : h * 0.05)
                        .blur(radius: 50)

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.indigo.opacity(0.25), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: w * 0.5
                            )
                        )
                        .frame(width: w * 0.95, height: w * 0.95)
                        .offset(x: animate ? -w * 0.1 : w * 0.2, y: animate ? h * 0.45 : h * 0.35)
                        .blur(radius: 70)
                }
            }
            .ignoresSafeArea()
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 8.0).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

public extension View {
    func liquidGlass(
        cornerRadius: CGFloat = 22,
        borderOpacity: Double = 0.35,
        glowColor: Color = Color.blue.opacity(0.12),
        glowRadius: CGFloat = 12
    ) -> some View {
        self.modifier(LiquidGlassModifier(
            cornerRadius: cornerRadius,
            borderOpacity: borderOpacity,
            glowColor: glowColor,
            glowRadius: glowRadius
        ))
    }
}
