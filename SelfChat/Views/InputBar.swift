import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct InputBar: View {
    let onSend: ([Message]) -> Void

    @State private var text = ""
    @State private var drafts: [AttachmentDraft] = []
    @State private var showMenu = false
    @State private var showPhotoPicker = false
    @State private var showFilePicker = false
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var isSending = false
    @Namespace private var glassNamespace

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !drafts.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            if !drafts.isEmpty {
                attachmentPreviewBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.horizontal, 16)
                    .padding(.bottom, 6)
            }

            GlassEffectContainer(spacing: 12) {
                HStack(alignment: .center, spacing: 12) {
                    plusButton

                    inputCapsule
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
        }
        .background(.clear)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: drafts.count)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showMenu)
        .photosPicker(
            isPresented: $showPhotoPicker,
            selection: $selectedPhotos,
            maxSelectionCount: 9,
            matching: .any(of: [.images, .videos]),
            photoLibrary: .shared()
        )
        .onChange(of: selectedPhotos) { _, items in
            guard !items.isEmpty else { return }
            loadPhotos(items)
            selectedPhotos = []
        }
        .sheet(isPresented: $showFilePicker) {
            DocumentPickerView(allowsMultiple: true) { urls in
                for url in urls { handleFile(url) }
            }
        }
    }

    private var plusButton: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showMenu.toggle()
            }
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 18, weight: .semibold))
                .rotationEffect(.degrees(showMenu ? 45 : 0))
                .animation(.spring(response: 0.3, dampingFraction: 0.65), value: showMenu)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .glassEffectID("plus", in: glassNamespace)
        .overlay(alignment: .bottomLeading) {
            if showMenu {
                menuPopup
                    .offset(x: 0, y: -72)
                    .glassEffectID("menu", in: glassNamespace)
                    .glassEffectTransition(.materialize)
                    .fixedSize()
            }
        }
    }

    private var inputCapsule: some View {
        HStack(alignment: .center, spacing: 8) {
            TextField("发送消息...", text: $text, axis: .vertical)
                .lineLimit(1...5)
                .textFieldStyle(.plain)
                .frame(maxWidth: .infinity)

            if canSend {
                Button {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                        isSending = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        isSending = false
                    }
                    sendAll()
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(Color.green, in: Circle())
                }
                .buttonStyle(.plain)
                .scaleEffect(isSending ? 0.75 : 1.0)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassEffect(.regular.interactive(), in: .capsule)
        .glassEffectID("capsule", in: glassNamespace)
    }

    private var menuPopup: some View {
        HStack(spacing: 20) {
            menuItem(icon: "photo.on.rectangle.fill", label: "照片") {
                showMenu = false
                showPhotoPicker = true
            }
            menuItem(icon: "doc.badge.plus", label: "文件") {
                showMenu = false
                showFilePicker = true
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 24))
    }

    private func menuItem(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .frame(width: 48, height: 48)
                    .glassEffect(in: .circle)
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }

    private var attachmentPreviewBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(drafts) { draft in
                    attachmentChip(draft)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
        }
    }

    @ViewBuilder
    private func attachmentChip(_ draft: AttachmentDraft) -> some View {
        ZStack(alignment: .topTrailing) {
            Group {
                switch draft.kind {
                case .image(let img, _):
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                case .video:
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.black.opacity(0.7))
                            .frame(width: 64, height: 64)
                        Image(systemName: "play.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                    }
                case .file(_, let name, _):
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.systemGray5))
                            .frame(width: 64, height: 64)
                        VStack(spacing: 4) {
                            FileIconView(fileName: name, size: 28)
                            Text((name as NSString).pathExtension.uppercased())
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            }

            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    drafts.removeAll { $0.id == draft.id }
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(Color(.systemGray2))
                        .frame(width: 18, height: 18)
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .offset(x: 6, y: -6)
        }
    }

    private func sendAll() {
        SoundManager.shared.playSendSound()
        HapticManager.shared.play(.sendMessage)

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        var messages: [Message] = []

        if drafts.isEmpty {
            if !trimmed.isEmpty {
                messages.append(Message(type: .text, text: trimmed))
            }
        } else {
            var paths: [String] = []
            var names: [String] = []
            var sizes: [Int64] = []
            var types: [MessageType] = []

            for draft in drafts {
                switch draft.kind {
                case .image(_, let data):
                    if let path = try? MediaStore.shared.saveData(data, fileName: "image.jpg") {
                        paths.append(path); names.append("image.jpg")
                        sizes.append(Int64(data.count)); types.append(.image)
                    }
                case .video(_, let data):
                    if let path = try? MediaStore.shared.saveData(data, fileName: "video.mov") {
                        paths.append(path); names.append("video.mov")
                        sizes.append(Int64(data.count)); types.append(.video)
                    }
                case .file(let url, _, _):
                    guard url.startAccessingSecurityScopedResource() else { continue }
                    defer { url.stopAccessingSecurityScopedResource() }
                    if let result = try? MediaStore.shared.importFile(from: url) {
                        paths.append(result.path); names.append(result.fileName)
                        sizes.append(result.fileSize); types.append(.file)
                    }
                }
            }

            let overallType: MessageType
            if types.allSatisfy({ $0 == .image }) { overallType = .image }
            else if types.allSatisfy({ $0 == .video }) { overallType = .video }
            else if types.allSatisfy({ $0 == .file }) { overallType = .file }
            else { overallType = .mixed }

            messages.append(Message(
                type: overallType,
                text: trimmed.isEmpty ? nil : trimmed,
                mediaPaths: paths,
                fileNames: names,
                fileSizes: sizes
            ))
        }

        onSend(messages)
        text = ""
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            drafts = []
        }
    }

    private func loadPhotos(_ items: [PhotosPickerItem]) {
        for item in items {
            let isVideo = item.supportedContentTypes.contains(where: { $0.conforms(to: .movie) })
            item.loadTransferable(type: Data.self) { result in
                guard case .success(let data) = result, let data else { return }
                DispatchQueue.main.async {
                    if isVideo {
                        let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mov")
                        try? data.write(to: tmpURL)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            drafts.append(AttachmentDraft(kind: .video(tmpURL, data)))
                        }
                    } else if let img = UIImage(data: data) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            drafts.append(AttachmentDraft(kind: .image(img, data)))
                        }
                    }
                }
            }
        }
    }

    private func handleFile(_ url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        let name = url.lastPathComponent
        let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize).map(Int64.init) ?? 0
        url.stopAccessingSecurityScopedResource()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            drafts.append(AttachmentDraft(kind: .file(url, name, size)))
        }
    }
}

struct DocumentPickerView: UIViewControllerRepresentable {
    var allowsMultiple: Bool = false
    let onPick: ([URL]) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.item])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = allowsMultiple
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: ([URL]) -> Void
        init(onPick: @escaping ([URL]) -> Void) { self.onPick = onPick }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            onPick(urls)
        }
    }
}
