enum OptWidget {
    case disabled
    case present(Widget)
}

class WidgetCache {
    private var widgets: [String: OptWidget] = [:]
    private var nextWidgets: [String: OptWidget] = [:]
    private var scroll: [ScrollWidget] = []
    private var nextScroll: [ScrollWidget] = []

    public func remove(_ key: String) -> Widget? {
        switch self.widgets.removeValue(forKey: key) {
        case nil, .disabled:
            return nil
        case let .present(widget):
            for key in widget.keys() {
                self.widgets.removeValue(forKey: key)
            }
            return widget
        }
    }

    public func remove(_ keys: [String]) -> Widget? {
        for key in keys {
            if let widget = self.remove(key) {
                return widget
            }
        }
        return nil
    }

    public func putNext(_ widget: Widget) {
        for key in widget.keys() {
            if self.nextWidgets[key] == nil {
                self.nextWidgets[key] = .present(widget)
            } else {
                // Two widgets use this key.  Don't use it for any widgets.
                // We cannot use `self.widgets[key] = nil` since that deletes the entry.
                self.nextWidgets.updateValue(.disabled, forKey: key)
            }
        }
    }

    public func removeScroll() -> ScrollWidget? {
        if self.scroll.isEmpty {
            return nil
        }
        return self.scroll.remove(at: 0)
    }

    public func putNextScroll(_ widget: ScrollWidget) {
        self.nextScroll.append(widget)
    }

    public func flip() {
        self.widgets = self.nextWidgets
        self.nextWidgets = [:]
        self.scroll = self.nextScroll
        self.nextScroll = []
    }
}
