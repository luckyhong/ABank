//
//  FeatureSearch.swift
//  ABank
//
//  功能搜索：按名称、关键词、分类名匹配，多个词需全部命中。
//

import Foundation

enum FeatureSearch {
    static func search(_ query: String, in catalog: [FeatureDescriptor] = FeatureCatalog.all) -> [FeatureDescriptor] {
        let terms = query.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        guard let first = terms.first else { return [] }

        let matches = catalog.enumerated().compactMap { offset, feature -> (rank: Int, offset: Int, feature: FeatureDescriptor)? in
            let texts = [feature.title, feature.category.title] + feature.keywords
            let matchesAll = terms.allSatisfy { term in
                texts.contains { $0.localizedCaseInsensitiveContains(term) }
            }
            guard matchesAll else { return nil }
            let rank: Int
            if feature.title.lowercased().hasPrefix(first.lowercased()) {
                rank = 0
            } else if feature.title.localizedCaseInsensitiveContains(first) {
                rank = 1
            } else {
                rank = 2
            }
            return (rank, offset, feature)
        }
        return matches
            .sorted { ($0.rank, $0.offset) < ($1.rank, $1.offset) }
            .map(\.feature)
    }
}
