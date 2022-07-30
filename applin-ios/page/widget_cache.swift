private enum CacheEntry {
    case tombstone
    case ok(WidgetProto)
}

class WidgetCache {
    private var form: [FormWidget] = []
    private var nextForm: [FormWidget] = []
    private var scroll: [ScrollWidget] = []
    private var nextScroll: [ScrollWidget] = []
    private var keyed: [String: CacheEntry] = [:]
    private var nextKeyed: [String: CacheEntry] = [:]

    public func flip() {
        self.keyed = self.nextKeyed
        self.nextKeyed = [:]
        self.scroll = self.nextScroll
        self.nextScroll = []
        self.form = self.nextForm
        self.nextForm = []
    }

    // Non-Keyed Widgets /////////////////////////////////////////////////////

    public func putNextForm(_ widget: FormWidget) {
        self.nextForm.append(widget)
    }

    public func putNextScroll(_ widget: ScrollWidget) {
        self.nextScroll.append(widget)
    }

    public func removeForm() -> FormWidget? {
        if self.form.isEmpty {
            return nil
        }
        return self.form.remove(at: 0)
    }

    public func removeScroll() -> ScrollWidget? {
        if self.scroll.isEmpty {
            return nil
        }
        return self.scroll.remove(at: 0)
    }

    // Keyed Widgets /////////////////////////////////////////////////////////

    public func putNext(_ widget: WidgetProto) {
        for key in widget.keys() {
            if self.nextKeyed[key] == nil {
                self.nextKeyed[key] = .ok(widget)
            } else {
                // Two widgets use this key.  Don't use it for any widgets.
                // We cannot use `self.widgets[key] = nil` since that deletes the entry.
                self.nextKeyed.updateValue(.tombstone, forKey: key)
            }
        }
    }

    private func removeKeyed(_ key: String) -> WidgetProto? {
        switch self.keyed.removeValue(forKey: key) {
        case nil, .tombstone:
            return nil
        case let .ok(widget):
            for key in widget.keys() {
                self.keyed.removeValue(forKey: key)
            }
            return widget
        }
    }

    public func get(_ keys: [String]) -> WidgetProto? {
        for key in keys {
            if case let .ok(widget) = self.keyed[key] {
                return widget
            }
        }
        for key in keys {
            if case let .ok(widget) = self.nextKeyed[key] {
                return widget
            }
        }
        return nil
    }

    public func remove(_ keys: [String]) -> WidgetProto? {
        for key in keys {
            if let widget = self.removeKeyed(key) {
                return widget
            }
        }
        return nil
    }
}
