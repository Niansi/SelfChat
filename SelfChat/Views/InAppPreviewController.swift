import SwiftUI
import QuickLook

struct InAppPreviewController: UIViewControllerRepresentable {
    let url: URL
    @Binding var isPresented: Bool

    func makeUIViewController(context: Context) -> UINavigationController {
        let preview = QLPreviewController()
        preview.dataSource = context.coordinator
        preview.delegate = context.coordinator
        let nav = UINavigationController(rootViewController: preview)
        nav.navigationBar.prefersLargeTitles = false
        return nav
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(url: url, isPresented: $isPresented)
    }

    class Coordinator: NSObject, QLPreviewControllerDataSource, QLPreviewControllerDelegate {
        let url: URL
        @Binding var isPresented: Bool

        init(url: URL, isPresented: Binding<Bool>) {
            self.url = url
            self._isPresented = isPresented
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            url as NSURL
        }

        func previewControllerDidDismiss(_ controller: QLPreviewController) {
            isPresented = false
        }
    }
}
