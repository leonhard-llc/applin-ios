import UIKit

private class UpdaterNode {
    static func update(_ session: ApplinSession, _ cache: WidgetCache, _ data: WidgetData) -> UIView {
        let root = UpdaterNode(data)
        root.getSomeWidgets(session, cache, data) { data in
            if data.inner().priority() == .focusable {
                if let widget = cache.findStale(data) {
                    return widget.isFocused(session, data)
                }
            }
            return false
        }
        root.getSomeWidgets(session, cache, data) { data in
            data.inner().priority() == .focusable
        }
        root.getSomeWidgets(session, cache, data) { _ in
            true
        }
        root.updateNodeAndSubs(session, cache, data)
        return root.widget!.getView()
    }

    // TODONT: Don't store WidgetData, since that would take O(n^2) memory and O(n^3) time.

    private let subNodes: [UpdaterNode]
    private var widget: WidgetProto?

    init(_ data: WidgetData) {
        // TODO: Add keys for focused subs.
        self.subNodes = data.inner().subs().map({ subData in UpdaterNode(subData) })
    }

    func getSomeWidgets(_ session: ApplinSession, _ cache: WidgetCache, _ data: WidgetData, _ shouldGetViewFn: (WidgetData) -> Bool) {
        var isASubBuilt = false
        for (n, subData) in data.inner().subs().enumerated() {
            let subNode = self.subNodes[n]
            subNode.getSomeWidgets(session, cache, subData, shouldGetViewFn)
            isASubBuilt = isASubBuilt || subNode.widget != nil
        }
        if self.widget == nil && (isASubBuilt || shouldGetViewFn(data)) {
            self.widget = cache.getOrMake(data)
        }
    }

    func updateNodeAndSubs(_ session: ApplinSession, _ cache: WidgetCache, _ data: WidgetData) {
        for (n, subData) in data.inner().subs().enumerated() {
            let subNode = self.subNodes[n]
            subNode.updateNodeAndSubs(session, cache, subData)
        }
        if self.widget == nil {
            self.widget = cache.getOrMake(data)
        }
        let subWidgets = self.subNodes.map({ node in node.widget! })
        // TODO(mleonhard) Find a way to make this type-safe and eliminate the exception.
        try! self.widget!.update(session, data, subWidgets)
    }
}

private enum CacheEntry {
    case duplicate
    case fresh(WidgetProto)
    case stale(WidgetProto)
}

class WidgetCache: CustomStringConvertible {
    private var keyToWidgets: [String: CacheEntry] = [:]

    public var description: String {
        "WidgetCache(\(self.keyToWidgets))"
    }

    private func addFresh(keys: [String], _ widget: WidgetProto) {
        for key in keys {
            switch self.keyToWidgets[key] {
            case nil, .stale(_):
                self.keyToWidgets[key] = .fresh(widget)
            case .duplicate:
                break
            case .fresh(_):
                // Two widgets use this key.  Don't use it for any widgets.
                self.keyToWidgets[key] = .duplicate
            }
        }
    }

    func findStale(_ data: WidgetData) -> WidgetProto? {
        for key in data.inner().keys() {
            if case let .stale(widget) = self.keyToWidgets[key] {
                if type(of: widget) == data.inner().widgetClass() {
                    return widget
                }
            }
        }
        return nil
    }

    private func removeStale(keys: [String]) {
        for key in keys {
            switch self.keyToWidgets[key] {
            case nil, .duplicate, .fresh(_):
                break
            case .stale:
                self.keyToWidgets.removeValue(forKey: key)
            }
        }
    }

    public func getOrMake(_ data: WidgetData) -> WidgetProto {
        let newKeys = data.inner().keys()
        if let widget = self.findStale(data) {
            self.removeStale(keys: newKeys)
            self.addFresh(keys: newKeys, widget)
            return widget
        } else {
            let widget = data.inner().widget()
            self.addFresh(keys: newKeys, widget)
            return widget
        }
    }

    private func removeStaleAndChangeFreshToStale() {
        for (key, value) in self.keyToWidgets {
            switch value {
            case .duplicate:
                break
            case .stale(_):
                self.keyToWidgets.removeValue(forKey: key)
            case let .fresh(widget):
                self.keyToWidgets[key] = .stale(widget)
            }
        }
    }

    public func updateAll(_ session: ApplinSession, _ data: WidgetData) -> UIView {
        let view = UpdaterNode.update(session, self, data)
        self.removeStaleAndChangeFreshToStale()
        return view
    }
}
