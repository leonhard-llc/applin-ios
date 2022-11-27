import UIKit

/// A node with `optWidget`, which may be absent.
private class RoughNode {
    let keys: [String]
    let spec: Spec // Memory is not O(n^2) because Spec is a reference.
    let subNodes: [RoughNode]
    weak var superNode: RoughNode?
    var optWidget: Widget?

    init(_ spec: Spec) {
        self.spec = spec
        self.keys = spec.keys()
        self.subNodes = spec.subs().map({ subSpec in RoughNode(subSpec) })
        for subNode in self.subNodes {
            subNode.superNode = self
        }
    }
}

/// A node with `widget`.
private class DoneNode {
    let keys: [String]
    let spec: Spec // Memory is not O(n^2) because Spec is a reference.
    let subNodes: [DoneNode]
    let widget: Widget
    weak var superNode: DoneNode?

    init(_ roughNode: RoughNode) {
        self.keys = roughNode.keys
        self.spec = roughNode.spec
        self.subNodes = roughNode.subNodes.compactMap({ subNode in DoneNode(subNode) })
        self.widget = roughNode.optWidget ?? roughNode.spec.newWidget()
        for subNode in self.subNodes {
            subNode.superNode = self
        }
    }
}

private class NodeTable {
    private var keyToNodes: [String: [DoneNode]] = [:]

    func insert(_ node: DoneNode) {
        for key in node.keys {
            self.keyToNodes[key, default: []].append(node)
        }
        for subNode in node.subNodes {
            self.insert(subNode)
        }
    }

    func remove(_ node: DoneNode) {
        for key in node.keys {
            if var nodeList = self.keyToNodes[key] {
                nodeList.removeAll(where: { nodeInTable in nodeInTable === node })
            }
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

    func removeAll() {
        self.keyToNodes.removeAll()
    }
}

class WidgetCache {
    private var table = NodeTable()

    private func visitNode(_ node: RoughNode, _ findOldNode: (RoughNode) -> DoneNode?) -> DoneNode? {
        var oldSuperNode: DoneNode?
        for subNode in node.subNodes {
            if let oldNode = self.visitNode(subNode, findOldNode) {
                if node.optWidget == nil && oldNode.spec.widgetClass() == node.spec.widgetClass() {
                    node.optWidget = oldNode.widget
                    oldSuperNode = oldNode.superNode
                }
            }
        }
        if node.optWidget == nil {
            if let oldNode = findOldNode(node) {
                self.table.remove(oldNode)
                node.optWidget = oldNode.widget
                oldSuperNode = oldNode.superNode
            }
        }
        return oldSuperNode
    }

    private func updateNode(_ session: ApplinSession, _ node: DoneNode) {
        for subNode in node.subNodes {
            self.updateNode(session, subNode)
        }
        let subWidgets = node.subNodes.map({ subNode in subNode.widget })
        // TODO(mleonhard) Find a way to make this type-safe and eliminate the exception.
        try! node.widget.update(session, node.spec, subWidgets)
    }

    func updateAll(_ session: ApplinSession, _ spec: Spec) -> Widget {
        let roughRoot = RoughNode(spec)
        _ = self.visitNode(roughRoot) { node in
            if node.spec.priority() == .focusable, let oldNode = self.table.find(node) {
                if oldNode.widget.isFocused() {
                    return oldNode
                }
            }
            return nil
        }
        _ = self.visitNode(roughRoot, { node in node.spec.priority() == .focusable ? self.table.find(node) : nil })
        _ = self.visitNode(roughRoot, { node in node.spec.priority() == .stateful ? self.table.find(node) : nil })
        _ = self.visitNode(roughRoot, { node in self.table.find(node) })
        let doneRoot = DoneNode(roughRoot)
        self.table.removeAll()
        self.table.insert(doneRoot)
        self.updateNode(session, doneRoot)
        return doneRoot.widget
    }
}
