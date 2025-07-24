import Foundation
import AzureCommunicationChat
import AzureCommunicationCommon
import AzureCore

protocol ChatServiceProtocol {
    func createClient(completion: @escaping (Result<ChatClient, Error>) -> Void)
//    func createThread(completion: @escaping (Result<String?, Error>) -> Void)
    func getThreadClient(completion: @escaping (Result<ChatThreadClient?, Error>) -> Void)
    func getHistory(completion: @escaping (Result<[ChatMessage], String>) -> Void)
    func receiveMessages(completion: @escaping (Result<Void, Error>) -> Void)
    func sendMessage(_ text: String, completion: @escaping (Result<ChatMessage, Error>) -> Void)
    // func getHistoryPaginated(pageSize: Int = 50, completion: @escaping (Result<[ChatMessage], String>) -> Void)
    var delegate: ChatServiceDelegare? { get set }
}

protocol ChatServiceDelegare: AnyObject {
    func receiveAZMessages(meaaage: ChatMessage)
}

class ChatService: ChatServiceProtocol {
    private var chatClient: ChatClient?
    private var threadClient: ChatThreadClient?
    internal var delegate: ChatServiceDelegare?
    
    
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
    
    // Aleady created from BE then they will send chat thread id vai API
//    func createThread(completion: @escaping (Result<String?, Error>) -> Void) {
//        guard let chatClient = self.chatClient else {
//            completion(.failure(NSError(domain: "ChatService", code: -1, userInfo: [NSLocalizedDescriptionKey: "ChatClient not initialized"])))
//            return
//        }
//        let request = CreateChatThreadRequest(
//            topic: "Quickstart",
//            participants: [
//                ChatParticipant(
//                    id: CommunicationUserIdentifier(self.userId),
//                    displayName: self.displayName
//                )
//            ]
//        )
//        chatClient.create(thread: request) { result, _ in
//            switch result {
//            case let .success(result):
//                let threadId = result.chatThread?.id
//                print("create thread success with: \(result.chatThread?.topic ?? "NA") threadId: \(threadId ?? "NA")")
//                completion(.success(threadId))
//            case .failure(let error):
//                completion(.failure(error))
//            }
//        }
//    }
    
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
                            text: messageText,
                            isIncoming: self.isMessageOwner(sender: msg.sender),
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
                            text: event.message,
                            isIncoming: self.isMessageOwner(sender: event.sender),
                            createdOn: event.createdOn ?? Iso8601Date.now
                        )
                        self.delegate?.receiveAZMessages(meaaage: chatMessage)
                    default:
                        return
                    }
                })
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
                            text: messageText,
                            isIncoming: self.isMessageOwner(sender: msg.sender),
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
        return userId != senderId
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
