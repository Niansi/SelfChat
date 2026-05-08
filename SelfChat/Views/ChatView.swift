import SwiftUI
import SwiftData

struct ChatView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Message.createdAt, order: .forward) private var messages: [Message]

    @State private var showTodoList = false
    @State private var todoTarget: Message?
    @State private var showTodoSheet = false

    @State private var flyingMessage: FlyingMessageState?

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .bottom)
                                        .combined(with: .scale(scale: 0.88))
                                        .combined(with: .opacity),
                                    removal: .opacity
                                ))
                                .contextMenu {
                                    if !message.isTodo {
                                        Button {
                                            todoTarget = message
                                            showTodoSheet = true
                                        } label: {
                                            Label("转为待办", systemImage: "checkmark.circle")
                                        }
                                    }
                                    Button(role: .destructive) {
                                        deleteMessage(message)
                                    } label: {
                                        Label("删除", systemImage: "trash")
                                    }
                                }
                                .visualEffect { content, proxy in
                                    let frame = proxy.frame(in: .global)
                                    let screenCenter = UIScreen.main.bounds.height / 2
                                    let distance = abs(frame.midY - screenCenter)
                                    let maxDist = UIScreen.main.bounds.height / 2
                                    let progress = min(distance / maxDist, 1.0)
                                    let scaleY = 1 - progress * 0.025
                                    let scaleX = 1 + progress * 0.012
                                    return content.scaleEffect(x: scaleX, y: scaleY, anchor: .center)
                                }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    .padding(.bottom, 120)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: messages.count) { _, _ in
                    if let last = messages.last {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
                .onAppear {
                    if let last = messages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                InputBar { msgs in
                    if let first = msgs.first,
                       first.type == .text,
                       let text = first.text {
                        triggerFlyingAnimation(text: text)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                        for message in msgs {
                            modelContext.insert(message)
                        }
                    }
                }
                .background(.clear)
            }
            .overlay {
                if let flying = flyingMessage {
                    FlyingMessageView(state: flying)
                }
            }
            .navigationTitle("文件传输助手")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .bottomBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showTodoList = true
                    } label: {
                        Image(systemName: "checklist")
                    }
                }
            }
            .sheet(isPresented: $showTodoList) {
                TodoListView()
            }
            .sheet(isPresented: $showTodoSheet) {
                if let target = todoTarget {
                    TodoDetailView(message: target) {
                        showTodoSheet = false
                    }
                }
            }
        }
    }

    private func triggerFlyingAnimation(text: String) {
        flyingMessage = FlyingMessageState(text: text, offset: 0, opacity: 1)
        withAnimation(.easeOut(duration: 0.35)) {
            flyingMessage?.offset = -120
            flyingMessage?.opacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            flyingMessage = nil
        }
    }

    private func deleteMessage(_ message: Message) {
        HapticManager.shared.play(.deleteMessage)
        MediaStore.shared.delete(relativePath: message.mediaPath)
        modelContext.delete(message)
    }
}

struct FlyingMessageState {
    let text: String
    var offset: CGFloat
    var opacity: Double
}

struct FlyingMessageView: View {
    let state: FlyingMessageState

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Text(state.text)
                    .font(.body)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color(red: 0.44, green: 0.85, blue: 0.44))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                    .offset(y: state.offset)
                    .opacity(state.opacity)
                Spacer().frame(width: 16)
            }
            .padding(.bottom, 90)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}
