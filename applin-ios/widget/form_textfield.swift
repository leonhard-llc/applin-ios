import Foundation
import UIKit

struct FormTextfieldData: Equatable, Hashable, WidgetDataProto {
    static let TYP = "form-textfield"
    let allow: ApplinAllow
    let autoCapitalize: ApplinAutoCapitalize?
    let checkRpc: String?
    let initialString: String?
    let label: String
    let maxChars: UInt32?
    let maxLines: UInt32?
    let minChars: UInt32?
    let pageKey: String
    let varName: String

    init(pageKey: String, _ item: JsonItem) throws {
        self.allow = item.optAllow() ?? .all
        self.autoCapitalize = item.optAutoCapitalize()
        self.checkRpc = item.checkRpc
        self.initialString = item.initialString
        self.label = try item.requireLabel()
        self.maxChars = item.maxChars
        self.maxLines = item.maxLines
        self.minChars = item.minChars
        self.pageKey = pageKey
        self.varName = try item.requireVar()
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(FormTextfieldData.TYP)
        item.setAllow(self.allow)
        item.setAutoCapitalize(self.autoCapitalize)
        item.checkRpc = self.checkRpc
        item.initialString = self.initialString
        item.label = self.label
        item.maxChars = self.maxChars
        item.maxLines = self.maxLines
        item.minChars = self.minChars
        item.varName = self.varName
        return item
    }

    func keys() -> [String] {
        ["form-textfield:\(self.varName)"]
    }

    func canTap() -> Bool {
        true
    }

    func tap(_ session: ApplinSession, _ cache: WidgetCache) {
        if let widget = cache.get(self.keys()) as? FormTextfieldWidget {
            widget.textview.becomeFirstResponder()
        }
    }

    func getView(_ session: ApplinSession, _ cache: WidgetCache) -> UIView {
        let widget = cache.remove(self.keys()) as? FormTextfieldWidget ?? FormTextfieldWidget(self.pageKey, self)
        widget.data = self
        cache.putNext(widget)
        return widget.getView(session)
    }

    func vars() -> [(String, Var)] {
        [(self.varName, .string(self.initialString ?? ""))]
    }
}

class FormTextfieldWidget: NSObject, UITextViewDelegate, WidgetProto {
    static let errorImage = UIImage(systemName: "exclamationmark.circle")
    let stack: UIStackView
    //let stackWidthConstraint: NSLayoutConstraint
    let label: UILabel
    let textview: UITextView
    let errorStack: UIStackView
    let errorImageView: UIImageView
    let errorLabel: UILabel
    let pageKey: String
    var data: FormTextfieldData
    var errorMessage: String?
    weak var session: ApplinSession?

    init(_ pageKey: String, _ data: FormTextfieldData) {
        print("FormTextfieldWidget.init(\(data))")
        // TODONT: Don't use a UIView and layout with constraints.  Text fields scrolled into view
        //         will ignore their width constraint.  Use a UIStackView instead.
        self.stack = UIStackView()
        self.stack.translatesAutoresizingMaskIntoConstraints = false
        self.stack.axis = .vertical
        self.stack.alignment = .fill
        self.stack.spacing = 4.0
        self.stack.widthAnchor.constraint(equalToConstant: 100_000.0).withPriority(.defaultHigh).isActive = true

        self.label = UILabel()
        self.label.translatesAutoresizingMaskIntoConstraints = false
        self.label.lineBreakMode = .byWordWrapping
        self.label.numberOfLines = 0
        self.stack.addArrangedSubview(label)

        self.errorStack = UIStackView()
        self.errorStack.translatesAutoresizingMaskIntoConstraints = false
        self.errorStack.axis = .horizontal
        self.errorStack.alignment = .center
        self.errorStack.spacing = 4.0
        self.stack.addArrangedSubview(self.errorStack)

        self.errorImageView = UIImageView(image: Self.errorImage)
        self.errorImageView.translatesAutoresizingMaskIntoConstraints = false
        self.errorImageView.tintColor = .systemRed
        // TODONT: Don't try to size the image by setting its frame size.  The image will
        //         randomly ignore this and get stretched.  Use constraints instead.
        self.errorImageView.heightAnchor.constraint(equalToConstant: 30).isActive = true
        self.errorImageView.widthAnchor.constraint(equalTo: self.errorImageView.heightAnchor).isActive = true
        self.errorStack.addArrangedSubview(self.errorImageView)

        self.errorLabel = UILabel()
        self.errorLabel.translatesAutoresizingMaskIntoConstraints = false
        self.errorLabel.text = errorMessage
        self.errorLabel.lineBreakMode = .byWordWrapping
        self.errorLabel.numberOfLines = 0
        self.errorStack.addArrangedSubview(self.errorLabel)

        self.textview = UITextView()
        self.textview.translatesAutoresizingMaskIntoConstraints = false
        self.textview.isScrollEnabled = false // Resize to fit text.
        self.stack.addArrangedSubview(self.textview)

        self.pageKey = pageKey
        self.data = data
        self.errorMessage = "Error1"
        super.init()
        self.textview.delegate = self
        self.textview.text = self.session?.getStringVar(self.data.varName) ?? self.data.initialString ?? ""
        self.update()
    }

