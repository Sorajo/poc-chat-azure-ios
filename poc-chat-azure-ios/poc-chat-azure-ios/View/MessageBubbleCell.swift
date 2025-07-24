import UIKit
import AzureCore

struct ChatMessage: Codable {
    let text: String
    let isIncoming: Bool
    let createdOn: Iso8601Date
}

class MessageBubbleCell: UITableViewCell {
    private let bubbleView = UIView()
    private let messageLabel = UILabel()
    private var leadingConstraint: NSLayoutConstraint!
    private var trailingConstraint: NSLayoutConstraint!
    private var maxWidthConstraint: NSLayoutConstraint!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.addSubview(bubbleView)
        bubbleView.layer.cornerRadius = 16
        bubbleView.layer.masksToBounds = true
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.addSubview(messageLabel)

        // Constraints for incoming (left) and outgoing (right) bubbles
        leadingConstraint = bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
        trailingConstraint = bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12)
        maxWidthConstraint = bubbleView.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.7)

        NSLayoutConstraint.activate([
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            leadingConstraint,
            trailingConstraint,
            maxWidthConstraint,
            messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 8),
            messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -8),
            messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(with message: ChatMessage) {
        messageLabel.text = message.text
        if message.isIncoming {
            bubbleView.backgroundColor = UIColor(white: 0.9, alpha: 1)
            messageLabel.textColor = .black
            leadingConstraint.constant = 16
            trailingConstraint.constant = -80 // Give outgoing bubbles more space on left
            leadingConstraint.isActive = true
            trailingConstraint.isActive = false
        } else {
            bubbleView.backgroundColor = UIColor.systemBlue
            messageLabel.textColor = .white
            leadingConstraint.constant = 80 // Give incoming bubbles more space on right
            trailingConstraint.constant = -12
            leadingConstraint.isActive = false
            trailingConstraint.isActive = true
        }
        maxWidthConstraint.isActive = true
    }
}
