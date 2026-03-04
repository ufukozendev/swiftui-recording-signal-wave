import SwiftUI

public struct RecordingSignalWaveView: View {
    public struct RGBColor: Sendable, Equatable {
        public var red: Double
        public var green: Double
        public var blue: Double

        public init(red: Double, green: Double, blue: Double) {
            self.red = red
            self.green = green
            self.blue = blue
        }

        fileprivate var swiftUIColor: Color {
            Color(red: red, green: green, blue: blue)
        }
    }

    public struct Tone: Sendable, Equatable {
        public var top: RGBColor
        public var mid: RGBColor
        public var bottom: RGBColor

        public init(top: RGBColor, mid: RGBColor, bottom: RGBColor) {
            self.top = top
            self.mid = mid
            self.bottom = bottom
        }
    }

    public struct Style: Sendable, Equatable {
        public var barWidth: CGFloat
        public var barSpacing: CGFloat
        public var maxBarHeight: CGFloat
        public var activeFrameRate: Double
        public var reducedMotionFrameRate: Double
        public var tones: [Tone]

        public init(
            barWidth: CGFloat = 36,
            barSpacing: CGFloat = -8,
            maxBarHeight: CGFloat = 108,
            activeFrameRate: Double = 30,
            reducedMotionFrameRate: Double = 10,
            tones: [Tone] = Style.defaultTones
        ) {
            self.barWidth = barWidth
            self.barSpacing = barSpacing
            self.maxBarHeight = maxBarHeight
            self.activeFrameRate = activeFrameRate
            self.reducedMotionFrameRate = reducedMotionFrameRate
            self.tones = tones
        }

        public static let `default` = Style()

        public static let hero = Style(
            barWidth: 42,
            barSpacing: -10,
            maxBarHeight: 136,
            activeFrameRate: 36,
            reducedMotionFrameRate: 12,
            tones: defaultTones
        )

        public static let compact = Style(
            barWidth: 28,
            barSpacing: -6,
            maxBarHeight: 84,
            activeFrameRate: 24,
            reducedMotionFrameRate: 10,
            tones: defaultTones
        )

        public static let defaultTones: [Tone] = [
            Tone(
                top: RGBColor(red: 1.0, green: 0.68, blue: 0.56),
                mid: RGBColor(red: 1.0, green: 0.52, blue: 0.36),
                bottom: RGBColor(red: 0.82, green: 0.32, blue: 0.24)
            ),
            Tone(
                top: RGBColor(red: 1.0, green: 0.82, blue: 0.42),
                mid: RGBColor(red: 1.0, green: 0.72, blue: 0.24),
                bottom: RGBColor(red: 0.86, green: 0.54, blue: 0.10)
            ),
            Tone(
                top: RGBColor(red: 0.74, green: 1.0, blue: 0.68),
                mid: RGBColor(red: 0.58, green: 0.96, blue: 0.50),
                bottom: RGBColor(red: 0.34, green: 0.78, blue: 0.28)
            ),
            Tone(
                top: RGBColor(red: 1.0, green: 0.94, blue: 0.48),
                mid: RGBColor(red: 1.0, green: 0.86, blue: 0.24),
                bottom: RGBColor(red: 0.86, green: 0.68, blue: 0.10)
            )
        ]
    }

    public var audioLevel: Float
    public var isRecording: Bool
    public var isPaused: Bool
    public var isFinalizing: Bool
    public var style: Style

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private struct BarProfile {
        let heightMultiplier: CGFloat
        let response: CGFloat
        let speed: Double
        let phase: Double
        let floor: CGFloat
    }

    private let barProfiles: [BarProfile] = [
        .init(heightMultiplier: 0.74, response: 0.58, speed: 1.45, phase: 0.20, floor: 0.14),
        .init(heightMultiplier: 1.00, response: 1.00, speed: 1.86, phase: 1.10, floor: 0.20),
        .init(heightMultiplier: 0.90, response: 0.82, speed: 1.62, phase: 2.35, floor: 0.18),
        .init(heightMultiplier: 0.70, response: 0.52, speed: 2.05, phase: 3.05, floor: 0.12)
    ]

    public init(
        audioLevel: Float,
        isRecording: Bool = true,
        isPaused: Bool = false,
        isFinalizing: Bool = false,
        style: Style = .default
    ) {
        self.audioLevel = audioLevel
        self.isRecording = isRecording
        self.isPaused = isPaused
        self.isFinalizing = isFinalizing
        self.style = style
    }

