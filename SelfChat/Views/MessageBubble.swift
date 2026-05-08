import SwiftUI
import AVKit

struct MessageBubble: View {
    let message: Message
    @State private var galleryStartIndex = 0
    @State private var showGallery = false
    @State private var showFilePreview = false
    @State private var previewURL: URL?
    @State private var isMediaPressed = false

    var body: some View {
        HStack {
            Spacer(minLength: 60)
            VStack(alignment: .trailing, spacing: 4) {
                mainContent
                metaRow
            }
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        let paths = message.mediaPaths
        let names = message.fileNames
        let mediaPaths = mediaOnlyPaths(paths: paths, names: names)
        let filePairs = fileOnlyPairs(paths: paths, names: names)

        switch message.type {
        case .text:
            textBubble(message.text ?? "")

        case .image, .video, .mixed:
            VStack(alignment: .trailing, spacing: 6) {
                if mediaPaths.count == 1 {
                    singleMediaView(path: mediaPaths[0], name: names[paths.firstIndex(of: mediaPaths[0]) ?? 0])
                } else if mediaPaths.count > 1 {
                    mediaStackView(mediaPaths: mediaPaths, names: names, allPaths: paths)
                }
                ForEach(Array(filePairs.enumerated()), id: \.offset) { idx, pair in
                    fileBubble(path: pair.0, name: pair.1, sizeIndex: paths.firstIndex(of: pair.0) ?? idx)
                }
                if let txt = message.text, !txt.isEmpty {
                    textBubble(txt)
                }
            }

        case .file:
            VStack(alignment: .trailing, spacing: 6) {
                ForEach(Array(zip(paths, names).enumerated()), id: \.offset) { idx, pair in
                    fileBubble(path: pair.0, name: pair.1, sizeIndex: idx)
                }
                if let txt = message.text, !txt.isEmpty {
                    textBubble(txt)
                }
            }
        }
    }

    private func mediaOnlyPaths(paths: [String], names: [String]) -> [String] {
        if message.type == .image || message.type == .video { return paths }
        return zip(paths, names).filter { _, name in
            let ext = (name as NSString).pathExtension.lowercased()
            return ["jpg","jpeg","png","gif","heic","webp","mov","mp4","m4v"].contains(ext)
                || name == "image.jpg" || name == "video.mov"
        }.map(\.0)
    }

    private func fileOnlyPairs(paths: [String], names: [String]) -> [(String, String)] {
        if message.type != .mixed { return [] }
        return zip(paths, names).filter { _, name in
            let ext = (name as NSString).pathExtension.lowercased()
            return !["jpg","jpeg","png","gif","heic","webp","mov","mp4","m4v"].contains(ext)
                && name != "image.jpg" && name != "video.mov"
        }
    }

    private func isVideo(name: String) -> Bool {
        let ext = (name as NSString).pathExtension.lowercased()
        return ["mov","mp4","m4v"].contains(ext) || name == "video.mov"
    }

    private func textBubble(_ text: String) -> some View {
        Text(text)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(red: 0.44, green: 0.85, blue: 0.44))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func singleMediaView(path: String, name: String) -> some View {
        let url = MediaStore.shared.fileURL(for: path)
        return ZStack {
            if isVideo(name: name) {
                VideoThumbnailView(url: url)
                    .frame(width: 220, height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                ZStack {
                    Circle().fill(.ultraThinMaterial).frame(width: 52, height: 52)
                    Image(systemName: "play.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.primary)
                        .offset(x: 2)
                }
            } else if let img = UIImage(contentsOfFile: url.path) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: 220, maxHeight: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .scaleEffect(isMediaPressed ? 0.92 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.5), value: isMediaPressed)
        .onTapGesture {
            HapticManager.shared.play(.tapStack)
            isMediaPressed = true
            let idx = message.mediaPaths.firstIndex(of: path) ?? 0
            galleryStartIndex = idx
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                isMediaPressed = false
                showGallery = true
            }
        }
        .fullScreenCover(isPresented: $showGallery) {
            MediaGalleryView(
                paths: message.mediaPaths,
                names: message.fileNames,
                startIndex: galleryStartIndex,
                isPresented: $showGallery
            )
        }
    }

    private func mediaStackView(mediaPaths: [String], names: [String], allPaths: [String]) -> some View {
        CardStackView(
            mediaPaths: mediaPaths,
            names: names
        ) { tappedIndex in
            galleryStartIndex = tappedIndex
            showGallery = true
        }
        .fullScreenCover(isPresented: $showGallery) {
            MediaGalleryView(
                paths: message.mediaPaths,
                names: message.fileNames,
                startIndex: galleryStartIndex,
                isPresented: $showGallery
            )
        }
    }

    private func fileBubble(path: String, name: String, sizeIndex: Int) -> some View {
        let url = MediaStore.shared.fileURL(for: path)
        let ext = (name as NSString).pathExtension.lowercased()
        let info = FileIconHelper.info(for: name)
        let sizeStr = fileSizeString(sizeIndex < message.fileSizes.count ? message.fileSizes[sizeIndex] : 0)

        return HStack(spacing: 10) {
            FileIconView(fileName: name, size: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                HStack(spacing: 4) {
                    Text(ext.isEmpty ? "文件" : ext.uppercased())
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(info.color)
                    Text("·").font(.caption2).foregroundStyle(.tertiary)
                    Text(sizeStr).font(.caption2).foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color(.systemGray4).opacity(0.5), lineWidth: 0.5))
        .frame(maxWidth: 260)
        .onTapGesture {
            previewURL = url
            showFilePreview = true
        }
        .fullScreenCover(isPresented: $showFilePreview) {
            if let url = previewURL {
                InAppPreviewController(url: url, isPresented: $showFilePreview).ignoresSafeArea()
            }
        }
    }

    private var metaRow: some View {
        HStack(spacing: 4) {
            if message.isTodo {
                Image(systemName: "checkmark.circle.fill").font(.caption2).foregroundStyle(.green)
            }
            Text(message.createdAt.formatted(.dateTime.hour().minute()))
                .font(.caption2).foregroundStyle(.secondary)
        }
    }

    private func fileSizeString(_ size: Int64) -> String {
        let bytes = Double(size)
        if bytes < 1024 { return "\(size) B" }
        if bytes < 1024 * 1024 { return String(format: "%.1f KB", bytes / 1024) }
        return String(format: "%.1f MB", bytes / 1024 / 1024)
    }
}

struct MediaGalleryView: View {
    let paths: [String]
    let names: [String]
    let startIndex: Int
    @Binding var isPresented: Bool

    @State private var currentIndex: Int
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false
    @State private var isAppeared = false

    private let dismissThreshold: CGFloat = 120
    private let dismissVelocityThreshold: CGFloat = 600

    init(paths: [String], names: [String], startIndex: Int, isPresented: Binding<Bool>) {
        self.paths = paths
        self.names = names
        self.startIndex = startIndex
        self._isPresented = isPresented
        self._currentIndex = State(initialValue: startIndex)
    }

    private func isVideo(at index: Int) -> Bool {
        guard index < names.count else { return false }
        let name = names[index]
        let ext = (name as NSString).pathExtension.lowercased()
        return ["mov","mp4","m4v"].contains(ext) || name == "video.mov"
    }

    private var backgroundOpacity: Double {
        let progress = abs(dragOffset.height) / 300
        return max(0, 1.0 - progress)
    }

    var body: some View {
        ZStack {
            // 毛玻璃背景
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(backgroundOpacity * (isAppeared ? 1 : 0))
                .ignoresSafeArea()
                .animation(.easeOut(duration: 0.15), value: dragOffset.height)

            TabView(selection: $currentIndex) {
                ForEach(Array(paths.enumerated()), id: \.offset) { idx, path in
                    mediaPageView(path: path, index: idx)
                        .tag(idx)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()
            .offset(y: rubberBandedOffset)
            .scaleEffect(isAppeared ? scaleEffect : 0.88)
            .rotationEffect(.degrees(dragRotation))
            .opacity(isAppeared ? 1 : 0)
            // 使用 simultaneousGesture 让垂直下滑和 TabView 水平滑动共存
            .simultaneousGesture(
                DragGesture(minimumDistance: 5)
                    .onChanged { value in
                        let isVertical = abs(value.translation.height) >= abs(value.translation.width)
                        if isVertical && value.translation.height > 0 {
                            isDragging = true
                            dragOffset = value.translation
                        }
                    }
                    .onEnded { value in
                        isDragging = false
                        let velocity = value.velocity.height
                        if dragOffset.height > dismissThreshold || velocity > dismissVelocityThreshold {
                            // 跟手关闭：先让视图继续移动到手指释放的位置，然后动画关闭
                            let finalOffset = dragOffset.height + velocity * 0.15
                            withAnimation(.easeOut(duration: 0.25)) {
                                dragOffset = CGSize(width: dragOffset.width, height: finalOffset)
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                                isPresented = false
                                dragOffset = .zero
                            }
                        } else {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                                dragOffset = .zero
                            }
                        }
                    }
            )
            .onTapGesture(count: 2) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isPresented = false
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isAppeared = true
                }
            }

            VStack {
                HStack {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isPresented = false
                        }
                    } label: {
                        ZStack {
                            Circle().fill(.ultraThinMaterial).frame(width: 34, height: 34)
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.primary)
                        }
                    }
                    .padding(.leading, 16)
                    .padding(.top, 56)

                    Spacer()

                    if paths.count > 1 {
                        Text("\(currentIndex + 1) / \(paths.count)")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.primary.opacity(0.8))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(.ultraThinMaterial, in: Capsule())
                            .padding(.trailing, 16)
                            .padding(.top, 56)
                    }
                }
                Spacer()
            }
            .opacity(backgroundOpacity)
        }
    }

    private var rubberBandedOffset: CGFloat {
        let raw = dragOffset.height
        let limit: CGFloat = 80
        if raw <= limit {
            return raw
        }
        let excess = raw - limit
        return limit + excess * 0.4
    }

    private var scaleEffect: CGFloat {
        max(0.78, 1 - abs(dragOffset.height) / 500)
    }

    private var dragRotation: Double {
        Double(dragOffset.width / 25)
    }

    @ViewBuilder
    private func mediaPageView(path: String, index: Int) -> some View {
        let url = MediaStore.shared.fileURL(for: path)
        if isVideo(at: index) {
            VideoPlayer(player: AVPlayer(url: url))
                .ignoresSafeArea()
        } else if let img = UIImage(contentsOfFile: url.path) {
            Image(uiImage: img)
                .resizable()
                .scaledToFit()
        }
    }
}

struct VideoThumbnailView: View {
    let url: URL
    @State private var thumbnail: UIImage?

    var body: some View {
        Group {
            if let thumbnail {
                Image(uiImage: thumbnail).resizable().scaledToFill()
            } else {
                Rectangle().fill(Color.black.opacity(0.6))
            }
        }
        .onAppear { generateThumbnail() }
    }

    private func generateThumbnail() {
        Task.detached {
            let asset = AVAsset(url: url)
            let gen = AVAssetImageGenerator(asset: asset)
            gen.appliesPreferredTrackTransform = true
            gen.maximumSize = CGSize(width: 440, height: 320)
            if let cgImage = try? gen.copyCGImage(at: .zero, actualTime: nil) {
                let image = UIImage(cgImage: cgImage)
                await MainActor.run { thumbnail = image }
            }
        }
    }
}
