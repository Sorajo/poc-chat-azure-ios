import Foundation

protocol ChatDisplayLogic: AnyObject {
    func displayChatRows(_ messages: [ChatRow])
    func displayOtherUserTyping(_ typing: TypingType)
}

// MARK: - ChatRow Enum
enum ChatRow: Equatable {
    case message(ChatMessage)
    case timestamp(String)

    static func == (lhs: ChatRow, rhs: ChatRow) -> Bool {
        switch (lhs, rhs) {
        case (.message(let lMsg), .message(let rMsg)):
            return lMsg.id == rMsg.id
        case (.timestamp(let lStr), .timestamp(let rStr)):
            return lStr == rStr
        default:
            return false
        }
    }
}
