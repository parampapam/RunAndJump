//
//  PickupKindTests.swift
//  RunAndJumpTests
//
//  Created by Roman Pospelov on 25.07.2026.
//

import Testing
@testable import RunAndJump

struct PickupKindTests {

    @Test func coinTiersHaveIncreasingValue() {
        #expect(CoinTier.bronze.points < CoinTier.silver.points)
        #expect(CoinTier.silver.points < CoinTier.gold.points)
    }

    @Test func healthPickupMapsToHealthEvent() {
        #expect(PickupKind.health.event == .healthPickup)
    }

    @Test(arguments: CoinTier.allCases)
    func coinPickupMapsToBonusEventWithTierPoints(tier: CoinTier) {
        #expect(PickupKind.coin(tier).event == .bonusPickup(points: tier.points))
    }

    /// Очки за монету переживают гибель — значит, и монета не возвращается.
    @Test(arguments: CoinTier.allCases)
    func coinStaysCollectedAfterDeath(tier: CoinTier) {
        #expect(PickupKind.coin(tier).staysCollectedAfterDeath == true)
    }

    /// Здоровье при возрождении восстанавливается, поэтому аптечка возвращается.
    @Test func healthPickupReturnsAfterDeath() {
        #expect(PickupKind.health.staysCollectedAfterDeath == false)
    }

    @Test(arguments: CoinTier.allCases)
    func collectingCoinAddsTierPointsToState(tier: CoinTier) {
        let state = PlayerState(health: 3, bonusPoints: 10)
        let new = GameRules.apply(PickupKind.coin(tier).event, to: state)
        #expect(new.bonusPoints == 10 + tier.points)
        #expect(new.health == 3) // здоровье не меняется
    }
}
