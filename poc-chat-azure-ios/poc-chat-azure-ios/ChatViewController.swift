
import UIKit

class ChatViewController: UITableViewController, ChatDisplayLogic {
    // ChatRow: either a message or a timestamp label (now contains formatted string for timestamp)
    private var chatRows: [ChatRow] = []
    private var isOtherUserTyping: Bool = false
    private let messageInputBar = MessageInputBar()
    private var inputBarBottomConstraint: NSLayoutConstraint?

    var interactor: ChatBusinessLogic?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Chat"
        tableView.register(MessageBubbleCell.self, forCellReuseIdentifier: "MessageBubbleCell")
        tableView.register(TimestampLabelCell.self, forCellReuseIdentifier: "TimestampLabelCell")
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .interactive
        setupInputBar()
        build()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        interactor?.startAZS()
    }

    private func build() {
        let interactor = ChatInteractor(chatService: ChatService())
        let presenter = ChatPresenter()
        interactor.presenter = presenter
        presenter.viewController = self
        self.interactor = interactor
    }

    private func setupInputBar() {
        messageInputBar.delegate = self
        messageInputBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(messageInputBar)
        inputBarBottomConstraint = messageInputBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        NSLayoutConstraint.activate([
            messageInputBar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            messageInputBar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            inputBarBottomConstraint!,
            messageInputBar.heightAnchor.constraint(greaterThanOrEqualToConstant: 52)
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let inputBarHeight = messageInputBar.frame.height
        tableView.contentInset.bottom = inputBarHeight
        tableView.scrollIndicatorInsets.bottom = inputBarHeight
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
              let curve = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else { return }
        let keyboardHeight = keyboardFrame.height - view.safeAreaInsets.bottom
        inputBarBottomConstraint?.constant = -keyboardHeight
        UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: curve << 16), animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
              let curve = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else { return }
        inputBarBottomConstraint?.constant = 0
        UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: curve << 16), animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
    }

    // MARK: - TableView DataSource
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatRows.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = chatRows[indexPath.row]
        switch row {
        case .message(let message):
            let cell = tableView.dequeueReusableCell(withIdentifier: "MessageBubbleCell", for: indexPath) as! MessageBubbleCell
            cell.configure(with: message)
            return cell
        case .timestamp(let timestamp):
            let cell = tableView.dequeueReusableCell(withIdentifier: "TimestampLabelCell", for: indexPath) as! TimestampLabelCell
            cell.configure(with: timestamp)
            return cell
        }
    }

    // MARK: - Clean Swift Display Logic
    func displayChatRows(_ chatRows: [ChatRow], isOtherUserTyping: Bool) {
        self.chatRows = chatRows
        self.isOtherUserTyping = isOtherUserTyping
        tableView.reloadData()
        scrollToBottom()
    }

    func displayOtherUserTyping(_ typing: Bool) {
        self.isOtherUserTyping = typing
        tableView.reloadData()
        if typing { scrollToBottom() }
    }

    private func scrollToBottom() {
        let lastRow = tableView.numberOfRows(inSection: 0) - 1
        guard lastRow >= 0 else { return }
        let indexPath = IndexPath(row: lastRow, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }

    // Grouping logic moved to presenter
}

// MARK: - ChatRow Enum
enum ChatRow {
    case message(ChatMessage)
    case timestamp(String)
}

// MARK: - TimestampLabelCell
class TimestampLabelCell: UITableViewCell {
    private let label = UILabel()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = .secondaryLabel
        contentView.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4)
        ])
        selectionStyle = .none
        backgroundColor = .clear
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    func configure(with timestamp: String) {
        label.text = timestamp
    }
}

// MARK: - MessageInputBarDelegate
extension ChatViewController: MessageInputBarDelegate {
    func didSendMessage(_ text: String) {
        interactor?.sendMessage(text)
    }
    func didChangeTyping(_ isTyping: Bool) {
        interactor?.setOtherUserTyping(isTyping)
    }
}



