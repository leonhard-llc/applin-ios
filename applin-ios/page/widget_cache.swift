import UIKit

private class UpdaterNode {
    static func update(_ session: ApplinSession, _ cache: WidgetCache, _ spec: Spec) -> WidgetProto {
        let root = UpdaterNode(spec)
        root.getSomeWidgets(session, cache, spec) { data in
            if data.priority() == .focusable {
                if let widget = cache.findStale(data) {
                    return widget.isFocused()
                }
            }
            return false
        }
        root.getSomeWidgets(session, cache, spec) { data in
            data.priority() == .focusable
        }
        root.getSomeWidgets(session, cache, spec) { data in
            data.priority() == .stateful
        }
        root.getSomeWidgets(session, cache, spec) { _ in
            true
        }
        root.updateNodeAndSubs(session, cache, spec)
        return root.widget!
    }

    // TODONT: Don't store WidgetData, since that would take O(n^2) memory and O(n^3) time.

    private let subNodes: [UpdaterNode]
    private var widget: WidgetProto?

    init(_ spec: Spec) {
        // TODO: Add keys for focused subs.
        self.subNodes = spec.subs().map({ subData in UpdaterNode(subData) })
    }

    func getSomeWidgets(_ session: ApplinSession, _ cache: WidgetCache, _ spec: Spec, _ shouldGetViewFn: (Spec) -> Bool) {
        var isASubBuilt = false
        for (n, subData) in spec.subs().enumerated() {
            let subNode = self.subNodes[n]
            subNode.getSomeWidgets(session, cache, subData, shouldGetViewFn)
            isASubBuilt = isASubBuilt || subNode.widget != nil
        }
        if self.widget == nil && (isASubBuilt || shouldGetViewFn(spec)) {
            self.widget = cache.getOrMake(spec)
        }
    }

    func updateNodeAndSubs(_ session: ApplinSession, _ cache: WidgetCache, _ spec: Spec) {
        for (n, subData) in spec.subs().enumerated() {
            let subNode = self.subNodes[n]
            subNode.updateNodeAndSubs(session, cache, subData)
        }
        if self.widget == nil {
            self.widget = cache.getOrMake(spec)
        }
        let subWidgets = self.subNodes.map({ node in node.widget! })
        // TODO(mleonhard) Find a way to make this type-safe and eliminate the exception.
        try! self.widget!.update(session, spec, subWidgets)
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

    func findStale(_ spec: Spec) -> WidgetProto? {
        for key in spec.keys() {
            if case let .stale(widget) = self.keyToWidgets[key] {
                if type(of: widget) == spec.widgetClass() {
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

    public func getOrMake(_ spec: Spec) -> WidgetProto {
        let newKeys = spec.keys()
        if let widget = self.findStale(spec) {
            self.removeStale(keys: newKeys)
            self.addFresh(keys: newKeys, widget)
            return widget
        } else {
            let widget = spec.widget()
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

    public func updateAll(_ session: ApplinSession, _ spec: Spec) -> WidgetProto {
        let rootWidget = UpdaterNode.update(session, self, spec)
        self.removeStaleAndChangeFreshToStale()
        return rootWidget
    }
}
