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
    func cleanup()
    // func getHistoryPaginated(pageSize: Int = 50, completion: @escaping (Result<[ChatMessage], String>) -> Void)
    var delegate: ChatServiceDelegare? { get set }
}

protocol ChatServiceDelegare: AnyObject {
    func receiveAZMessages(meaaage: ChatMessage)
    func showTypingIndicator(sender: String)
}

class ChatService: ChatServiceProtocol {
    deinit {
        print("ChatService deallocated")
        // Force synchronous cleanup in deinit
        cleanup()
    }
    private var typingHandlerRegistered = false
    private var chatClient: ChatClient?
    private var threadClient: ChatThreadClient?
    internal var delegate: ChatServiceDelegare?
    private var isCleaningUp = false
    
    
    // Replace with your ACS endpoint and user access token
    private let endpoint = "" // e.g. "https://<RESOURCE_NAME>.communication.azure.com"
    private let userAccessToken = ""
    private let displayName = ""
    private var userId = ""
    private let threadId = ""
    
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
    
    /// Synchronous cleanup for deinit - ensures WebSocket is closed before deallocation
    internal func cleanup() {
        guard !isCleaningUp else { return }
        
        print("Performing synchronous cleanup in deinit...")
        
        // Unregister event handlers
        chatClient?.unregister(event: .chatMessageReceived)
        chatClient?.unregister(event: .typingIndicatorReceived)
        
        // Stop WebSocket synchronously (blocks until WebSocket is closed)
        if chatClient != nil {
            chatClient?.stopRealTimeNotifications()
            print("✅ WebSocket stopped in deinit")
        }
        
        // Clear all references
        threadClient = nil
        chatClient = nil
        delegate = nil
        typingHandlerRegistered = false
        
        print("✅ Synchronous cleanup completed")
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
