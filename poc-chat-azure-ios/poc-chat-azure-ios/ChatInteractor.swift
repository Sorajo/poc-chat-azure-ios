
import Foundation
import AzureCommunicationChat
import AzureCommunicationCommon
import AzureCore

protocol ChatBusinessLogic: AnyObject {
    func startAZS()
    func sendMessage(_ text: String)
//    func receiveMessage(_ text: String)
    func setOtherUserTyping(_ typing: Bool)
}

final class ChatInteractor: ChatBusinessLogic {
    var presenter: ChatPresentationLogic?
    private var messages: [ChatMessage] = []
    private var isOtherUserTyping: Bool = false
    private var chatService: ChatServiceProtocol

    // Dependency injection via initializer
    init(chatService: ChatServiceProtocol) {
        self.chatService = chatService
        self.chatService.delegate = self
    }

    func sendMessage(_ text: String) {
        chatService.sendMessage(text) { result in
            switch result {
            case .success(let message):
                break
//                self.messages.append(message)
//                self.messages.sort { (msg1: ChatMessage, msg2: ChatMessage) in
//                    msg1.createdOn < msg2.createdOn
//                }
//                self.presenter?.presentMessages(self.messages, isOtherUserTyping: false)
            case .failure(let error):
                print(error.localizedDescription)
                break
            }
        }
    }
    func startAZS() {
        chatService.createClient { [weak self] clientResult in
            switch clientResult {
            case .success:
                self?.chatService.createThread { threadResult in
                    switch threadResult {
                    case .success:
                        self?.chatService.getThreadClient { threadClientResult in
                            switch threadClientResult {
                            case .success:
                                self?.chatService.getHistory { historyResult in
                                    switch historyResult {
                                    case .success(let messages):
                                        self?.messages = messages.sorted { (msg1: ChatMessage, msg2: ChatMessage) in
                                            msg1.createdOn < msg2.createdOn
                                        }
                                        self?.presenter?.presentMessages(self?.messages ?? [], isOtherUserTyping: false)
                                        self?.chatService.receiveMessages { _ in }
                                    case .failure(let error):
                                        print("Get history error: \(error)")
                                    }
                                }
                            case .failure(let error):
                                print("Get thread client error: \(error.localizedDescription)")
                            }
                        }
                    case .failure(let error):
                        print("Create thread error: \(error.localizedDescription)")
                    }
                }
            case .failure(let error):
                print("Create client error: \(error.localizedDescription)")
            }
        }
    }

     func setOtherUserTyping(_ typing: Bool) {
        isOtherUserTyping = typing
        presenter?.presentOtherUserTyping(typing)
    }
}

extension ChatInteractor: ChatServiceDelegare {
    func receiveAZMessages(meaaage: ChatMessage) {
        DispatchQueue.main.async {
            self.messages.append(meaaage)
            self.presenter?.presentMessages(self.messages, isOtherUserTyping: false)
        }
    }
}
