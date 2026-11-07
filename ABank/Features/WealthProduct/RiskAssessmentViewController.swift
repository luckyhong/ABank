//
//  RiskAssessmentViewController.swift
//  ABank
//
//  风险测评：5 题单选，全部作答后提交；提交后显示等级与有效期，可重新测评。
//

import UIKit
import SnapKit

final class RiskAssessmentViewController: WealthFlowViewController, RouteHosting {
    private var answers: [Int?] = Array(repeating: nil, count: RiskQuestionnaire.questions.count)
    private var showsResult = false

    var hostedRoute: AppRoute? { .riskAssessment }

    override func setupUI() {
        super.setupUI()
        title = "风险测评"
    }

    override func refreshBankingData() {
        clearContent()
        addStatusCard()
        if showsResult {
            addResultActions()
        } else {
            addQuestions()
        }
        addNotice("本机模拟 · 测评结果仅用于演示")
    }

    private func addStatusCard() {
        let headline = UILabel()
        headline.font = .systemFont(ofSize: 22, weight: .semibold)
        headline.accessibilityIdentifier = "risk.status"
        let detail: String
        switch risk.state {
        case .none:
            headline.text = "尚未测评"
            headline.textColor = .abankTextPrimary
            detail = "完成 5 道题，了解您的风险承受等级。结果有效期 365 天。"
        case .valid(let profile, let expiresOn):
            headline.text = "\(profile.title)（\(profile.shortTitle)）"
            headline.textColor = .abankPrimary
            detail = "有效期至 \(expiresOn)。可购买风险等级不高于 R\(min(profile.rawValue, ProductRiskLevel.allCases.count)) 的产品。"
        case .expired(let profile):
            headline.text = "已过期"
            headline.textColor = .abankWarning
            detail = "上次结果为\(profile.title)（\(profile.shortTitle)），请重新测评。"
        }
        addCard([headline, branchCaption(detail)])
    }

    private func addQuestions() {
        for (qIndex, question) in RiskQuestionnaire.questions.enumerated() {
            var views: [UIView] = [branchTitleLine("\(qIndex + 1). \(question.title)")]
            for (oIndex, option) in question.options.enumerated() {
                let row = RiskOptionRow(title: option, selected: answers[qIndex] == oIndex, id: "risk.q\(qIndex).\(oIndex)")
                row.onTap = { [weak self] in
                    self?.answers[qIndex] = oIndex
                    self?.refreshBankingData()
                }
                views.append(row)
            }
            addCard(views, spacing: 0)
        }
        let complete = answers.allSatisfy { $0 != nil }
        let submit = addButton(complete ? "提交测评" : "请完成全部题目", id: "risk.submit") { [weak self] in self?.submit() }
        if !complete {
            submit.isEnabled = false
            submit.backgroundColor = .abankTextTertiary
        }
    }

    private func addResultActions() {
        _ = addButton("完成", id: "risk.done") { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        _ = addButton("重新测评", id: "risk.retake", primary: false) { [weak self] in
            self?.answers = Array(repeating: nil, count: RiskQuestionnaire.questions.count)
            self?.showsResult = false
            self?.refreshBankingData()
        }
    }

    private func submit() {
        do {
            try risk.submit(answers: answers.compactMap { $0 })
            showsResult = true
            refreshBankingData()
        } catch {
            showError(error)
        }
    }
}
