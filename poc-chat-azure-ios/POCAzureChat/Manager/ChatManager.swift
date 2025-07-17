//
//  ChatManager.swift
//  POCAzureChat
//
//  Created by POC on 16/7/2568 BE.
//

import Foundation
import AzureCommunicationChat
import AzureCommunicationCommon

class ChatManager {

    private var chatClient: ChatClient?
    private var chatThreadClient: ChatThreadClient?

    init(endpoint: String, userAccessToken: String, threadId: String) {
        setupChatClient(endpoint: endpoint, userAccessToken: userAccessToken, threadId: threadId)
    }

    private func setupChatClient(endpoint: String, userAccessToken: String, threadId: String) {
        do {
            // สร้าง Credential
            let credential = try CommunicationTokenCredential(token: userAccessToken)

            // สร้าง Chat Client
            let options = AzureCommunicationChatClientOptions()
            chatClient = try ChatClient(endpoint: endpoint, credential: credential, withOptions: options)

            // สร้าง ChatThreadClient จาก threadId
            chatThreadClient = try chatClient?.createClient(forThread: threadId)

            print("✅ Chat client initialized successfully.")

        } catch {
            print("❌ Error initializing chat client: \(error)")
        }
    }

    func sendMessage(text: String, displayName: String = "iOSUser") {
        guard let chatThreadClient = chatThreadClient else {
            print("❗️ChatThreadClient not initialized.")
            return
        }

        let messageRequest = SendChatMessageRequest(
            content: text,
            senderDisplayName: displayName,
            type: .text
        )

        chatThreadClient.send(message: messageRequest) { result, code in
            switch result {
            case .success(let response):
                print("✅ Message sent with ID: \(response.id ?? "nil")")
            case .failure(let error):
                print("❌ Failed to send message: \(error)")
            }
        }
      
    }
}
