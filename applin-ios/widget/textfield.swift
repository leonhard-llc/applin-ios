import Foundation
import UIKit

struct TextfieldData: Equatable, Hashable, WidgetDataProto {
    static let TYP = "textfield"

    let allow: ApplinAllow
    let autoCapitalize: ApplinAutoCapitalize?
    let initialString: String?
    let maxChars: UInt32?
    let maxLines: UInt32?
    let minChars: UInt32?
    let pageKey: String
    let varName: String

    init(pageKey: String, _ item: JsonItem) throws {
        self.allow = item.optAllow() ?? .all
        self.autoCapitalize = item.optAutoCapitalize()
        self.initialString = item.initialString
        self.maxChars = item.maxChars
        self.maxLines = item.maxLines
        self.minChars = item.minChars
        self.pageKey = pageKey
        self.varName = try item.requireVar()
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(TextfieldData.TYP)
        item.setAllow(self.allow)
        item.setAutoCapitalize(self.autoCapitalize)
        item.initialString = self.initialString
        item.maxChars = self.maxChars
        item.maxLines = self.maxLines
        item.minChars = self.minChars
        item.varName = self.varName
        return item
    }

    func keys() -> [String] {
        ["form-textfield:\(self.varName)"]
    }

    func priority() -> WidgetPriority {
        .focusable
    }

    func subs() -> [WidgetData] {
        []
    }

    func vars() -> [(String, Var)] {
        [(self.varName, .string(self.initialString ?? ""))]
    }

    func widgetClass() -> AnyClass {
        TextfieldWidget.self
    }

    func widget() -> WidgetProto {
        TextfieldWidget(self)
    }
}

class TextfieldWidget: NSObject, UITextViewDelegate, WidgetProto {
    let textview: UITextView
    let constraints = ConstraintSet()
    var initialized = false
    weak var session: ApplinSession?

    init(_ data: TextfieldData) {
        print("TextfieldWidget.init(\(data))")
        // TODONT: Don't use a UIView and layout with constraints.  Text fields scrolled into view
        //         will ignore their width constraint.  Use a UIStackView instead.
        self.textview = UITextView()
        self.textview.translatesAutoresizingMaskIntoConstraints = false
        self.textview.isScrollEnabled = false // Resize to fit text.
        self.textview.font = UIFont.systemFont(ofSize: 20)
        NSLayoutConstraint.activate([self.textview.widthAnchor.constraint(equalToConstant: 100_000.0).withPriority(.defaultLow)])
        super.init()
        self.textview.delegate = self
    }

    func getView() -> UIView {
        self.textview
    }

    func isFocused(_ session: ApplinSession, _ data: WidgetData) -> Bool {
        self.textview.isFirstResponder
    }

    func update(_ session: ApplinSession, _ widgetData: WidgetData, _ subs: [WidgetProto]) throws {
        guard case let .textfield(data) = widgetData else {
            throw "Expected .text got: \(widgetData)"
        }
        self.session = session
        if !self.initialized {
            self.textview.text = session.getStringVar(data.varName) ?? data.initialString ?? ""
            self.initialized = true
        }
        switch data.maxLines {
        case nil, 1:
            NSLayoutConstraint.activate([self.textview.heightAnchor.constraint(greaterThanOrEqualToConstant: 20)])
        default:
            NSLayoutConstraint.activate([self.textview.heightAnchor.constraint(greaterThanOrEqualToConstant: 40)])
        }
        switch data.allow {
        case .all:
            self.textview.keyboardType = .default
        case .ascii:
            self.textview.keyboardType = .default
        case .email:
            self.textview.keyboardType = .emailAddress
        case .numbers:
            self.textview.keyboardType = .numberPad
        case .tel:
            self.textview.keyboardType = .phonePad
        }
        switch data.autoCapitalize {
        case .names:
            self.textview.autocapitalizationType = .words
        case .sentences:
            self.textview.autocapitalizationType = .sentences
        case nil:
            self.textview.autocapitalizationType = .none
        }
        self.textview.layer.borderColor = UIColor.systemGray4.cgColor
        self.textview.layer.borderWidth = 1.0
        self.textview.layer.cornerRadius = 4.0
        self.textview.reloadInputViews()
    }
}