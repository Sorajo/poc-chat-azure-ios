
import Foundation
import AzureCommunicationChat
import AzureCommunicationCommon
import AzureCore

protocol ChatBusinessLogic: AnyObject {
    func startAZS()
    func sendMessage(_ text: String)
    func cleanup()
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
    
    deinit {
        print("ChatInteractor deallocated")
    }
    
    func sendMessage(_ text: String) {
        chatService.sendMessage(text) { result in
            switch result {
            case .success(let message):
                // do nothing
                break
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
                self?.chatService.getThreadClient { threadClientResult in
                    switch threadClientResult {
                    case .success:
                        self?.chatService.getHistory { historyResult in
                            switch historyResult {
                            case .success(let messages):
                                self?.messages = messages.sorted { (msg1: ChatMessage, msg2: ChatMessage) in
                                    msg1.createdOn < msg2.createdOn
                                }
                                self?.presenter?.presentMessages(self?.messages ?? [])
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
                print("Create client error: \(error.localizedDescription)")
            }
        }
    }
    
    func cleanup() {
        print("Cleaning up ChatInteractor...")
        chatService.cleanup()
        messages.removeAll()
        chatService.delegate = nil
    }
}

extension ChatInteractor: ChatServiceDelegare {
    func receiveAZMessages(meaaage: ChatMessage) {
        DispatchQueue.main.async {
            self.messages.append(meaaage)
            self.presenter?.presentOtherUserTyping(.none)
            self.presenter?.presentMessages(self.messages)
        }
    }
    
    func showTypingIndicator(sender: String) {
        DispatchQueue.main.async {
            self.presenter?.presentOtherUserTyping(.typing(sender))
        }
    }
}
