import Foundation
import AzureCommunicationChat
import AzureCommunicationCommon
import AzureCore

protocol ChatServiceProtocol {
    func createClient(completion: @escaping (Result<ChatClient, Error>) -> Void)
    func createThread(completion: @escaping (Result<String?, Error>) -> Void)
    func getThreadClient(completion: @escaping (Result<ChatThreadClient?, Error>) -> Void)
    func getHistory(completion: @escaping (Result<[ChatMessage], String>) -> Void)
    func receiveMessages(completion: @escaping (Result<Void, Error>) -> Void)
    func sendMessage(_ text: String, completion: @escaping (Result<ChatMessage, Error>) -> Void)
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
    private let displayName = "iOS User"
    private let userId = ""
    private let threadId = ""
    
    // ...existing code...

    //            createClientTask,
    //            createThreadTask,
    //            getThreadClientTask,
    //            getHistoryTask,
    //            receiveMessagesTask
    //
    
    func createClient(completion: @escaping (Result<ChatClient, Error>) -> Void) {
        DispatchQueue.global(qos: .background).async {
            do {
                let credential = try CommunicationTokenCredential(token: self.userAccessToken)
                let options = AzureCommunicationChatClientOptions()
                let client = try ChatClient(endpoint: self.endpoint, credential: credential, withOptions: options)
                self.chatClient = client
                completion(.success(client))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func createThread(completion: @escaping (Result<String?, Error>) -> Void) {
        guard let chatClient = self.chatClient else {
            completion(.failure(NSError(domain: "ChatService", code: -1, userInfo: [NSLocalizedDescriptionKey: "ChatClient not initialized"])))
            return
        }
        let request = CreateChatThreadRequest(
            topic: "Quickstart",
            participants: [
                ChatParticipant(
                    id: CommunicationUserIdentifier(self.userId),
                    displayName: self.displayName
                )
            ]
        )
        chatClient.create(thread: request) { result, _ in
            switch result {
            case let .success(result):
                let threadId = result.chatThread?.id
                print("create thread success with: \(result.chatThread?.topic ?? "NA") threadId: \(threadId ?? "NA")")
                completion(.success(threadId))
            case .failure(let error):
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
                            text: messageText,
                            isIncoming: self.userId != msg.sender?.rawId,
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
                            isIncoming: self.userId != event.sender?.rawId,
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
}
extension Iso8601Date {
    static let now: Iso8601Date = .init()
}
    
