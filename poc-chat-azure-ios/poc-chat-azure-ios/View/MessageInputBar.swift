import UIKit

protocol MessageInputBarDelegate: AnyObject {
    func didSendMessage(_ text: String)
    func didChangeTyping(_ isTyping: Bool)
}

class MessageInputBar: UIView, UITextFieldDelegate {
    weak var delegate: MessageInputBarDelegate?
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
    private let textField = UITextField()
    private let sendButton = UIButton(type: .system)
    private var isTyping = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        blurView.layer.cornerRadius = 22
        blurView.clipsToBounds = true
        blurView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(blurView)
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
        ])
        textField.font = UIFont.systemFont(ofSize: 16)
        textField.backgroundColor = .clear
        textField.borderStyle = .none
        textField.layer.cornerRadius = 14
        textField.delegate = self
        textField.translatesAutoresizingMaskIntoConstraints = false
        sendButton.setTitle("Send", for: .normal)
        sendButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(textField)
        addSubview(sendButton)
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 16),
            textField.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            textField.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -10),
            sendButton.leadingAnchor.constraint(equalTo: textField.trailingAnchor, constant: 10),
            sendButton.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -16),
            sendButton.bottomAnchor.constraint(equalTo: textField.bottomAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 60),
            textField.heightAnchor.constraint(equalToConstant: 38)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func sendTapped() {
        guard let text = textField.text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        delegate?.didSendMessage(text)
        textField.text = ""
        setTyping(false)
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        let newText = (currentText as NSString).replacingCharacters(in: range, with: string)
        let currentlyTyping = !newText.isEmpty
        if currentlyTyping != isTyping {
            setTyping(currentlyTyping)
        }
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendTapped()
        return false
    }

    private func setTyping(_ typing: Bool) {
        isTyping = typing
        delegate?.didChangeTyping(typing)
    }
}

