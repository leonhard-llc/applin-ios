private enum CacheEntry {
    case tombstone
    case ok(WidgetProto)
}

class WidgetCache {
    private var widgets: [String: CacheEntry] = [:]
    private var nextWidgets: [String: CacheEntry] = [:]
    private var scroll: [ScrollWidget] = []
    private var nextScroll: [ScrollWidget] = []

    public func remove(_ key: String) -> WidgetProto? {
        switch self.widgets.removeValue(forKey: key) {
        case nil, .tombstone:
            return nil
        case let .ok(widget):
            for key in widget.keys() {
                self.widgets.removeValue(forKey: key)
            }
            return widget
        }
    }

    public func remove(_ keys: [String]) -> WidgetProto? {
        for key in keys {
            if let widget = self.remove(key) {
                return widget
            }
        }
        return nil
    }

    public func putNext(_ widget: WidgetProto) {
        for key in widget.keys() {
            if self.nextWidgets[key] == nil {
                self.nextWidgets[key] = .ok(widget)
            } else {
                // Two widgets use this key.  Don't use it for any widgets.
                // We cannot use `self.widgets[key] = nil` since that deletes the entry.
                self.nextWidgets.updateValue(.tombstone, forKey: key)
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
