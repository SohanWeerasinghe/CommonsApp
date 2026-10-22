//
//  ChatDetailView.swift
//  CommonsApp
//
//  Created by Sohan Weerasinghe on 21/9/2026.
//
import SwiftUI
import FirebaseAuth
struct ChatDetailView: View {
    @EnvironmentObject var store: AppStore
    let thread: ChatThread
    @State private var messageText = ""
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.wallBackgroundTop, Theme.wallBackgroundBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            VStack(spacing: 0) {
                // Chat header
                ChatDetailHeader(
                    name: thread.neighborName,
                    unit: thread.neighborUnit,
                    residentUID: thread.neighborUID
                )
                // Context card
                if let note = thread.contextNote {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.appPurple)
                        Text(note)
                            .font(Theme.ui(12, weight: .medium))
                            .foregroundStyle(Theme.appNavy)
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .frame(minHeight: 48)
                    .background(Theme.appPurpleSoft)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
                // Messages
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        VStack(spacing: 14) {
                            let currentThread = getCurrentThread()
                            if currentThread.messages.isEmpty {
                                VStack(spacing: 10) {
                                    Image(systemName: "bubble.left.and.bubble.right")
                                        .font(.system(size: 34))
                                        .foregroundStyle(Theme.appPurple.opacity(0.5))
                                    Text("No messages yet")
                                        .font(Theme.display(17, weight: .bold))
                                        .foregroundStyle(Theme.appNavy)
                                    Text("Say hello to \(thread.neighborName).")
                                        .font(Theme.ui(13))
                                        .foregroundStyle(Theme.appMuted)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, 60)
                            } else {
                                ForEach(currentThread.messages) { message in
                                    MessageBubble(
                                        message: message,
                                        neighborUnit: thread.neighborUnit,
                                        neighborName: thread.neighborName,
                                        neighborUID: thread.neighborUID
                                    )
                                    .id(message.id)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 18)
                        .padding(.bottom, 14)
                    }
                    .scrollIndicators(.hidden)
                    .onChange(of: getCurrentThread().messages.count) {
                        if let lastMessage = getCurrentThread().messages.last {
                            withAnimation {
                                scrollProxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                // Message composer
                MessageComposer(
                    messageText: $messageText,
                    neighborName: thread.neighborName
                ) {
                    sendMessage()
                }
            }
        }
        //Turn on/off chat listner from firebase
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            if let chatId = thread.firestoreId {
                store.setActiveChat(chatId)
                store.startChatMessagesListener(chatId: chatId)
            }
        }
        .onDisappear {
            store.setActiveChat(nil)
        }
    }
    func getCurrentThread() -> ChatThread {
        for currentThread in store.chatThreads {
            if currentThread.id == thread.id {
                return currentThread
            }
        }
        return thread
    }
   func sendMessage() {
        let trimmedMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedMessage.isEmpty {
            return
        }
        store.send(text: trimmedMessage, in: thread)
        messageText = ""
    }
}
private struct ChatDetailHeader: View {
    @Environment(\.dismiss) private var dismiss
    let name: String
    let unit: String
    let residentUID: String?
    var body: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Theme.appNavy)
                    .frame(width: 42, height: 42)
                    .background(Theme.card)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            ChatResidentAvatar(name: name, unit: unit, size: 42, residentUID: residentUID)
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(Theme.ui(15, weight: .bold))
                    .foregroundStyle(Theme.appNavy)
                Text("Unit \(unit)")
                    .font(Theme.ui(11))
                    .foregroundStyle(Theme.appMuted)
            }
            Spacer()
            Button {
                // Calling functionality can be connected later.
            } label: {
                Image(systemName: "phone")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.appNavy)
                    .frame(width: 38, height: 38)
                    .background(Theme.card)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            Button {
                // Conversation options can be connected later.
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Theme.appNavy)
                    .frame(width: 38, height: 38)
                    .background(Theme.card)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 10)
    }
}
private struct MessageBubble: View {
    @EnvironmentObject private var store: AppStore
    let message: ChatMessage
    let neighborUnit: String
    let neighborName: String
    let neighborUID: String?
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isMine {
                Spacer(minLength: 55)
            } else {
                ChatResidentAvatar(name: neighborName, unit: neighborUnit, size: 30, residentUID: neighborUID)
            }
            VStack(
                alignment: message.isMine ? .trailing : .leading,
                spacing: 5
            ) {
                Text(message.text)
                    .font(Theme.ui(14))
                    .foregroundStyle(message.isMine ? .white : Theme.appNavy)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(
                        message.isMine ? Theme.appPurple : Theme.card
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay {
                        if !message.isMine {
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Theme.appBorder, lineWidth: 1)
                        }
                    }
                Text(message.timestamp.chatRelativeDescription)
                    .font(Theme.ui(9))
                    .foregroundStyle(Theme.appMuted)
            }
            .frame(maxWidth: 260, alignment: message.isMine ? .trailing : .leading)
            if message.isMine {
                ChatResidentAvatar(name: store.currentResident.name, unit: store.currentResident.unit, size: 30, residentUID: Auth.auth().currentUser?.uid)
            } else {
                Spacer(minLength: 55)
            }
        }
    }
}
private struct MessageComposer: View {
    @Binding var messageText: String
    let neighborName: String
    let sendMessage: () -> Void
    var body: some View {
        HStack(spacing: 8) {
            Button {
                // Photo picker can be connected later.
            } label: {
                Image(systemName: "camera")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Theme.appMuted)
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.plain)
            TextField("Message \(neighborName)...", text: $messageText)
                .font(Theme.ui(13))
                .foregroundStyle(Theme.appNavy)
                .submitLabel(.send)
                .onSubmit {
                    sendMessage()
                }
            Button {
                // Voice recording can be connected later.
            } label: {
                Image(systemName: "mic")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Theme.appMuted)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(
                        messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? Theme.appMuted
                        : Theme.appPurple
                    )
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(
                messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            )
        }
        .padding(.horizontal, 10)
        .frame(height: 54)
        .background(Theme.card)
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .stroke(Theme.appBorder, lineWidth: 1)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(Theme.wallBackgroundBottom)
    }
}
#Preview {
    NavigationStack {
        ChatListView()
            .environmentObject(AppStore())
    }
}
