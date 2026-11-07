//
//  BranchListViewController.swift
//  ABank
//
//  网点列表：城市切换、有效号横幅、示意图、筛选与列表。
//

import UIKit
import SnapKit

final class BranchListViewController: BranchFlowViewController, RouteHosting {
    private enum Filter: Int, CaseIterable {
        case all, open, personalCash, personalNonCash, corporate

        var title: String {
            switch self {
            case .all: return "全部"
            case .open: return "营业中"
            case .personalCash: return BranchBusiness.personalCash.title
            case .personalNonCash: return BranchBusiness.personalNonCash.title
            case .corporate: return BranchBusiness.corporate.title
            }
        }

        func matches(_ branch: Branch, state: BranchOpenState) -> Bool {
            switch self {
            case .all: return true
            case .open: return state == .open
            case .personalCash: return branch.businesses.contains(.personalCash)
            case .personalNonCash: return branch.businesses.contains(.personalNonCash)
            case .corporate: return branch.businesses.contains(.corporate)
            }
        }
    }

    private var filter: Filter = .all
    private var highlightedID: String?
    private var rows: [String: UIView] = [:]

    var hostedRoute: AppRoute? { .branchList }

    override func setupUI() {
        super.setupUI()
        title = "网点查询"
    }

    override func setupNavigationBar() {
        super.setupNavigationBar()
        let history = UIBarButtonItem(title: "我的记录", style: .plain, target: self, action: #selector(openHistory))
        history.accessibilityIdentifier = "branchList.history"
        navigationItem.rightBarButtonItem = history
    }

    @objc private func openHistory() {
        router.open(.branchServiceHistory, from: self)
    }

    override func refreshBankingData() {
        clearContent()
        rows = [:]
        let city = cities.currentCity
        let now = dates.now
        let all = BranchCatalog.branches(inCity: city.id)
        if let id = highlightedID, !all.contains(where: { $0.id == id }) { highlightedID = nil }

        contentStack.addArrangedSubview(cityButton(city))

        if let ticket = services.activeTicket {
            let banner = ActiveTicketBannerView(ticket: ticket, status: services.status(of: ticket))
            banner.onTap = { [weak self] in
                guard let self else { return }
                self.router.open(.ticketDetail(ticketID: ticket.id), from: self)
            }
            contentStack.addArrangedSubview(banner)
        }

        let map = BranchSketchMapView()
        map.configure(branches: all, highlightedID: highlightedID)
        map.onPinTapped = { [weak self] id in self?.highlight(id) }
        map.snp.makeConstraints { $0.height.equalTo(180) }
        contentStack.addArrangedSubview(map)

        let chips = BranchChipBar(titles: Filter.allCases.map(\.title), selected: filter.rawValue, idPrefix: "branchList.filter")
        chips.onSelect = { [weak self] index in
            self?.filter = Filter(rawValue: index) ?? .all
            self?.refreshBankingData()
        }
        contentStack.addArrangedSubview(chips)

        let visible = all.filter { filter.matches($0, state: BranchSchedule.openState(of: $0, at: now, dates: dates)) }
        guard !visible.isEmpty else {
            addEmptyState("当前城市暂无符合条件的网点", id: "branchList.empty")
            return
        }
        let group = UIStackView(arrangedSubviews: visible.map { branch in
            let row = BranchRowView(branch: branch, state: BranchSchedule.openState(of: branch, at: now, dates: dates),
                                    highlighted: branch.id == highlightedID)
            row.onTap = { [weak self] in
                guard let self else { return }
                self.router.open(.branchDetail(branchID: branch.id), from: self)
            }
            rows[branch.id] = row
            return row
        })
        group.axis = .vertical
        group.backgroundColor = .abankCardBackground
        group.layer.cornerRadius = 10
        group.clipsToBounds = true
        contentStack.addArrangedSubview(group)
    }

    private func cityButton(_ city: BranchCity) -> UIView {
        let button = UIButton(type: .system)
        button.setTitle(" " + city.name + " ▾", for: .normal)
        button.titleLabel?.font = .abankBodyMedium()
        button.setTitleColor(.abankTextPrimary, for: .normal)
        button.setImage(UIImage(systemName: "location.fill"), for: .normal)
        button.tintColor = .abankPrimary
        button.contentHorizontalAlignment = .leading
        button.accessibilityIdentifier = "branchList.city"
        button.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.router.open(.cityPicker, from: self)
        }, for: .touchUpInside)
        return button
    }

    private func highlight(_ id: String) {
        highlightedID = id
        if let branch = BranchCatalog.branch(id: id),
           !filter.matches(branch, state: BranchSchedule.openState(of: branch, at: dates.now, dates: dates)) {
            filter = .all
        }
        refreshBankingData()
        view.layoutIfNeeded()
        if let row = rows[id] {
            let frame = row.convert(row.bounds, to: scrollView)
            scrollView.scrollRectToVisible(frame.insetBy(dx: 0, dy: -Spacing.md), animated: true)
        }
    }
}
