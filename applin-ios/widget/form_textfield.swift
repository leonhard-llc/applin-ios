import Foundation
import UIKit

// TODO: Finish.

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
            widget.textfield.becomeFirstResponder()
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

class FormTextfieldWidget: NSObject, UITextFieldDelegate, WidgetProto {
    static let errorImage = UIImage(systemName: "exclamationmark.circle")
    let stack: UIStackView
    //let stackWidthConstraint: NSLayoutConstraint
    let label: UILabel
    let textfield: UITextField
    let errorStack: UIStackView
    let errorImageView: UIImageView
    let errorLabel: UILabel
    let defaultBorderColor: CGColor?
    let defaultBorderWidth: CGFloat
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

        self.textfield = UITextField()
        self.textfield.translatesAutoresizingMaskIntoConstraints = false
        self.textfield.text = "Hello"
        self.textfield.borderStyle = .roundedRect
        self.stack.addArrangedSubview(self.textfield)

        self.defaultBorderColor = self.textfield.layer.borderColor
        self.defaultBorderWidth = self.textfield.layer.borderWidth
        self.pageKey = pageKey
        self.data = data
        self.errorMessage = "Error1"
        super.init()
        self.textfield.delegate = self
        self.update()
    }

    func keys() -> [String] {
        self.data.keys()
    }

    func update() {
        print("update")
        self.label.text = self.data.label
        switch self.data.allow {
        case .all:
            self.textfield.keyboardType = .default
        case .ascii:
            self.textfield.keyboardType = .default
        case .email:
            self.textfield.keyboardType = .emailAddress
        case .numbers:
            self.textfield.keyboardType = .numberPad
        case .tel:
            self.textfield.keyboardType = .phonePad
        }
        switch self.data.autoCapitalize {
        case .names:
            self.textfield.autocapitalizationType = .words
        case .sentences:
            self.textfield.autocapitalizationType = .sentences
        case .none:
            self.textfield.autocapitalizationType = .none
        }
        if self.data.maxLines == 1 {
            self.textfield.clearButtonMode = .always
        } else {
            self.textfield.clearButtonMode = .never
        }
        if let errorMessage = self.errorMessage {
            self.textfield.layer.borderColor = UIColor.systemRed.cgColor
            self.textfield.layer.borderWidth = 2.0
            self.errorImageView.isHidden = false
            self.errorLabel.text = errorMessage
            self.errorLabel.isHidden = false
        } else {
            self.textfield.layer.borderColor = self.defaultBorderColor
            self.textfield.layer.borderWidth = self.defaultBorderWidth
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

    // UITextFieldDelegate

}
