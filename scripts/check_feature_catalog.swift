import Foundation

@main struct FeatureCatalogChecks {
    @MainActor static func main() throws {
        catalogIntegrity()
        searchBehavior()
        whitespaceQueries()
        try preferencesChecks()
        favoritesDraftRules()
        print("Feature catalog checks passed")
    }

    @MainActor static func catalogIntegrity() {
        let ids = FeatureCatalog.all.map(\.id)
        precondition(Set(ids).count == ids.count && ids.count == FeatureID.allCases.count && ids.count == 69, "ids \(ids.count)")
        precondition(Set(FeatureCatalog.all.map(\.title)).count == 69, "titles must be unique")
        precondition(FeatureCatalog.all.filter(\.isAvailable).count == 19)
        precondition(FeatureCatalog.descriptor(.securityCenter).availability == .available(.securityCenter))
        precondition(FeatureCatalog.descriptor(.loginSettings).availability == .available(.loginSettings))
        precondition(FeatureCatalog.descriptor(.paymentSettings).availability == .available(.paymentSettings))
        precondition(FeatureCatalog.descriptor(.loginDevices).availability == .available(.loginDevices))
        precondition(FeatureCatalog.defaultFavorites == [.creditCard, .pensionCommunity, .inclusiveFinance, .deposit, .wealthProduct, .loan, .lifePayment, .hotActivities, .cityZone])
        precondition(FeatureCatalog.descriptor(.loan).availability == .available(.myLoan))
        precondition(FeatureCatalog.descriptor(.phoneTransfer).availability == .available(.transferForm(method: .phone)))
        precondition(FeatureCatalog.descriptor(.transfer).availability == .available(.transfer(payerAccountID: nil)))
        precondition(FeatureCatalog.descriptor(.branchQueue).availability == .planned(stage: "M5 网点服务"))
        precondition(FeatureCatalog.descriptor(.branchQueue).plannedStageText == "计划阶段：M5 网点服务")
        precondition(FeatureCatalog.descriptor(.charity).plannedStageText == "后续规划")
        precondition(FeatureCategory.allCases.allSatisfy { !FeatureCatalog.features(in: $0).isEmpty })
        for id in FeatureID.allCases { precondition(FeatureCatalog.descriptor(id).id == id) }
    }

    @MainActor static func searchBehavior() {
        precondition(FeatureSearch.search("").isEmpty)
        let t = FeatureSearch.search("转账").map(\.id)
        precondition(t.first == .transfer, "\(t)")
        precondition(t.contains(.accountTransfer) && t.contains(.transferLimits))
        precondition(FeatureSearch.search("账单").map(\.id).prefix(2).contains(.monthlyBill))
        precondition(FeatureSearch.search("网点").contains { $0.id == .branchQueue })
        precondition(FeatureSearch.search("理财").contains { $0.id == .wealthProduct })
        precondition(FeatureSearch.search("vip").contains { $0.id == .customerLevel })
        for placeholder in ["分期借钱", "存金通", "个人养老金", "农银快e宝", "生活缴费"] {
            precondition(!FeatureSearch.search(placeholder).isEmpty, "首页占位词 \(placeholder) 无结果")
        }
        precondition(FeatureSearch.search("不存在的功能").isEmpty)
    }

    @MainActor static func whitespaceQueries() {
        precondition(FeatureSearch.search("   ").isEmpty && FeatureSearch.search("\u{3000}").isEmpty)
        precondition(FeatureSearch.search(" 转账  记录 ").map(\.id) == [.transferRecords])
        precondition(FeatureSearch.search("转账\u{3000}记录").map(\.id) == [.transferRecords])
    }

    @MainActor static func withSuite(_ body: (UserDefaults) throws -> Void) rethrows {
        let suite = "ABank.FeatureChecks." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        try body(defaults)
    }

