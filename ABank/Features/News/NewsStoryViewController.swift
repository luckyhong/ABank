import UIKit
import SafariServices
import SnapKit

final class NewsStoryViewController: BaseViewController {
    private let story: NewsStory

    init(story: NewsStory) {
        self.story = story
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupNavigationBar() {
        title = story.isDemo ? "每日知识" : "资讯详情"
        navigationController?.setNavigationBarHidden(false, animated: false)
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(back))
    }
    override func setupUI() {
        view.backgroundColor = .white
        let scroll = UIScrollView()
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        let title = UILabel()
        title.text = story.title
        title.font = .systemFont(ofSize: 24, weight: .semibold)
        title.numberOfLines = 0
        let meta = UILabel()
        meta.text = story.isDemo ? "学习示例 · 非实时新闻" : story.publisher + " · " + NewsDashboard.dateText(story.publishedAt)
        meta.font = .systemFont(ofSize: 13)
        meta.textColor = .abankTextSecondary
        let cover = NewsRemoteImageView()
        cover.contentMode = .scaleAspectFill
        cover.clipsToBounds = true
        cover.layer.cornerRadius = 8
        cover.isHidden = story.imageURL == nil
        cover.load(story.imageURL)
        let summary = UILabel()
        summary.numberOfLines = 0
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 7
        summary.attributedText = NSAttributedString(string: story.summary.isEmpty ? "请查看原文了解完整报道。" : story.summary, attributes: [.font: UIFont.systemFont(ofSize: 17), .foregroundColor: UIColor.abankTextPrimary, .paragraphStyle: style])
        let original = UIButton(type: .system)
        original.setTitle(story.channel == .video ? "观看视频  ›" : "查看原文  ›", for: .normal)
        original.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        original.tintColor = .abankTeal
        original.isHidden = story.url == nil
        original.addTarget(self, action: #selector(openOriginal), for: .touchUpInside)
        [title, meta, cover, summary, original].forEach { stack.addArrangedSubview($0) }
        view.addSubview(scroll)
        scroll.addSubview(stack)
        scroll.snp.makeConstraints { $0.edges.equalTo(view.safeAreaLayoutGuide) }
        stack.snp.makeConstraints { make in
            make.edges.equalTo(scroll.contentLayoutGuide).inset(20)
            make.width.equalTo(scroll.frameLayoutGuide).offset(-40)
        }
        cover.snp.makeConstraints { $0.height.equalTo(190).priority(.high) }
        original.snp.makeConstraints { $0.height.equalTo(44).priority(.high) }
    }
    @objc private func back() { navigationController?.popViewController(animated: true) }
    @objc private func openOriginal() {
        guard let url = story.url.flatMap({ NewsRSSParser.safeURL($0.absoluteString) }) else { return }
        present(SFSafariViewController(url: url), animated: true)
    }
}

final class NewsStoryListViewController: UITableViewController {
    private let stories: [NewsStory]
    init(title: String, stories: [NewsStory]) {
        self.stories = stories
        super.init(style: .plain)
        self.title = title
        hidesBottomBarWhenPushed = true
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(back))
        tableView.register(NewsArticleCell.self, forCellReuseIdentifier: NewsArticleCell.reuseId)
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100
        if stories.isEmpty {
            let label = UILabel()
            label.text = "暂无匹配资讯，试试其他关键词或频道"
            label.font = .systemFont(ofSize: 14)
            label.textColor = .abankTextSecondary
            label.textAlignment = .center
            label.numberOfLines = 0
            tableView.backgroundView = label
        }
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { stories.count }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NewsArticleCell.reuseId, for: indexPath) as! NewsArticleCell
        if case .article(let article) = NewsDashboard.entry(stories[indexPath.row]) { cell.configure(with: article) }
        return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        navigationController?.pushViewController(NewsStoryViewController(story: stories[indexPath.row]), animated: true)
    }
    @objc private func back() { navigationController?.popViewController(animated: true) }
}
