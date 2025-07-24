import Foundation
import AzureCommunicationChat
import AzureCommunicationCommon
import AzureCore

protocol ChatServiceProtocol {
    func createClient(completion: @escaping (Result<ChatClient, Error>) -> Void)
    func getThreadClient(completion: @escaping (Result<ChatThreadClient?, Error>) -> Void)
    func getHistory(completion: @escaping (Result<[ChatMessage], String>) -> Void)
    func receiveMessages(completion: @escaping (Result<Void, Error>) -> Void)
    func sendMessage(_ text: String, completion: @escaping (Result<ChatMessage, Error>) -> Void)
    // func getHistoryPaginated(pageSize: Int = 50, completion: @escaping (Result<[ChatMessage], String>) -> Void)
    var delegate: ChatServiceDelegare? { get set }
}

protocol ChatServiceDelegare: AnyObject {
    func receiveAZMessages(meaaage: ChatMessage)
    func showTypingIndicator(sender: String)
}

class ChatService: ChatServiceProtocol {
    deinit {
        if let chatClient = chatClient {
            chatClient.stopRealTimeNotifications()
        }
    }
    private var typingHandlerRegistered = false
    private var chatClient: ChatClient?
    private var threadClient: ChatThreadClient?
    internal var delegate: ChatServiceDelegare?
    
    
    // Replace with your ACS endpoint and user access token
    private let endpoint = "https://acs-chat-dev.asiapacific.communication.azure.com" // e.g. "https://<RESOURCE_NAME>.communication.azure.com"
    private let userAccessToken = "eyJhbGciOiJSUzI1NiIsImtpZCI6IkRCQTFENTczNEY1MzM4QkRENjRGNjA4NjE2QTQ5NzFCOTEwNjU5QjAiLCJ4NXQiOiIyNkhWYzA5VE9MM1dUMkNHRnFTWEc1RUdXYkEiLCJ0eXAiOiJKV1QifQ.eyJza3lwZWlkIjoiYWNzOmI1YzcxNzc2LWNmYTgtNGY3My04NzNkLTllNDJiZGMzZGM1MV8wMDAwMDAyOC1iYjViLTIxZjQtNzNjYi1jODNhMGQwMDBhNjkiLCJzY3AiOjE3OTIsImNzaSI6IjE3NTMzMzc4MTYiLCJleHAiOjE3NTM0MjQyMTYsInJnbiI6ImFwYWMiLCJhY3NTY29wZSI6ImNoYXQiLCJyZXNvdXJjZUlkIjoiYjVjNzE3NzYtY2ZhOC00ZjczLTg3M2QtOWU0MmJkYzNkYzUxIiwicmVzb3VyY2VMb2NhdGlvbiI6ImFzaWFwYWNpZmljIiwiaWF0IjoxNzUzMzM3ODE2fQ.D3MWAr_e9RRbK_m_JbFXsj0mcS81ixTBhauYofeq6nrM33szFzcWt8qNfu07U6aivFkeIYfs2UIsrOhiT8kd5b-ofeuYNz6CxCTHoWsWTNZyhls-cRRoB7bIggwD-WdrAVJ_5HRbwreZZdWTW3i0Q-MXUFzNLgWHt_c4PEXU3hqQF1-GHTp2VC2cGlOYB4L_AdNnHNfL5868wCiwQ4_bXYLA7hfFXo9IrGZLA9N7ti8Ppq__ukGmscLoihWZZUxjnJOrio5ptQHVL6LHhxrWGWxBBZRMzLW-XiiNQAXT-eEOQYWSV4qhwC31w9bsIlxFIip0n42Ncv-Lq9F4cy30UQ"
    private let displayName = "Mai iOS"
    private var userId = ""
    private let threadId = "19:acsV1_G68PN0dAUb_Lr7xlXArGwvPx-SGMii2wDz4H0iY5wfo1@thread.v2"
    
