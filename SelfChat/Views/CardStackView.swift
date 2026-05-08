import SwiftUI

struct CardStackView: View {
    let mediaPaths: [String]
    let names: [String]
    let onTap: (Int) -> Void

    @State private var currentIndex = 0
    @State private var dragOffset: CGSize = .zero
    @State private var dragRotation: Double = 0
    @State private var isWiggling = false
    @State private var transitioningIndex: Int?

    @Environment(\.scenePhase) private var scenePhase

    private let swipeThreshold: CGFloat = 60
    private let velocityThreshold: CGFloat = 400

    var body: some View {
        ZStack {
            ForEach(displayIndices, id: \.self) { idx in
                cardView(at: idx)
            }
        }
        .frame(width: 194, height: 194)
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if oldPhase != .active && newPhase == .active {
                // 从非活跃状态回到活跃，触发微动
                triggerWiggle()
            } else if newPhase != .active {
                // 离开活跃状态，恢复整齐
                isWiggling = false
            }
        }
        .onAppear {
            triggerWiggle()
        }
    }

    private var displayIndices: [Int] {
        var indices: [Int] = []
        let start = currentIndex
        let end = min(start + 3, mediaPaths.count)
        for i in start..<end {
            indices.append(i)
        }
        if let transitioningIndex {
            indices.append(transitioningIndex)
        }
        return indices
    }

    private func depth(for idx: Int) -> Int {
        if let transitioningIndex, idx == transitioningIndex {
            return 3
        }
        let d = idx - currentIndex
        return max(0, min(d, 2))
    }

    private func isTopCard(_ idx: Int) -> Bool {
        idx == currentIndex
    }

    @ViewBuilder
    private func cardView(at idx: Int) -> some View {
        let isTop = isTopCard(idx)
        let d = depth(for: idx)
        let baseScale = 1.0 - Double(d) * 0.05
        let wiggleOffset = isWiggling && d > 0 ? wiggleRotation(for: d) : 0.0
        let baseRotation = Double(d) * 3.5 - 3.5 + wiggleOffset
        let baseOffsetX = CGFloat(d) * 4 + CGFloat(wiggleOffset * 0.5)
        let baseOffsetY = CGFloat(d) * -4

        let url = MediaStore.shared.fileURL(for: mediaPaths[idx])
        let name = names[safe: idx] ?? ""

        ZStack {
            if isVideo(name: name) {
                VideoThumbnailView(url: url)
                    .frame(width: 180, height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            } else if let img = UIImage(contentsOfFile: url.path) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 180, height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)
        .rotationEffect(.degrees(baseRotation + (isTop ? dragRotation : 0)))
        .offset(
            x: baseOffsetX + (isTop ? dragOffset.width : 0),
            y: baseOffsetY + (isTop ? dragOffset.height * 0.3 : 0)
        )
        .scaleEffect(
            isTop && dragOffset != .zero
                ? max(0.94, 1.0 - Double(abs(dragOffset.width)) / 600.0)
                : baseScale
        )
        .zIndex(isTop ? 100 : Double(mediaPaths.count - d))
        .animation(.spring(response: 0.45, dampingFraction: 0.75), value: currentIndex)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isWiggling)
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: transitioningIndex)
        .gesture(
            isTop && transitioningIndex == nil
                ? DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation
                        dragRotation = Double(value.translation.width / 20)
                    }
                    .onEnded { value in
                        let velocity = value.velocity.width
                        if value.translation.width > swipeThreshold || velocity > velocityThreshold {
                            swipeToBottom(direction: 1)
                        } else if value.translation.width < -swipeThreshold || velocity < -velocityThreshold {
                            swipeToBottom(direction: -1)
                        } else {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                dragOffset = .zero
                                dragRotation = 0
                            }
                        }
                    }
                : nil
        )
        .onTapGesture {
            if isTop && transitioningIndex == nil {
                HapticManager.shared.play(.tapStack)
                onTap(idx)
            }
        }
    }

    private func swipeToBottom(direction: CGFloat) {
        HapticManager.shared.play(.swipeStack)
        let outgoing = currentIndex
        transitioningIndex = outgoing

        // 让顶层卡片移动到堆栈底部位置
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            dragOffset = CGSize(width: direction * 15, height: 15)
            dragRotation = Double(direction * 3)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            currentIndex = (currentIndex + 1) % mediaPaths.count
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                transitioningIndex = nil
                dragOffset = .zero
                dragRotation = 0
            }
        }
    }

    private func triggerWiggle() {
        guard mediaPaths.count > 1 else { return }
        // 先恢复整齐，再微动，形成自然过渡
        isWiggling = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.easeInOut(duration: 0.3)) {
                isWiggling = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.6)) {
                    isWiggling = false
                }
            }
        }
    }

    private func wiggleRotation(for depth: Int) -> Double {
        let offsets: [Double] = [0, 3.5, -2.5]
        return offsets[safe: depth] ?? 0
    }

    private func isVideo(name: String) -> Bool {
        let ext = (name as NSString).pathExtension.lowercased()
        return ["mov", "mp4", "m4v"].contains(ext) || name == "video.mov"
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