    func keys() -> [String] {
        self.data.keys()
    }

    func update() {
        self.label.text = self.data.label
        switch self.data.allow {
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
        switch self.data.autoCapitalize {
        case .names:
            self.textview.autocapitalizationType = .words
        case .sentences:
            self.textview.autocapitalizationType = .sentences
        case .none:
            self.textview.autocapitalizationType = .none
        }
        if self.data.maxLines == 1 {
        } else {
        }
        if let errorMessage = self.errorMessage {
            self.textview.layer.borderColor = UIColor.systemRed.cgColor
            self.textview.layer.borderWidth = 2.0
            self.textview.layer.cornerRadius = 0.0
            self.errorImageView.isHidden = false
            self.errorLabel.text = errorMessage
            self.errorLabel.isHidden = false
        } else {
            self.textview.layer.borderColor = UIColor.systemGray4.cgColor
            self.textview.layer.borderWidth = 1.0
            self.textview.layer.cornerRadius = 4.0
            self.errorImageView.isHidden = true
            self.errorLabel.isHidden = true
            self.errorLabel.text = nil
        }
    }

    func getView(_ session: ApplinSession) -> UIView {
        self.session = session
        self.update()
        return self.stack
    }

    func adjustHeightInSuperviews() {
        // Look for superview UITableView widgets and make them recalculate heights of visible cells.
        var optView: UIView? = self.textview.superview
        while let view = optView {
            if let tableView = view as? UITableView {
                //tableView.updateConstraints()
                UIView.setAnimationsEnabled(false)
                tableView.beginUpdates()
                tableView.endUpdates()
                UIView.setAnimationsEnabled(true)
            }
            optView = view.superview
        }
    }

    func scrollCaretIntoView() {
        // Look for superview UITableView widgets and make them scroll the caret into view.
        var caretRect = CGRect.zero
        if let textPosition = self.textview.selectedTextRange?.end {
            caretRect = self.textview.caretRect(for: textPosition)
        }
        caretRect.origin.y -= 10.0
        caretRect.size.height += 20.0
        var subView: UIView = self.textview
        var optView: UIView? = self.textview.superview
        while let view = optView {
            caretRect = view.convert(caretRect, from: subView)
            if let tableView = view as? UIScrollView {
                tableView.scrollRectToVisible(caretRect, animated: false)
            }
            subView = view
            optView = view.superview
        }
    }

    // UITextViewDelegate

    func textViewDidChange(_: UITextView) {
        print("textViewDidChange")
        self.adjustHeightInSuperviews()
    }

    func textViewDidChangeSelection(_: UITextView) {
        print("textViewDidChangeSelection")
        Task {
            // Let the UITableView resize first.
            await sleep(ms: 100)
            self.scrollCaretIntoView()
        }
    }
}
