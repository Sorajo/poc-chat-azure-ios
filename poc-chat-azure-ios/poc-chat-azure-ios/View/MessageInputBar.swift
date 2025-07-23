import UIKit

protocol MessageInputBarDelegate: AnyObject {
    func didSendMessage(_ text: String)
    func didChangeTyping(_ isTyping: Bool)
}

class MessageInputBar: UIView, UITextFieldDelegate {
    weak var delegate: MessageInputBarDelegate?
    private let textField = UITextField()
    private let sendButton = UIButton(type: .system)
    private var isTyping = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .secondarySystemBackground
        textField.font = UIFont.systemFont(ofSize: 16)
        textField.layer.cornerRadius = 8
        textField.borderStyle = .roundedRect
        textField.placeholder = "Type a message..."
        textField.delegate = self
        textField.translatesAutoresizingMaskIntoConstraints = false
        sendButton.setTitle("Send", for: .normal)
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(textField)
        addSubview(sendButton)
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 8),
            textField.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            textField.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -8),
            sendButton.leadingAnchor.constraint(equalTo: textField.trailingAnchor, constant: 8),
            sendButton.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -8),
            sendButton.bottomAnchor.constraint(equalTo: textField.bottomAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 60),
            textField.heightAnchor.constraint(equalToConstant: 36)
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
