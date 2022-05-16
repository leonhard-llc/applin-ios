import Foundation
import SwiftUI

enum ModalKind: String {
    case Alert
    case Info
    case Question

    public func typ() -> String {
        switch self {
        case .Alert:
            return "alert-modal"
        case .Info:
            return "info-modal"
        case .Question:
            return "question-modal"
        }
    }
}

struct MaggieModal: Equatable {
    static func ==(lhs: MaggieModal, rhs: MaggieModal) -> Bool {
        return lhs.title == rhs.title
                && lhs.widgets == rhs.widgets
    }

    let kind: ModalKind
    let typ: String
    let title: String
    let widgets: [MaggieWidget]
    @State var isPresented = true

    enum CodingKeys: String, CodingKey {
        // case kind
        case typ
        case title
        case widgets
        // case isPresented
    }

    init(_ kind: ModalKind, title: String, _ widgets: [MaggieWidget]) {
        self.kind = kind
        self.typ = kind.typ()
        self.title = title
        self.widgets = widgets
    }

    init(_ kind: ModalKind, _ item: JsonItem, _ session: MaggieSession) throws {
        self.kind = kind
        self.typ = kind.typ()
        self.title = try item.takeTitle()
        self.widgets = try item.takeWidgets(session)
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(self.kind.typ())
        item.title = self.title
        item.widgets = self.widgets.map({ widgets in widgets.toJsonItem() })
        return item
    }

    public func toView() -> AnyView {
        switch self.kind {
        case .Alert:
            return AnyView(
                    EmptyView().alert(self.title, isPresented: self.$isPresented) {
                        ForEach(self.widgets) {
                            widget in
                            widget
                        }
                    }
            )
        case .Info, .Question:
            return AnyView(
                    EmptyView().confirmationDialog(self.title, isPresented: self.$isPresented) {
                        ForEach(self.widgets) {
                            widget in
                            widget
                        }
                    }
            )
        }
    }
}
