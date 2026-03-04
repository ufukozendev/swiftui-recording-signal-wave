import Testing
@testable import RecordingSignalWave

@Test func defaultStyleContainsFourTones() {
    #expect(RecordingSignalWaveView.Style.default.tones.count == 4)
}

@Test func heroStyleIsLargerThanDefault() {
    #expect(RecordingSignalWaveView.Style.hero.barWidth > RecordingSignalWaveView.Style.default.barWidth)
    #expect(RecordingSignalWaveView.Style.hero.maxBarHeight > RecordingSignalWaveView.Style.default.maxBarHeight)
}

@Test func compactStyleKeepsOverlap() {
    #expect(RecordingSignalWaveView.Style.compact.barSpacing < 0)
}

@Test func customToneRoundTripsValues() {
    let tone = RecordingSignalWaveView.Tone(
        top: .init(red: 0.1, green: 0.2, blue: 0.3),
        mid: .init(red: 0.4, green: 0.5, blue: 0.6),
        bottom: .init(red: 0.7, green: 0.8, blue: 0.9)
    )

    #expect(tone.top == .init(red: 0.1, green: 0.2, blue: 0.3))
    #expect(tone.mid == .init(red: 0.4, green: 0.5, blue: 0.6))
    #expect(tone.bottom == .init(red: 0.7, green: 0.8, blue: 0.9))
}