    @MainActor static func preferencesChecks() throws {
        let key = FeaturePreferencesStore.storageKey
        precondition(key == "abank.featurePreferences.v1")
        precondition(FeaturePreferencesStore.maxFavorites == 9 && FeaturePreferencesStore.maxRecents == 8)

        // defaultsWhenEmpty
        withSuite { defaults in
            let store = FeaturePreferencesStore(defaults: defaults)
            precondition(store.favorites == FeatureCatalog.defaultFavorites)
            precondition(store.recents.isEmpty)
        }
        // favoritesRules
        withSuite { defaults in
            let store = FeaturePreferencesStore(defaults: defaults)
            precondition(store.setFavorites([.transfer, .loan, .transfer]) == [.transfer, .loan])
            let available = FeatureCatalog.all.prefix(11).map(\.id)
            precondition(store.setFavorites(Array(available)) == Array(available.prefix(9)))
            precondition(store.setFavorites([]) == [] && store.favorites.isEmpty)
            precondition(FeaturePreferencesStore(defaults: defaults).favorites.isEmpty)
            store.setFavorites([.loan, .myAccount])
            precondition(FeaturePreferencesStore(defaults: defaults).favorites == [.loan, .myAccount])
        }
        // unknownIDsDropped
        withSuite { defaults in
            defaults.set(Data(#"{"favorites":["transfer","removedFeature","loan"],"recents":["ghost"]}"#.utf8), forKey: key)
            let store = FeaturePreferencesStore(defaults: defaults)
            precondition(store.favorites == [.transfer, .loan] && store.recents.isEmpty)
        }
        // corruptDataFallsBack
        withSuite { defaults in
            defaults.set(Data("not json".utf8), forKey: key)
            precondition(FeaturePreferencesStore(defaults: defaults).favorites == FeatureCatalog.defaultFavorites)
        }
        // recentsRules + plannedNotRecorded
        withSuite { defaults in
            let store = FeaturePreferencesStore(defaults: defaults)
            store.recordUse(.transfer); store.recordUse(.loan); store.recordUse(.transfer)
            precondition(store.recents == [.transfer, .loan])
            store.recordUse(.branchQueue)
            precondition(store.recents == [.transfer, .loan])
            let available = FeatureCatalog.all.filter(\.isAvailable).map(\.id)
            for id in available.prefix(10) { store.recordUse(id) }
            precondition(store.recents.count == 8 && store.recents.first == available[9])
            precondition(FeaturePreferencesStore(defaults: defaults).recents == store.recents)
        }
        // notifies
        withSuite { defaults in
            let center = NotificationCenter()
            var count = 0
            let token = center.addObserver(forName: FeaturePreferencesStore.didChangeNotification, object: nil, queue: nil) { _ in count += 1 }
            defer { center.removeObserver(token) }
            let store = FeaturePreferencesStore(defaults: defaults, notificationCenter: center)
            store.setFavorites([.loan]); precondition(count == 1)
            store.recordUse(.transfer); precondition(count == 2)
            store.recordUse(.branchQueue); precondition(count == 2)
        }
    }

    @MainActor static func favoritesDraftRules() {
        var d = FavoritesDraft(ids: [.transfer, .loan])
        precondition(d.add(.loan) == .duplicate && d.ids == [.transfer, .loan])
        d.move(from: 1, to: 0); precondition(d.ids == [.loan, .transfer])
        d.remove(.loan); precondition(d.ids == [.transfer])
        precondition(d.add(.myAccount) == .added && d.ids == [.transfer, .myAccount])
        d.remove(.myAccount)
        var full = FavoritesDraft(ids: Array(FeatureCatalog.all.prefix(9).map(\.id)))
        precondition(full.add(FeatureCatalog.all[9].id) == .full && full.ids.count == 9)
        d.move(from: 0, to: 5); precondition(d.ids == [.transfer])
        d.move(from: 7, to: 0); precondition(d.ids == [.transfer])
        let trimmed = FavoritesDraft(ids: [.loan, .loan] + FeatureCatalog.all.prefix(12).map(\.id))
        precondition(trimmed.ids.count == 9 && trimmed.ids.first == .loan)
    }
}
