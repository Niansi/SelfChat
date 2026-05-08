import SwiftUI
import SwiftData

struct TodoDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let message: Message
    let onDismiss: () -> Void

    @State private var reminderText: String = ""
    @State private var hasReminder = false
    @State private var reminderDate = Date().addingTimeInterval(3600)

    var body: some View {
        NavigationStack {
            Form {
                Section("待办内容") {
                    TextField("描述", text: $reminderText, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section {
                    Toggle("设置提醒", isOn: $hasReminder)
                    if hasReminder {
                        DatePicker("提醒时间", selection: $reminderDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                    }
                }
            }
            .navigationTitle("添加待办")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { onDismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") { save() }
                        .disabled(reminderText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                reminderText = prefilledText()
            }
        }
    }

    private func prefilledText() -> String {
        switch message.type {
        case .text:
            return message.text ?? ""
        case .image:
            return "查看图片"
        case .video:
            return "查看视频"
        case .file:
            return message.fileName ?? "查看文件"
        case .mixed:
            return message.text ?? "查看附件"
        }
    }

    private func save() {
        let text = reminderText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let todo = TodoItem(
            messageId: message.id,
            reminderText: text,
            reminderDate: hasReminder ? reminderDate : nil
        )
        modelContext.insert(todo)

        if hasReminder {
            NotificationService.shared.schedule(todoId: todo.id, title: text, date: reminderDate)
        }

        message.isTodo = true
        onDismiss()
    }
}
