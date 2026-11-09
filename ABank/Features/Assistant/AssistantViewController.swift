//
//  AssistantViewController.swift
//  ABank
//
//  在线助手：本地关键词匹配，会话只存于页面内存，离开即清空。
//

import UIKit
import SnapKit

final class AssistantViewController: BaseViewController {

    private let scrollView = UIScrollView()
    private let stack = UIStackView()
    private let inputField = UITextField()
    private let sendButton = UIButton(type: .system)

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        hidesBottomBarWhenPushed = true
    }

    convenience init() { self.init(nibName: nil, bundle: nil) }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupNavigationBar() {
        title = "在线助手"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage.abankBackIndicator, style: .plain, target: self, action: #selector(backTapped)
        )
    }

    override func setupUI() {
        view.backgroundColor = UIColor(red: 245 / 255, green: 245 / 255, blue: 245 / 255, alpha: 1)

        let disclaimer = UILabel()
        disclaimer.text = "智能助手为本地演示，回答仅供参考"
        disclaimer.font = .systemFont(ofSize: 12)
        disclaimer.textColor = .abankTextTertiary
        disclaimer.textAlignment = .center

        stack.axis = .vertical
        stack.spacing = 12
        stack.layoutMargins = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        stack.isLayoutMarginsRelativeArrangement = true
        scrollView.keyboardDismissMode = .interactive
        scrollView.alwaysBounceVertical = true
        scrollView.addSubview(stack)

        let bar = UIView()
        bar.backgroundColor = .white
        inputField.placeholder = "请输入您的问题"
        inputField.font = .systemFont(ofSize: 15)
        inputField.returnKeyType = .send
        inputField.delegate = self
        inputField.accessibilityIdentifier = "assistant.input"
        sendButton.setTitle("发送", for: .normal)
        sendButton.setTitleColor(.abankOrange, for: .normal)
        sendButton.accessibilityIdentifier = "assistant.send"
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        bar.addSubview(inputField)
        bar.addSubview(sendButton)

        [disclaimer, scrollView, bar].forEach(view.addSubview)
        disclaimer.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(6)
            make.leading.trailing.equalToSuperview()
        }
        bar.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.keyboardLayoutGuide.snp.top)
        }
        inputField.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(12)
            make.leading.equalToSuperview().offset(16)
            make.height.equalTo(28)
            make.trailing.equalTo(sendButton.snp.leading).offset(-8)
        }
        sendButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalTo(inputField)
            make.width.equalTo(44)
        }
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(disclaimer.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(bar.snp.top)
        }
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }

        append(AssistantMessageView(text: AssistantEngine.welcomeText, isUser: false,
                                    quickQuestions: AssistantEngine.quickQuestions))
    }

    private func append(_ message: AssistantMessageView) {
        message.onFeatureTapped = { [weak self] id in
            guard let self else { return }
            AppRouter.shared.open(feature: id, from: self)
        }
        message.onQuickTapped = { [weak self] question in self?.send(question) }
        stack.addArrangedSubview(message)
        view.layoutIfNeeded()
        let offset = max(0, scrollView.contentSize.height - scrollView.bounds.height)
        scrollView.setContentOffset(CGPoint(x: 0, y: offset), animated: true)
    }

    private func send(_ text: String) {
        guard let reply = AssistantEngine.reply(to: text) else { return }
        append(AssistantMessageView(text: text, isUser: true))
        append(AssistantMessageView(text: reply.text, isUser: false, features: reply.features))
    }

    @objc private func sendTapped() {
        let text = inputField.text ?? ""
        inputField.text = nil
        send(text)
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
}

extension AssistantViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendTapped()
        return false
    }
}
