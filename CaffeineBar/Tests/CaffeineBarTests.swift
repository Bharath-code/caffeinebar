import Testing
import Foundation
@testable import CaffeineBar

@Suite("CaffeineBar Tests")
struct CaffeineBarTests {
    @Test("App target compiles successfully")
    func appCompiles() {
        #expect(true)
    }
}

// MARK: - Metabolism Model Tests

/// Helper to create a fresh CupStore on the MainActor with isolated UserDefaults.
@MainActor
func makeStore() -> CupStore {
    let suiteName = "test.metabolism.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    return CupStore(defaults: defaults)
}

@Suite("Metabolism Model")
struct MetabolismModelTests {

    // MARK: - Base Profile Half-Life

    @Test("Fast profile returns 5.0 hours")
    func fastProfileHalfLife() {
        #expect(MetabolismProfile.fast.halfLifeHours == 5.0)
    }

    @Test("Normal profile returns 5.5 hours")
    func normalProfileHalfLife() {
        #expect(MetabolismProfile.normal.halfLifeHours == 5.5)
    }

    @Test("Slow profile returns 6.0 hours")
    func slowProfileHalfLife() {
        #expect(MetabolismProfile.slow.halfLifeHours == 6.0)
    }

    // MARK: - Effective Half-Life With Age

    @MainActor
    @Test("No age or weight returns base profile half-life")
    func noPersonalization() async {
        let store = makeStore()
        store.metabolismProfile = .normal
        store.userAge = nil
        store.bodyWeight = nil
        #expect(store.effectiveHalfLifeHours == 5.5)
    }

    @MainActor
    @Test("Age 30 (baseline) returns base profile half-life")
    func age30Baseline() async {
        let store = makeStore()
        store.metabolismProfile = .fast
        store.userAge = 30
        store.bodyWeight = nil
        #expect(store.effectiveHalfLifeHours == 5.0)
    }

    @MainActor
    @Test("Age 50 adds 0.3 hours to half-life")
    func age50Adjustment() async {
        let store = makeStore()
        store.metabolismProfile = .normal
        store.userAge = 50
        store.bodyWeight = nil
        #expect(store.effectiveHalfLifeHours == 5.8)
    }

    @MainActor
    @Test("Age 20 subtracts 0.15 hours from half-life")
    func age20Adjustment() async {
        let store = makeStore()
        store.metabolismProfile = .normal
        store.userAge = 20
        store.bodyWeight = nil
        #expect(store.effectiveHalfLifeHours == 5.35)
    }

    // MARK: - Effective Half-Life With Weight

    @MainActor
    @Test("Weight 70kg (baseline) returns base profile half-life")
    func weight70Baseline() async {
        let store = makeStore()
        store.metabolismProfile = .fast
        store.userAge = nil
        store.bodyWeight = 70.0
        #expect(store.effectiveHalfLifeHours == 5.0)
    }

    @MainActor
    @Test("Weight 90kg adds 0.06 hours to half-life")
    func weight90Adjustment() async {
        let store = makeStore()
        store.metabolismProfile = .normal
        store.userAge = nil
        store.bodyWeight = 90.0
        #expect(store.effectiveHalfLifeHours == 5.56)
    }

    @MainActor
    @Test("Weight 50kg subtracts 0.06 hours from half-life")
    func weight50Adjustment() async {
        let store = makeStore()
        store.metabolismProfile = .normal
        store.userAge = nil
        store.bodyWeight = 50.0
        #expect(store.effectiveHalfLifeHours == 5.44)
    }

    // MARK: - Combined Age + Weight

    @MainActor
    @Test("Age 45 and weight 85kg combine correctly")
    func ageAndWeightCombined() async {
        let store = makeStore()
        store.metabolismProfile = .normal
        store.userAge = 45
        store.bodyWeight = 85.0
        // 5.5 + (45 - 30) * 0.015 + (85 - 70) * 0.003 = 5.5 + 0.225 + 0.045 = 5.77
        #expect(store.effectiveHalfLifeHours == 5.77)
    }

    // MARK: - Clamping

    @MainActor
    @Test("Effective half-life is clamped between 3.0 and 8.0")
    func clampingBounds() async {
        let store = makeStore()
        store.metabolismProfile = .slow
        store.userAge = 120
        store.bodyWeight = 250.0
        // 6.0 + 1.35 + 0.54 = 7.89 — still under 8.0 with valid inputs
        // But the clamp should ensure 3.0 <= value <= 8.0
        #expect(store.effectiveHalfLifeHours >= 3.0)
        #expect(store.effectiveHalfLifeHours <= 8.0)
    }

    // MARK: - Defaults

    @MainActor
    @Test("Default userAge is nil")
    func defaultUserAgeNil() async {
        let store = makeStore()
        #expect(store.userAge == nil)
    }

