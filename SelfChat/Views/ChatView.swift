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
                                        .combined(with: .scale(scale: 0.85))
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
                                .geometryGroup()
                                .visualEffect { content, proxy in
                                    let frame = proxy.frame(in: .global)
                                    // 使用固定参考值避免 UIScreen.main 废弃警告
                                    let referenceCenter: CGFloat = 450
                                    let distance = abs(frame.midY - referenceCenter)
                                    let progress = min(distance / referenceCenter, 1.0)
                                    // 更明显的挤压效果
                                    let scaleY = 1 - progress * 0.06
                                    let scaleX = 1 + progress * 0.03
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
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
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
        // 起始位置：和输入框齐平（底部偏右）
        // 目标位置：消息列表区域（向上飞约 120pt）
        flyingMessage = FlyingMessageState(
            text: text,
            offsetY: 0,
            offsetX: 0,
            scale: 1.0,
            opacity: 1.0
        )
        withAnimation(.easeOut(duration: 0.4)) {
            flyingMessage?.offsetY = -130
            flyingMessage?.offsetX = 10
            flyingMessage?.scale = 0.88
            flyingMessage?.opacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
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
    var offsetY: CGFloat
    var offsetX: CGFloat
    var scale: CGFloat
    var opacity: Double
}

struct FlyingMessageView: View {
    let state: FlyingMessageState

    var body: some View {
        GeometryReader { geo in
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
                        .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
                        .offset(x: state.offsetX, y: state.offsetY)
                        .scaleEffect(state.scale)
                        .opacity(state.opacity)
                    Spacer().frame(width: 20)
                }
                .padding(.bottom, max(geo.safeAreaInsets.bottom + 72, 90))
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
    }
}
