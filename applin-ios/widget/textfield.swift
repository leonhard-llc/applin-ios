import Foundation
import UIKit

struct TextfieldData: Equatable, Hashable {
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

    func subs() -> [Spec] {
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
    static let BORDER_COLOR: UIColor = UIColor.label
    static let BORDER_WIDTH: CGFloat = 0.7
    static let CORNER_RADIUS: CGFloat = 10.0
    let textview: UITextView
    let constraints = ConstraintSet()
    var initialized = false
    weak var session: ApplinSession?
    var data: TextfieldData

    init(_ data: TextfieldData) {
        print("TextfieldWidget.init(\(data))")
        self.data = data
        // TODONT: Don't use a UIView and layout with constraints.  Text fields scrolled into view
        //         will ignore their width constraint.  Use a UIStackView instead.
        self.textview = UITextView()
        self.textview.translatesAutoresizingMaskIntoConstraints = false
        self.textview.isScrollEnabled = false // Resize to fit text.
        self.textview.font = UIFont.systemFont(ofSize: 20)
        NSLayoutConstraint.activate([self.textview.widthAnchor.constraint(equalToConstant: 100_000.0).withPriority(.defaultHigh)])
        super.init()
        self.textview.delegate = self
        self.textview.layer.borderColor = Self.BORDER_COLOR.cgColor
        self.textview.layer.borderWidth = Self.BORDER_WIDTH
        self.textview.layer.cornerRadius = Self.CORNER_RADIUS
        // A tinted rectangle looks better, but has lower contrast:
        //self.textview.layer.backgroundColor = UIColor.systemGray6.cgColor
    }

    func getView() -> UIView {
        self.textview
    }

    func isFocused(_ session: ApplinSession, _ data: Spec) -> Bool {
        self.textview.isFirstResponder
    }

    func update(_ session: ApplinSession, _ spec: Spec, _ subs: [WidgetProto]) throws {
        guard case let .textfield(data) = spec.value else {
            throw "Expected .text got: \(spec)"
        }
        if !subs.isEmpty {
            throw "Expected no subs got: \(subs)"
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

        //self.textview.keyboardType = data.allow.keyboardType()
        //self.textview.autocapitalizationType = data.autoCapitalize?.textAutocapitalizationType() ?? .none
        //self.textview.layer.borderColor = UIColor.systemGray4.cgColor
        //self.textview.layer.borderWidth = 1.0
        //self.textview.layer.cornerRadius = 4.0
        //self.textview.reloadInputViews()
        let keyboardTypeChanged = self.textview.keyboardType != data.allow.keyboardType()
        if keyboardTypeChanged {
            print("TextfieldWidget(\(data.varName) keyboardType changed \(self.textview.keyboardType) -> \(data.allow.keyboardType())")
            self.textview.keyboardType = data.allow.keyboardType()
        }
        let newAutocapType = data.autoCapitalize?.textAutocapitalizationType() ?? .none
        let autocapTypeChanged = self.textview.autocapitalizationType != newAutocapType
        if autocapTypeChanged {
            print("TextfieldWidget(\(data.varName) autocapitalizationType changed \(self.textview.autocapitalizationType) -> \(newAutocapType)")
            self.textview.autocapitalizationType = newAutocapType
        }
        if keyboardTypeChanged || autocapTypeChanged {
            print("TextfieldWidget(\(data.varName) reloadInputViews()")
            self.textview.reloadInputViews()
        }
    }

    // UITextViewDelegate

    func textViewDidChange(_: UITextView) {
        //print("textViewDidChange")
        self.session?.setStringVar(self.data.varName, self.textview.text.isEmpty ? nil : self.textview.text)
    }
}
