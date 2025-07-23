import Foundation

protocol ChatDisplayLogic: AnyObject {
    func displayChatRows(_ messages: [ChatRow], isOtherUserTyping: Bool)
    func displayOtherUserTyping(_ typing: Bool)
}

// MARK: - ChatRow Enum
enum ChatRow {
    case message(ChatMessage)
    case timestamp(String)
}
