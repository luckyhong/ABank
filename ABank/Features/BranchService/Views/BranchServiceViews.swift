//
//  BranchServiceViews.swift
//  ABank
//
//  网点服务通用页面基类与复用视图：状态标签、网点行、选项条、营业时间表、有效号横幅。
//

import UIKit
import SnapKit

/// 网点服务页面基类：持有城市与记录 Store，任一变化、回到前台或跨日时调用 `refreshBankingData()`。
class BranchFlowViewController: TransferFlowViewController {
    let cities: CitySelectionStore
    let services: BranchServiceStore
    let dates: BankingDateContext

    init(cities: CitySelectionStore = .shared, services: BranchServiceStore = .shared, dates: BankingDateContext = .system) {
        self.cities = cities
        self.services = services
        self.dates = dates
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(branchDataDidChange),
                                               name: CitySelectionStore.didChangeNotification, object: cities)
        NotificationCenter.default.addObserver(self, selector: #selector(branchDataDidChange),
                                               name: BranchServiceStore.didChangeNotification, object: services)
    }

    @objc private func branchDataDidChange() {
        guard isViewLoaded else { return }
        refreshBankingData()
    }

    func clearContent() {
        contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
    }

    /// 白底圆角卡片，内容纵向排列。
    @discardableResult
    func addCard(_ views: [UIView], spacing: CGFloat = Spacing.sm, insets: CGFloat = Spacing.md) -> UIView {
        let card = BranchCardView(views, spacing: spacing, insets: insets)
        contentStack.addArrangedSubview(card)
        return card
    }

    func addSectionTitle(_ text: String) {
        let label = UILabel()
        label.text = text
        label.font = .abankBodyMedium()
        label.textColor = .abankTextPrimary
        contentStack.addArrangedSubview(label)
    }

    func addEmptyState(_ text: String, id: String) {
        let label = UILabel()
        label.text = text
        label.font = .abankBody()
        label.textColor = .abankTextSecondary
        label.textAlignment = .center
        label.numberOfLines = 0
        label.accessibilityIdentifier = id
        let card = BranchCardView([label], spacing: 0, insets: Spacing.xl)
        contentStack.addArrangedSubview(card)
    }

    func confirm(_ message: String, confirmTitle: String = "确定", action: @escaping () -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: confirmTitle, style: .destructive) { _ in action() })
        present(alert, animated: true)
    }

    func showError(_ error: Error) {
        showToast((error as? BranchServiceError)?.errorDescription ?? BranchServiceError.saveFailed.errorDescription!)
    }

    func dayLabel(_ day: Date) -> String {
        let weekdays = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
        let weekday = weekdays[dates.calendar.component(.weekday, from: day) - 1]
        return dates.string(from: day, format: "MM月dd日") + " " + weekday
    }
}

/// 白底圆角卡片。
final class BranchCardView: UIView {
    let stack = UIStackView()

    init(_ views: [UIView], spacing: CGFloat = Spacing.sm, insets: CGFloat = Spacing.md) {
        super.init(frame: .zero)
        backgroundColor = .abankCardBackground
        layer.cornerRadius = 10
        stack.axis = .vertical
        stack.spacing = spacing
        views.forEach(stack.addArrangedSubview)
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(insets) }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

/// 营业状态描边标签（沿用首页网点卡样式）。
final class BranchStatusTagView: UIView {
    private let label = UILabel()

