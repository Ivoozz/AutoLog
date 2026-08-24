import SwiftUI

public struct LiquidGlassModifier: ViewModifier {
    public var cornerRadius: CGFloat
    public var borderOpacity: Double
    public var glowColor: Color
    public var glowRadius: CGFloat

    public init(
        cornerRadius: CGFloat = 22,
        borderOpacity: Double = 0.45,
        glowColor: Color = Color.blue.opacity(0.18),
        glowRadius: CGFloat = 16
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
                                Color.white.opacity(0.14),
                                Color.white.opacity(0.04),
                                Color.clear
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
                            stops: [
                                .init(color: Color.white.opacity(borderOpacity), location: 0.0),
                                .init(color: Color.white.opacity(borderOpacity * 0.4), location: 0.35),
                                .init(color: Color.clear, location: 0.6),
                                .init(color: Color.white.opacity(borderOpacity * 0.25), location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.2
                    )
            )
            .shadow(color: glowColor, radius: glowRadius, x: 0, y: 8)
            .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}

public struct LiquidBackground: View {
    @State private var animate = false

    public init() {}

    public var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()

            // Fluid ambient mesh refraction orbs
            GeometryReader { proxy in
                let w = proxy.size.width
                let h = proxy.size.height

                ZStack {
                    // Orb 1: Apple Electric Blue
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color(red: 0.0, green: 0.48, blue: 1.0, opacity: 0.38), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: w * 0.48
                            )
                        )
                        .frame(width: w * 0.95, height: w * 0.95)
                        .offset(x: animate ? -w * 0.22 : w * 0.18, y: animate ? -h * 0.12 : h * 0.06)
                        .blur(radius: 65)

                    // Orb 2: Apple Vivid Cyan
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color(red: 0.2, green: 0.8, blue: 0.95, opacity: 0.32), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: w * 0.42
                            )
                        )
                        .frame(width: w * 0.85, height: w * 0.85)
                        .offset(x: animate ? w * 0.28 : -w * 0.12, y: animate ? h * 0.22 : h * 0.04)
                        .blur(radius: 55)

                    // Orb 3: Apple Deep Indigo / Violet
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color(red: 0.35, green: 0.34, blue: 0.84, opacity: 0.28), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: w * 0.52
                            )
                        )
                        .frame(width: w * 1.0, height: w * 1.0)
                        .offset(x: animate ? -w * 0.15 : w * 0.22, y: animate ? h * 0.48 : h * 0.32)
                        .blur(radius: 75)
                }
            }
            .ignoresSafeArea()
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 9.0).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

public extension Font {
    static func sfRounded(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static func sfMono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

public extension View {
    func liquidGlass(
        cornerRadius: CGFloat = 22,
        borderOpacity: Double = 0.45,
        glowColor: Color = Color.blue.opacity(0.18),
        glowRadius: CGFloat = 16
    ) -> some View {
        self.modifier(LiquidGlassModifier(
            cornerRadius: cornerRadius,
            borderOpacity: borderOpacity,
            glowColor: glowColor,
            glowRadius: glowRadius
        ))
    }
}
