import Testing
import Foundation

private func freshDefaults() -> UserDefaults {
    let name = "notchhider.tests.\(UUID().uuidString)"
    let d = UserDefaults(suiteName: name)!
    d.removePersistentDomain(forName: name)
    return d
}

@Suite struct BarSettingsTests {
    @Test func defaultsAreEnabledSquareWithMediumRadius() {
        let s = BarSettings(defaults: freshDefaults())
        #expect(s.enabled == true)
        #expect(s.roundCorners == false)
        #expect(s.cornerRadius == 8)
    }

    @Test func valuesPersistAcrossInstances() {
        let d = freshDefaults()
        let a = BarSettings(defaults: d)
        a.enabled = false
        a.roundCorners = true
        a.cornerRadius = 14
        let b = BarSettings(defaults: d)
        #expect(b.enabled == false)
        #expect(b.roundCorners == true)
        #expect(b.cornerRadius == 14)
    }

    @Test func storedRadiusIsKeptInSliderRange() {
        let s = BarSettings(defaults: freshDefaults())
        s.cornerRadius = 100
        #expect(s.cornerRadius == 20)
        s.cornerRadius = -3
        #expect(s.cornerRadius == 0)
    }
}

@Suite struct BarAppearanceSettingsTests {
    @Test func newSettingsDefaultToBlackWithIconAndMediumGlass() {
        let s = BarSettings(defaults: freshDefaults())
        #expect(s.look == .black)
        #expect(s.glassIntensity == 60)
        #expect(s.showMenuBarIcon == true)
    }

    @Test func appearanceSettingsPersistAcrossInstances() {
        let d = freshDefaults()
        let a = BarSettings(defaults: d)
        a.look = .glass
        a.glassIntensity = 35
        a.showMenuBarIcon = false
        let b = BarSettings(defaults: d)
        #expect(b.look == .glass)
        #expect(b.glassIntensity == 35)
        #expect(b.showMenuBarIcon == false)
    }

    @Test(arguments: [(set: 0.0, want: 1.0), (set: -20.0, want: 1.0), (set: 250.0, want: 100.0), (set: 1.0, want: 1.0), (set: 100.0, want: 100.0)])
    func glassIntensityStaysWithinOneToHundredPercent(_ c: (set: Double, want: Double)) {
        let s = BarSettings(defaults: freshDefaults())
        s.glassIntensity = c.set
        #expect(s.glassIntensity == c.want)
    }

    @Test func unknownStoredLookFallsBackToBlack() {
        let d = freshDefaults()
        d.set("neon", forKey: "look")
        #expect(BarSettings(defaults: d).look == .black)
    }
}