    init(text: String, active: Bool) {
        super.init(frame: .zero)
        let color: UIColor = active ? .abankPrimary : .abankTextTertiary
        label.text = text
        label.font = .systemFont(ofSize: 11)
        label.textColor = color
        layer.borderColor = color.cgColor
        layer.borderWidth = 0.8
        layer.cornerRadius = 4
        addSubview(label)
        label.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 1, left: 5, bottom: 1, right: 5)) }
        setContentHuggingPriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    convenience init(state: BranchOpenState) {
        self.init(text: state.title, active: state == .open || state == .selfService)
    }

    convenience init(ticketStatus: QueueTicketStatus) {
        self.init(text: ticketStatus.title, active: ticketStatus.isActive)
    }

    convenience init(reservationStatus: ReservationStatus) {
        self.init(text: reservationStatus.title, active: reservationStatus == .pending)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

/// 一行文字：左侧主文，右侧可选附件视图。
func branchTitleLine(_ text: String, font: UIFont = .abankBodyMedium(), trailing: [UIView] = []) -> UIStackView {
    let label = UILabel()
    label.text = text
    label.font = font
    label.textColor = .abankTextPrimary
    label.numberOfLines = 0
    let line = UIStackView(arrangedSubviews: [label] + trailing + [UIView()])
    line.spacing = Spacing.sm
    line.alignment = .center
    return line
}

func branchCaption(_ text: String, color: UIColor = .abankTextSecondary) -> UILabel {
    let label = UILabel()
    label.text = text
    label.font = .abankCaption()
    label.textColor = color
    label.numberOfLines = 0
    return label
}

func branchDistanceText(_ meters: Int) -> String {
    meters >= 1000 ? String(format: "%.1f公里", Double(meters) / 1000) : "\(meters)米"
}

/// 网点列表行：名称 + 状态标签、距离、地址。
final class BranchRowView: UIControl {
    var onTap: (() -> Void)?

    init(branch: Branch, state: BranchOpenState, highlighted: Bool) {
        super.init(frame: .zero)
        accessibilityIdentifier = "branchList.row.\(branch.id)"
        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityLabel = [branch.name, state.title, branchDistanceText(branch.distanceMeters), branch.address].joined(separator: "，")

        let distance = branchCaption(branchDistanceText(branch.distanceMeters))
        distance.setContentHuggingPriority(.required, for: .horizontal)
        let title = branchTitleLine(branch.name, trailing: [BranchStatusTagView(state: state)])
        title.addArrangedSubview(distance)
        let labels = UIStackView(arrangedSubviews: [title, branchCaption(branch.address)])
        labels.axis = .vertical
        labels.spacing = Spacing.xs
        labels.isUserInteractionEnabled = false
        addSubview(labels)
        labels.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 12, left: Spacing.md, bottom: 12, right: Spacing.md)) }
        let line = UIView()
        line.backgroundColor = .abankSeparator.withAlphaComponent(0.5)
        addSubview(line)
        line.snp.makeConstraints { $0.leading.trailing.equalToSuperview().inset(Spacing.md); $0.bottom.equalToSuperview(); $0.height.equalTo(0.5) }
        if highlighted {
            backgroundColor = UIColor.abankPrimary.withAlphaComponent(0.08)
        }
        addAction(UIAction { [weak self] _ in self?.onTap?() }, for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

/// 横向选项条：筛选、业务、日期共用。选中项为主色实心，不可用项置灰。
final class BranchChipBar: UIView {
    var onSelect: ((Int) -> Void)?
    private let scrollView = UIScrollView()
    private let stack = UIStackView()

    init(titles: [String], selected: Int?, enabled: [Bool]? = nil, idPrefix: String) {
        super.init(frame: .zero)
        scrollView.showsHorizontalScrollIndicator = false
        stack.spacing = Spacing.sm
        addSubview(scrollView)
        scrollView.addSubview(stack)
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        stack.snp.makeConstraints {
            $0.edges.equalTo(scrollView.contentLayoutGuide)
            $0.height.equalTo(scrollView.frameLayoutGuide)
        }
        for (index, title) in titles.enumerated() {
            let isEnabled = enabled?[index] ?? true
            let isSelected = index == selected
            let button = UIButton(type: .system)
            button.setTitle(title, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 14, weight: isSelected ? .medium : .regular)
            button.titleLabel?.numberOfLines = 2
            button.titleLabel?.textAlignment = .center
            button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
            button.layer.cornerRadius = 15
            button.layer.borderWidth = isSelected ? 0 : 0.8
            button.layer.borderColor = UIColor.abankSeparator.cgColor
            button.backgroundColor = isSelected ? .abankPrimary : .abankCardBackground
            button.setTitleColor(isSelected ? .white : (isEnabled ? .abankTextPrimary : .abankTextTertiary), for: .normal)
            button.isEnabled = isEnabled
            button.accessibilityIdentifier = "\(idPrefix).\(index)"
            if isSelected { button.accessibilityTraits.insert(.selected) }
            button.addAction(UIAction { [weak self] _ in self?.onSelect?(index) }, for: .touchUpInside)
            stack.addArrangedSubview(button)
        }
        snp.makeConstraints { $0.height.greaterThanOrEqualTo(34) }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

/// 本周营业时间表：周一到周日，今天高亮。
final class BusinessHoursTableView: UIView {
    init(hours: BusinessHours, todayWeekday: Int) {
        super.init(frame: .zero)
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 6
        let names = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
        for weekday in [2, 3, 4, 5, 6, 7, 1] {
            let isToday = weekday == todayWeekday
            let text: String
            if hours.isAllDay {
                text = "24 小时自助服务"
            } else if let day = hours.hours(onWeekday: weekday) {
                var parts = Self.time(day.open) + "-" + Self.time(day.close)
                if let start = day.lunchStart, let end = day.lunchEnd {
                    parts += "（午休 " + Self.time(start) + "-" + Self.time(end) + "）"
                }
                text = parts
            } else {
                text = "休息"
            }
            let name = branchCaption(names[weekday - 1] + (isToday ? "（今天）" : ""), color: isToday ? .abankPrimary : .abankTextSecondary)
            let value = branchCaption(text, color: isToday ? .abankPrimary : .abankTextPrimary)
            value.textAlignment = .right
            let row = UIStackView(arrangedSubviews: [name, value])
            row.distribution = .fill
            name.setContentHuggingPriority(.required, for: .horizontal)
            stack.addArrangedSubview(row)
        }
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }
        accessibilityIdentifier = "branchDetail.hours"
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    static func time(_ minute: Int) -> String {
        String(format: "%02d:%02d", minute / 60, minute % 60)
    }
}

/// 有效号横幅：号码与状态，点击进入号票详情。
final class ActiveTicketBannerView: UIControl {
    var onTap: (() -> Void)?

    init(ticket: QueueTicket, status: QueueTicketStatus) {
        super.init(frame: .zero)
        backgroundColor = UIColor.abankPrimary.withAlphaComponent(0.1)
        layer.cornerRadius = 10
        accessibilityIdentifier = "branch.activeTicketBanner"
        isAccessibilityElement = true
        accessibilityTraits = .button
        let icon = UIImageView(image: UIImage(systemName: "number.circle.fill"))
        icon.tintColor = .abankPrimary
        icon.snp.makeConstraints { $0.size.equalTo(24) }
        let text = "我的号票 \(ticket.number) · \(status.title)" + (status.ahead > 0 ? " · 前方 \(status.ahead) 人" : "")
        let label = UILabel()
        label.text = text
        label.font = .abankBodyMedium()
        label.textColor = .abankPrimaryDark
        label.numberOfLines = 0
        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = .abankPrimaryDark
        chevron.setContentHuggingPriority(.required, for: .horizontal)
        let stack = UIStackView(arrangedSubviews: [icon, label, chevron])
        stack.spacing = Spacing.sm
        stack.alignment = .center
        stack.isUserInteractionEnabled = false
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(12) }
        accessibilityLabel = text
        addAction(UIAction { [weak self] _ in self?.onTap?() }, for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
