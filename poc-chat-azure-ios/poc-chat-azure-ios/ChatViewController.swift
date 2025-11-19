
import UIKit

class ChatViewController: UITableViewController, ChatDisplayLogic {
    // ChatRow: either a message or a timestamp label (now contains formatted string for timestamp)
    private var chatRows: [ChatRow] = []
    private var isOtherUserTyping: TypingType = .none
    private let messageInputBar = MessageInputBar()
    private var inputBarBottomConstraint: NSLayoutConstraint?

    var interactor: ChatBusinessLogic?
    
    deinit {
        // Remove observers
        NotificationCenter.default.removeObserver(self)
        print("ChatViewController deallocated")
    }

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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Check if we're being popped from navigation stack
        if isMovingFromParent {
            interactor?.cleanup()
        }
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

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
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
    func displayChatRows(_ chatRows: [ChatRow]) {
        self.chatRows = chatRows
        tableView.reloadData()
        scrollToBottom()
    }
    
    func displayOtherUserTyping(_ typing: TypingType) {
        self.isOtherUserTyping = typing
        switch typing {
        case .none:
            // Remove any "typing..." indicator from chatRows
            if let last = chatRows.last, case .timestamp(let text) = last, text.contains("is typing...") {
                chatRows.removeLast()
                tableView.reloadData()
            }
        case .typing(let sender):
            // Add a "typing..." indicator to the table view
            let typingRow = ChatRow.timestamp("\(sender) is typing...")
            if chatRows.last != typingRow {
                chatRows.append(typingRow)
                tableView.reloadData()
                scrollToBottom()
            }
        }
    }

    private func scrollToBottom() {
        let lastRow = tableView.numberOfRows(inSection: 0) - 1
        guard lastRow >= 0 else { return }
        let indexPath = IndexPath(row: lastRow, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }
}

// MARK: - MessageInputBarDelegate
extension ChatViewController: MessageInputBarDelegate {
    func didSendMessage(_ text: String) {
        interactor?.sendMessage(text)
    }
    func didChangeTyping(_ isTyping: Bool) {
//        interactor?.setOtherUserTyping(isTyping)
    }
}



