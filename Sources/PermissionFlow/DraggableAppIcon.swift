import AppKit
import SwiftUI

public struct DraggableAppIcon: NSViewRepresentable {
    private let isDraggable: Bool

    public init(isDraggable: Bool = true) {
        self.isDraggable = isDraggable
    }

    public func makeNSView(context: Context) -> NSView {
        let view = DraggableApplicationIconView()
        view.isDraggable = isDraggable
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        view.setContentHuggingPriority(.defaultLow, for: .vertical)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        return view
    }

    public func updateNSView(_ nsView: NSView, context: Context) {
        guard let view = nsView as? DraggableApplicationIconView else { return }
        view.isDraggable = isDraggable
        view.window?.invalidateCursorRects(for: view)
    }
}

private final class DraggableApplicationIconView: NSImageView, NSDraggingSource {
    var isDraggable = true

    init() {
        super.init(frame: NSRect(x: 0, y: 0, width: 44, height: 44))
        image = NSImage(named: NSImage.applicationIconName)
        imageScaling = .scaleProportionallyUpOrDown
        translatesAutoresizingMaskIntoConstraints = false
        wantsLayer = true
        layer?.cornerRadius = 10
        layer?.masksToBounds = true
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: 44, height: 44)
    }

    override func resetCursorRects() {
        super.resetCursorRects()
        addCursorRect(bounds, cursor: isDraggable ? .openHand : .arrow)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func mouseDragged(with event: NSEvent) {
        guard isDraggable else { return }

        let appURL = Bundle.main.bundleURL as NSURL
        let item = NSDraggingItem(pasteboardWriter: appURL)
        let dragFrame = NSRect(
            x: bounds.midX - 22,
            y: bounds.midY - 22,
            width: 44,
            height: 44
        )
        item.setDraggingFrame(dragFrame, contents: image)
        beginDraggingSession(with: [item], event: event, source: self)
    }

    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        .copy
    }
}