    public var body: some View {
        TimelineView(.periodic(from: .now, by: frameInterval)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let level = currentActivityLevel(at: time)

            HStack(alignment: .center, spacing: style.barSpacing) {
                ForEach(Array(resolvedTones.enumerated()), id: \.offset) { index, tone in
                    bubbleBar(tone: tone, index: index, level: level, time: time)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .clipped()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Recording signal visualization")
    }

    private var frameInterval: TimeInterval {
        let framesPerSecond = reduceMotion ? style.reducedMotionFrameRate : style.activeFrameRate
        return 1.0 / max(1, framesPerSecond)
    }

    private var resolvedTones: [Tone] {
        let source = style.tones.isEmpty ? Style.defaultTones : style.tones
        if source.count == 4 {
            return source
        }

        let defaults = Style.defaultTones
        return (0..<4).map { index in
            if index < source.count {
                return source[index]
            }
            return defaults[min(index, defaults.count - 1)]
        }
    }

    private func currentActivityLevel(at time: TimeInterval) -> CGFloat {
        let rawLevel = min(max(CGFloat(audioLevel), 0), 1)
        let shapedLevel = min(1, CGFloat(pow(Double(rawLevel), 0.82)) * 1.08)

        if isRecording {
            return max(0.2, shapedLevel)
        }

        if isFinalizing {
            let pulse = reduceMotion ? 0.12 : (CGFloat(sin(time * 1.8)) + 1) * 0.06
            return 0.24 + pulse
        }

        if isPaused {
            let idle = reduceMotion ? 0.02 : (CGFloat(sin(time * 1.2)) + 1) * 0.025
            return 0.12 + idle
        }

        return 0.08
    }

    private func barHeight(for index: Int, level: CGFloat, time: TimeInterval) -> CGFloat {
        let profile = barProfiles[index]
        let primaryPhase = time * (reduceMotion ? 0.8 : profile.speed) + profile.phase
        let secondaryPhase = time * (reduceMotion ? 0.55 : (profile.speed * 0.72)) + (profile.phase * 1.7)
        let tertiaryPhase = (primaryPhase * 1.33) + (profile.phase * 0.6)
        let primaryMotion = reduceMotion ? 0.5 : (CGFloat(sin(primaryPhase)) + 1) * 0.5
        let secondaryMotion = reduceMotion ? 0.5 : (CGFloat(sin(secondaryPhase)) + 1) * 0.5
        let tertiaryMotion = reduceMotion ? 0.5 : (CGFloat(sin(tertiaryPhase)) + 1) * 0.5
        let motionMix = (primaryMotion * 0.54) + (secondaryMotion * 0.28) + (tertiaryMotion * 0.18)
        let speechEnergy = CGFloat(pow(Double(level), Double(0.84 + (0.12 * profile.response))))
        let dynamicResponse = speechEnergy * (0.24 + (motionMix * (0.72 + (0.18 * profile.response))))
        let accentResponse = speechEnergy * tertiaryMotion * (0.16 + (0.22 * profile.response))
        let peakBoost = isRecording ? speechEnergy * speechEnergy * (18 + (16 * profile.response)) : 0
        let baseHeight = 30 + (style.maxBarHeight * profile.floor) + (dynamicResponse * 44) + (accentResponse * 28) + peakBoost

        return min(style.maxBarHeight, baseHeight * profile.heightMultiplier)
    }

    private func bubbleBar(
        tone: Tone,
        index: Int,
        level: CGFloat,
        time: TimeInterval
    ) -> some View {
        let height = barHeight(for: index, level: level, time: time)
        let normalizedHeight = min(1, height / style.maxBarHeight)
        let glowStrength = isRecording ? 0.9 : (isFinalizing ? 0.62 : (isPaused ? 0.28 : 0.2))
        let coreGlowOpacity = 0.18 + (normalizedHeight * 0.22 * glowStrength)
        let outerGlowOpacity = 0.10 + (normalizedHeight * 0.18 * glowStrength)

        return Capsule(style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        tone.top.swiftUIColor,
                        tone.mid.swiftUIColor,
                        tone.bottom.swiftUIColor
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: style.barWidth, height: height)
            .background {
                Capsule(style: .continuous)
                    .fill(tone.mid.swiftUIColor.opacity(coreGlowOpacity))
                    .frame(width: style.barWidth * 0.96, height: max(18, height * 0.84))
                    .blur(radius: 11)
                    .scaleEffect(x: 1.12, y: 1.08)
            }
            .background {
                Capsule(style: .continuous)
                    .fill(tone.bottom.swiftUIColor.opacity(outerGlowOpacity))
                    .frame(width: style.barWidth * 1.04, height: max(24, height * 0.96))
                    .blur(radius: 22)
                    .scaleEffect(x: 1.26, y: 1.14)
                    .offset(y: 2)
            }
            .overlay(alignment: .topLeading) {
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.42),
                                Color.white.opacity(0.08),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: style.barWidth * 0.58, height: max(16, height * 0.34))
                    .offset(x: 4, y: 4)
            }
            .overlay {
                Capsule(style: .continuous)
                    .stroke(Color.white.opacity(0.14), lineWidth: 0.8)
            }
            .shadow(
                color: tone.bottom.swiftUIColor.opacity(0.16),
                radius: 8,
                x: 0,
                y: 4
            )
            .animation(
                reduceMotion
                    ? .linear(duration: 0.18)
                    : .interactiveSpring(response: 0.26, dampingFraction: 0.80, blendDuration: 0.14),
                value: height
            )
            .zIndex(index == 1 || index == 2 ? 1 : 0)
    }
}

#Preview("Recording") {
    ZStack {
        Color.black.opacity(0.92).ignoresSafeArea()

        RecordingSignalWaveView(
            audioLevel: 0.84,
            isRecording: true,
            style: .hero
        )
        .frame(width: 220, height: 150)
    }
}

#Preview("Paused") {
    ZStack {
        Color(red: 0.06, green: 0.06, blue: 0.07).ignoresSafeArea()

        RecordingSignalWaveView(
            audioLevel: 0.08,
            isRecording: false,
            isPaused: true
        )
        .frame(width: 180, height: 120)
    }
}