    func createClient(completion: @escaping (Result<ChatClient, Error>) -> Void) {
        DispatchQueue.global(qos: .background).async {
            do {
                let credential = try CommunicationTokenCredential(token: self.userAccessToken)
                if let rawId = self.extractUserId(from: self.userAccessToken) {
                    self.userId = self.normalizeCommunicationUserId(rawId)
                } else {
                    self.userId = ""
                }
                let options = AzureCommunicationChatClientOptions()
                let client = try ChatClient(endpoint: self.endpoint, credential: credential, withOptions: options)
                self.chatClient = client
                
                completion(.success(client))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func getThreadClient(completion: @escaping (Result<ChatThreadClient?, Error>) -> Void) {
        guard let chatClient = self.chatClient else {
            completion(.failure(NSError(domain: "ChatService", code: -1, userInfo: [NSLocalizedDescriptionKey: "ChatClient not initialized"])))
            return
        }
        do {
            let threadClient = try chatClient.createClient(forThread: self.threadId)
            self.threadClient = threadClient
            completion(.success(threadClient))
        } catch {
            completion(.failure(error))
        }
    }
    
    func getHistory(completion: @escaping (Result<[ChatMessage], String>) -> Void) {
        guard let chatClient = self.chatClient else {
            completion(.failure("ChatClient not initialized"))
            return
        }
        do {
            let threadClient = try chatClient.createClient(forThread: self.threadId)
            let options = ListChatMessagesOptions(maxPageSize: 100)
            threadClient.listMessages(withOptions: options) { result, _ in
                switch result {
                case .success(let pagedMessages):
                    
                    let chatHistory: [ChatMessage] = pagedMessages.items?.compactMap { msg in
                        guard let messageText = msg.content?.message else { return nil }
                        return ChatMessage(
                            id: msg.id,
                            text: messageText,
                            isIncoming: !self.isMessageOwner(sender: msg.sender),
                            createdOn: msg.createdOn
                        )
                    } ?? []
                    completion(.success(chatHistory))
                case .failure(let error):
                    completion(.failure(error.message))
                }
            }
        } catch {
            completion(.failure(error.localizedDescription))
        }
    }
    
    func receiveMessages(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let chatClient = self.chatClient else {
            completion(.failure(NSError(domain: "ChatService", code: -1, userInfo: [NSLocalizedDescriptionKey: "ChatClient not initialized"])))
            return
        }
        chatClient.startRealTimeNotifications { result in
            switch result {
            case .success:
                print("Real-time notifications started.")
                completion(.success(()))
                chatClient.register(event: .chatMessageReceived, handler: { response in
                    switch response {
                    case let .chatMessageReceivedEvent(event):
                        let chatMessage = ChatMessage(
                            id: event.id,
                            text: event.message,
                            isIncoming: !self.isMessageOwner(sender: event.sender),
                            createdOn: event.createdOn ?? Iso8601Date.now
                        )
                        self.delegate?.receiveAZMessages(meaaage: chatMessage)
                    default:
                        return
                    }
                })
                // Register typing indicator event only once
                if !self.typingHandlerRegistered {
                    chatClient.register(event: .typingIndicatorReceived, handler: { response in
                        switch response {
                        case .typingIndicatorReceived(let event):
                            if event.threadId == self.threadId , event.sender?.rawId != self.userId {
                                self.delegate?.showTypingIndicator(sender: event.senderDisplayName ?? "Someone")
                            }
                        default: break
                        }
                    })
                    self.typingHandlerRegistered = true
                }
            case .failure(let error):
                print("Failed to start real-time notifications.")
                completion(.failure(error))
            }
        }
    }
    
    func sendMessage(_ text: String, completion: @escaping (Result<ChatMessage, Error>) -> Void) {
        guard let threadClient = self.threadClient else {
            completion(.failure(NSError(domain: "ChatService", code: -1, userInfo: [NSLocalizedDescriptionKey: "threadClient not initialized"])))
            return
        }
        let message = SendChatMessageRequest(
                                content: text,
                                senderDisplayName: displayName,
                                type: .text)
        threadClient.send(message: message) { result, error in
            switch result {
            case let .success(result):
                print("Message sent, message id: \(result.id)")
                completion(
                    .success(
                        ChatMessage(
                            id: UUID().uuidString,
                            text: text,
                            isIncoming: false,
                            createdOn: Iso8601Date.now
                        )
                    )
                )
            case .failure:
                print("Failed to send message")
                completion(.failure(error as! Error))
            }
        }
    }

    func getHistoryPaginated(pageSize: Int32 = 50, completion: @escaping (Result<[ChatMessage], String>) -> Void) {
    guard let chatClient = self.chatClient else {
        completion(.failure("ChatClient not initialized"))
        return
    }
    do {
        let threadClient = try chatClient.createClient(forThread: self.threadId)
        let options = ListChatMessagesOptions(maxPageSize: pageSize)
        threadClient.listMessages(withOptions: options) { result, _ in
            switch result {
            case .success(let pagedMessages):
                var allMessages: [ChatMessage] = []
                func fetchNextPage(_ page: PagedCollection<AzureCommunicationChat.ChatMessage>?) {
                    guard let page = page else {
                        completion(.success(allMessages))
                        return
                    }
                    let messages: [ChatMessage] = page.items?.compactMap { msg in
                        guard let messageText = msg.content?.message else { return nil }
                        return ChatMessage(
                            id: msg.id,
                            text: messageText,
                            isIncoming: !self.isMessageOwner(sender: msg.sender),
                            createdOn: msg.createdOn
                        )
                    } ?? []
                    allMessages.append(contentsOf: messages)
                    page.nextPage { nextResult in
                        switch nextResult {
                        case .success(let nextPage):
                           // fetchNextPage(nextPage)
                            break
                        case .failure:
                            completion(.success(allMessages))
                        }
                    }
                }
                fetchNextPage(pagedMessages)
            case .failure(let error):
                completion(.failure(error.message))
            }
        }
    } catch {
        completion(.failure(error.localizedDescription))
    }
    }
}

extension Iso8601Date {
    static let now: Iso8601Date = .init()
}
    
extension ChatService {
    /// Normalize ACS user ID from `skypeid` or raw format to SDK format
    func normalizeCommunicationUserId(_ raw: String) -> String {
        if raw.hasPrefix("8:") {
            return raw
        }
        if raw.hasPrefix("acs:") {
            return "8:" + raw
        }
        return raw
    }

    func isMessageOwner(sender: CommunicationIdentifier?) -> Bool {
        guard let senderId = sender?.rawId else {
            return false
        }
        return userId == senderId
    }
    
    func extractUserId(from token: String) -> String? {
        let segments = token.split(separator: ".")
        guard segments.count > 1 else { return nil }
        let payload = segments[1]
        var payloadData = payload
        // Pad base64 if needed
        while payloadData.count % 4 != 0 { payloadData.append("=") }
        guard let data = Data(base64Encoded: String(payloadData)) else { return nil }
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            // get userId from "skypeid"
            return json["skypeid"] as? String
        }
        return nil
    }
}
