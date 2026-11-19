import UIKit
import SnapKit

final class WealthBondIndexView: UIView {
    var onTap: (() -> Void)?

    private let header = WealthSectionHeaderView(title: "债券指数")
    private let card = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        header.onTap = { [weak self] in self?.onTap?() }
        card.backgroundColor = .abankCardBackground
        card.layer.cornerRadius = CornerRadius.lg
        card.addShadow(color: .black, opacity: 0.06, offset: CGSize(width: 0, height: 2), radius: 8)

        let name = BankingPageStyle.text("中债-农行乡村振兴债券指数", style: .subheadline)
        let status = BankingPageStyle.text("暂无指数行情", style: .footnote, color: .abankTextSecondary)
        let content = UIStackView(arrangedSubviews: [name, status])
        content.axis = .vertical
        content.spacing = 8

        addSubview(header)
        addSubview(card)
        card.addSubview(content)
        header.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview() }
        card.snp.makeConstraints { make in
            make.top.equalTo(header.snp.bottom).offset(12)
            make.leading.trailing.bottom.equalToSuperview()
        }
        content.snp.makeConstraints { $0.edges.equalToSuperview().inset(Spacing.md) }
    }
}
