import Foundation

enum TypingType {
    case none
    case typing(String)
}
protocol ChatPresentationLogic: AnyObject {
    func presentMessages(_ messages: [ChatMessage])
    func presentOtherUserTyping(_ typing: TypingType)
}

final class ChatPresenter: ChatPresentationLogic {
    weak var viewController: ChatDisplayLogic?

    func presentMessages(_ messages: [ChatMessage]) {
        let chatRows = makeChatRows(from: messages)
        viewController?.displayChatRows(chatRows)
    }

    func presentOtherUserTyping(_ typing: TypingType) {
        viewController?.displayOtherUserTyping(typing)
        // viewController?.displayOtherUserTyping(typing)
    }

    // Converts [ChatMessage] to [ChatRow] with formatted timestamp strings
    private func makeChatRows(from messages: [ChatMessage]) -> [ChatRow] {
        guard !messages.isEmpty else { return [] }
        var rows: [ChatRow] = []
        let calendar = Calendar.current
        var lastDate: Date? = nil
        for message in messages {
            let messageDate = message.createdOn.value
            if let last = lastDate {
                if !calendar.isDate(messageDate, inSameDayAs: last) || messageDate.timeIntervalSince(last) > 300 {
                    rows.append(.timestamp(formatDateLabel(messageDate)))
                }
            } else {
                rows.append(.timestamp(formatDateLabel(messageDate)))
            }
            rows.append(.message(message))
            lastDate = messageDate
        }
        return rows
    }

    private func formatDateLabel(_ date: Date) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        if calendar.isDateInToday(date) {
            formatter.dateFormat = "'Today' h:mm a"
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            formatter.dateFormat = "'Yesterday' h:mm a"
            return formatter.string(from: date)
        } else {
            formatter.dateFormat = "MMM d, yyyy h:mm a"
            return formatter.string(from: date)
        }
    }
}
