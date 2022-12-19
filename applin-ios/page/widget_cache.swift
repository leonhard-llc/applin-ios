import UIKit

/// A node with `optWidget`, which may be absent.
private class RoughNode {
    let keys: [String]
    let spec: Spec // Memory is not O(n^2) because Spec is a reference.
    let subs: [RoughNode]
    var optOldNode: DoneNode?
    weak var optSuper: RoughNode?

    init(_ spec: Spec) {
        self.spec = spec
        self.keys = spec.keys()
        self.subs = spec.subs().map({ subSpec in RoughNode(subSpec) })
        for sub in self.subs {
            sub.optSuper = self
        }
    }
}

/// A node with `widget`.
private class DoneNode {
    let keys: [String]
    let spec: Spec // Memory is not O(n^2) because Spec is a reference.
    let widget: Widget
    var subs: [DoneNode]
    weak var optSuper: DoneNode?

    init(_ roughNode: RoughNode) {
        self.keys = roughNode.keys
        self.spec = roughNode.spec
        self.subs = roughNode.subs.compactMap({ subNode in DoneNode(subNode) })
        self.widget = roughNode.optOldNode?.widget ?? roughNode.spec.newWidget()
        for sub in self.subs {
            sub.optSuper = self
        }
    }
}

private class NodeTable {
    private var optOldRoot: DoneNode?
    private var keyToNodes: [String: [DoneNode]] = [:]

    private func addKeyed(_ node: DoneNode) {
        for key in node.keys {
            self.keyToNodes[key, default: []].append(node)
        }
        for subNode in node.subs {
            self.addKeyed(subNode)
        }
    }

    func insert(_ root: DoneNode) {
        self.optOldRoot = root
        self.addKeyed(root)
    }

    func remove(_ node: DoneNode) {
        for key in node.keys {
            if var nodeList = self.keyToNodes[key] {
                nodeList.removeAll(where: { nodeInTable in nodeInTable === node })
            }
        }
        if self.optOldRoot === node {
            self.optOldRoot = nil
        }
        if let superNode = node.optSuper {
            superNode.subs.removeAll(where: { sub in sub === node })
        }
    }

    func find(_ roughNode: RoughNode) -> DoneNode? {
        for key in roughNode.keys {
            if let doneNodes = self.keyToNodes[key] {
                if doneNodes.count == 1 {
                    let doneNode = doneNodes.first!
                    if doneNode.spec.widgetClass() == roughNode.spec.widgetClass() {
                        return doneNode
                    }
                }
            }
        }
        return nil
    }

    func findOldSibling(_ roughNode: RoughNode) -> DoneNode? {
        if let superNode = roughNode.optSuper {
            if let oldSuper = superNode.optOldNode {
                for oldSibling in oldSuper.subs {
                    if oldSibling.spec.widgetClass() == roughNode.spec.widgetClass() {
                        return oldSibling
                    }
                }
            }
        }
        if let oldRoot = self.optOldRoot {
            if oldRoot.spec.widgetClass() == roughNode.spec.widgetClass() {
                return oldRoot
            }
        }
        return nil
    }

    func removeAll() {
        self.optOldRoot = nil
        self.keyToNodes.removeAll()
    }
}

class WidgetCache {
    private enum Order {
        case pre
        case post
    }

    private var table = NodeTable()

    private func visitNode(_ order: Order, _ node: RoughNode, _ findOldNode: (RoughNode) -> DoneNode?) -> DoneNode? {
        if order == .pre, node.optOldNode == nil, let oldNode = findOldNode(node) {
            self.table.remove(oldNode)
            node.optOldNode = oldNode
        }

        var optSubSuper: DoneNode?
        for subNode in node.subs {
            if let subSuper = self.visitNode(order, subNode, findOldNode) {
                if node.optOldNode == nil && optSubSuper == nil && subSuper.spec.widgetClass() == node.spec.widgetClass() {
                    optSubSuper = subSuper
                }
            }
        }
        if node.optOldNode == nil, let oldNode = optSubSuper {
            self.table.remove(oldNode)
            node.optOldNode = oldNode
        }

        if order == .post, node.optOldNode == nil, let oldNode = findOldNode(node) {
            self.table.remove(oldNode)
            node.optOldNode = oldNode
        }
        return node.optOldNode?.optSuper
    }

    private func updateNode(_ session: ApplinSession, _ node: DoneNode) {
        for subNode in node.subs {
            self.updateNode(session, subNode)
        }
        let subWidgets = node.subs.map({ subNode in subNode.widget })
        // TODO(mleonhard) Find a way to make this type-safe and eliminate the exception.
        try! node.widget.update(session, node.spec, subWidgets)
    }

    func updateAll(_ session: ApplinSession, _ spec: Spec) -> Widget {
        let roughRoot = RoughNode(spec)
        _ = self.visitNode(.post, roughRoot) { node in
            if node.spec.priority() == .focusable, let oldNode = self.table.find(node) {
                if oldNode.widget.isFocused() {
                    return oldNode
                }
            }
            return nil
        }
        _ = self.visitNode(.post, roughRoot, { node in node.spec.priority() == .focusable ? self.table.find(node) : nil })
        _ = self.visitNode(.post, roughRoot, { node in node.spec.priority() == .stateful ? self.table.find(node) : nil })
        _ = self.visitNode(.post, roughRoot, { node in self.table.find(node) })
        _ = self.visitNode(.pre, roughRoot, { node in self.table.findOldSibling(node) })
        let doneRoot = DoneNode(roughRoot)
        self.table.removeAll()
        self.table.insert(doneRoot)
        self.updateNode(session, doneRoot)
        return doneRoot.widget
    }
}
