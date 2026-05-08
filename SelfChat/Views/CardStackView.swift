import SwiftUI

struct CardStackView: View {
    let mediaPaths: [String]
    let names: [String]
    let onTap: (Int) -> Void

    @State private var currentIndex = 0
    @State private var dragOffset: CGSize = .zero
    @State private var dragRotation: Double = 0
    @State private var hasWiggled = false
    @State private var wigglePhase = false

    private let swipeThreshold: CGFloat = 80
    private let velocityThreshold: CGFloat = 500

    var body: some View {
        ZStack {
            ForEach(visibleIndices.reversed(), id: \.self) { idx in
                cardView(at: idx)
            }
        }
        .frame(width: 194, height: 194)
        .onAppear {
            triggerWiggle()
        }
        .onChange(of: mediaPaths.count) { _, _ in
            currentIndex = 0
            hasWiggled = false
            triggerWiggle()
        }
    }

    private var visibleIndices: [Int] {
        let start = currentIndex
        let end = min(start + 3, mediaPaths.count)
        return Array(start..<end)
    }

    @ViewBuilder
    private func cardView(at idx: Int) -> some View {
        let isTop = idx == currentIndex
        let depth = idx - currentIndex
        let baseScale = 1.0 - Double(depth) * 0.05
        let baseRotation = Double(depth) * 3.5 - 3.5 + (wigglePhase && depth > 0 ? wiggleOffset(for: depth) : 0)
        let baseOffsetX = CGFloat(depth) * 4 + (wigglePhase && depth > 0 ? CGFloat(wiggleOffset(for: depth) * 2) : 0)
        let baseOffsetY = CGFloat(depth) * -4

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
        .scaleEffect(isTop && dragOffset != .zero ? max(0.92, 1.0 - Double(abs(dragOffset.width)) / 800.0) : baseScale)
        .opacity(isTop && abs(dragOffset.width) > 20 ? 1.0 - Double(abs(dragOffset.width)) / 300.0 : 1.0)
        .zIndex(Double(mediaPaths.count - idx))
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: currentIndex)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: wigglePhase)
        .gesture(
            isTop ? DragGesture()
                .onChanged { value in
                    dragOffset = value.translation
                    dragRotation = Double(value.translation.width / 20)
                }
                .onEnded { value in
                    let velocity = value.velocity.width
                    if value.translation.width > swipeThreshold || velocity > velocityThreshold {
                        swipeAway(direction: 1)
                    } else if value.translation.width < -swipeThreshold || velocity < -velocityThreshold {
                        swipeAway(direction: -1)
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
            if isTop {
                HapticManager.shared.play(.tapStack)
                onTap(idx)
            }
        }
    }

    private func swipeAway(direction: CGFloat) {
        HapticManager.shared.play(.swipeStack)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            dragOffset = CGSize(width: direction * 500, height: dragOffset.height)
            dragRotation = Double(direction * 25)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            currentIndex = (currentIndex + 1) % mediaPaths.count
            dragOffset = .zero
            dragRotation = 0
        }
    }

    private func triggerWiggle() {
        guard !hasWiggled else { return }
        hasWiggled = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.25)) {
                wigglePhase = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    wigglePhase = false
                }
            }
        }
    }

    private func wiggleOffset(for depth: Int) -> Double {
        let offsets: [Double] = [0, 2.5, -1.5]
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
