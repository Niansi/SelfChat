import SwiftUI
import SwiftData

struct TodoListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TodoItem.createdAt, order: .reverse) private var todos: [TodoItem]

    var body: some View {
        NavigationStack {
            Group {
                if todos.isEmpty {
                    ContentUnavailableView("暂无待办", systemImage: "checkmark.circle", description: Text("长按消息可转为待办"))
                } else {
                    List {
                        ForEach(todos) { todo in
                            TodoRow(todo: todo)
                        }
                        .onDelete { indexSet in
                            indexSet.forEach { i in
                                let todo = todos[i]
                                NotificationService.shared.cancel(todoId: todo.id)
                                modelContext.delete(todo)
                            }
                        }
                    }
                }
            }
            .navigationTitle("待办")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct TodoRow: View {
    @Environment(\.modelContext) private var modelContext
    let todo: TodoItem

    var body: some View {
        HStack(spacing: 12) {
            Button {
                toggleComplete()
            } label: {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(todo.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                Text(todo.reminderText)
                    .strikethrough(todo.isCompleted)
                    .foregroundStyle(todo.isCompleted ? .secondary : .primary)
                    .lineLimit(3)

                if let date = todo.reminderDate {
                    Label(date.formatted(.dateTime.month().day().hour().minute()), systemImage: "bell")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func toggleComplete() {
        todo.isCompleted.toggle()
        if todo.isCompleted {
            NotificationService.shared.cancel(todoId: todo.id)
        } else if let date = todo.reminderDate, date > Date() {
            NotificationService.shared.schedule(todoId: todo.id, title: todo.reminderText, date: date)
        }
    }
}
