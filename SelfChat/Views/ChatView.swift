import SwiftUI
import SwiftData

struct ChatView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Message.createdAt, order: .forward) private var messages: [Message]

    @State private var showTodoList = false
    @State private var todoTarget: Message?
    @State private var showTodoSheet = false

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
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
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    .padding(.bottom, 120)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: messages.count) { _, _ in
                    if let last = messages.last {
                        withAnimation {
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
                    for message in msgs {
                        modelContext.insert(message)
                    }
                }
                .background(.clear)
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

    private func deleteMessage(_ message: Message) {
        MediaStore.shared.delete(relativePath: message.mediaPath)
        modelContext.delete(message)
    }
}