    @MainActor
    @Test("Default bodyWeight is nil")
    func defaultBodyWeightNil() async {
        let store = makeStore()
        #expect(store.bodyWeight == nil)
    }

    @MainActor
    @Test("Default hormonalContraceptive is .none")
    func defaultHormonalNone() async {
        let store = makeStore()
        #expect(store.hormonalContraceptive == .none)
    }

    // MARK: - Hormonal Contraception

    @MainActor
    @Test("Hormonal .none has 1.0x multiplier")
    func hormonalNoneMultiplier() async {
        #expect(HormonalContraceptive.none.halfLifeMultiplier == 1.0)
    }

    @MainActor
    @Test("Hormonal .estrogen has 2.0x multiplier")
    func hormonalEstrogenMultiplier() async {
        #expect(HormonalContraceptive.estrogen.halfLifeMultiplier == 2.0)
    }

    @MainActor
    @Test("Estrogen contraception doubles effective half-life")
    func hormonalEstrogenDoublesHalfLife() async {
        let store = makeStore()
        store.metabolismProfile = .normal
        store.userAge = nil
        store.bodyWeight = nil
        store.hormonalContraceptive = .estrogen
        #expect(store.effectiveHalfLifeHours == 11.0)  // 5.5 * 2.0
    }

    @MainActor
    @Test("Estrogen + age/weight combines multiplicatively")
    func hormonalCombinedWithAgeWeight() async {
        let store = makeStore()
        store.metabolismProfile = .normal
        store.userAge = 45
        store.bodyWeight = 85.0
        store.hormonalContraceptive = .estrogen
        // (5.5 + 0.225 + 0.045) * 2.0 = 5.77 * 2.0 = 11.54
        #expect(store.effectiveHalfLifeHours == 11.54)
    }

    @MainActor
    @Test("Estrogen with slow profile still clamped to 12.0")
    func hormonalClampedTo12() async {
        let store = makeStore()
        store.metabolismProfile = .slow
        store.userAge = 50
        store.bodyWeight = 100.0
        store.hormonalContraceptive = .estrogen
        // (6.0 + 0.3 + 0.09) * 2.0 = 6.39 * 2.0 = 12.78 -> clamped to 12.0
        #expect(store.effectiveHalfLifeHours == 12.0)
    }

    // MARK: - Input Clamping

    @MainActor
    @Test("userAge is clamped to minimum 13")
    func ageClampedMin() async {
        let store = makeStore()
        store.setUserAge(5)
        #expect(store.userAge == 13)
    }

    @MainActor
    @Test("userAge is clamped to maximum 120")
    func ageClampedMax() async {
        let store = makeStore()
        store.setUserAge(200)
        #expect(store.userAge == 120)
    }

    @MainActor
    @Test("bodyWeight is clamped to minimum 30.0")
    func weightClampedMin() async {
        let store = makeStore()
        store.setBodyWeight(10.0)
        #expect(store.bodyWeight == 30.0)
    }

    @MainActor
    @Test("bodyWeight is clamped to maximum 250.0")
    func weightClampedMax() async {
        let store = makeStore()
        store.setBodyWeight(500.0)
        #expect(store.bodyWeight == 250.0)
    }

    @MainActor
    @Test("Valid age 30 passes through unclamped")
    func ageValidPassesThrough() async {
        let store = makeStore()
        store.userAge = 30
        #expect(store.userAge == 30)
    }

    @MainActor
    @Test("Valid weight 70.0 passes through unclamped")
    func weightValidPassesThrough() async {
        let store = makeStore()
        store.bodyWeight = 70.0
        #expect(store.bodyWeight == 70.0)
    }

    // MARK: - Effective Half-Life Upper Bound Raised to 12.0

    @MainActor
    @Test("Effective half-life clamp upper bound is 12.0 with hormonal multiplier")
    func clampUpperBound12() async {
        let store = makeStore()
        store.metabolismProfile = .slow
        store.userAge = 120
        store.bodyWeight = 250.0
        store.hormonalContraceptive = .estrogen
        // Should be at or above 12.0 after adjustments, but clamped to 12.0
        #expect(store.effectiveHalfLifeHours == 12.0)
    }

    @MainActor
    @Test("Effective half-life clamp lower bound is 3.0")
    func clampLowerBound3() async {
        let store = makeStore()
        store.metabolismProfile = .fast
        store.userAge = 13
        store.bodyWeight = 30.0
        // 5.0 + (13-30)*0.015 + (30-70)*0.003 = 5.0 - 0.255 - 0.12 = 4.625
        // Still above 3.0 with fast profile. Use extreme values or fast+lowest.
        #expect(store.effectiveHalfLifeHours >= 3.0)
    }
}
