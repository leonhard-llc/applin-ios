import Foundation
import UIKit

struct TextfieldSpec: Equatable, Hashable {
    static let TYP = "textfield"

    let allow: ApplinAllow
    let autoCapitalize: ApplinAutoCapitalize?
    let error: String?
    let initialString: String?
    let label: String?
    let maxChars: UInt32?
    let maxLines: UInt32?
    let minChars: UInt32?
    let pageKey: String
    let rpc: String?
    let varName: String

    init(pageKey: String, _ item: JsonItem) throws {
        self.allow = item.optAllow() ?? .all
        self.autoCapitalize = item.optAutoCapitalize()
        self.error = item.error
        self.initialString = item.initialString
        self.label = item.label
        self.maxChars = item.maxChars
        self.maxLines = item.maxLines
        self.minChars = item.minChars
        self.pageKey = pageKey
        self.rpc = item.rpc
        self.varName = try item.requireVar()
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(TextfieldSpec.TYP)
        item.setAllow(self.allow)
        item.setAutoCapitalize(self.autoCapitalize)
        item.error = self.error
        item.initialString = self.initialString
        item.label = self.label
        item.maxChars = self.maxChars
        item.maxLines = self.maxLines
        item.minChars = self.minChars
        item.rpc = self.rpc
        item.varName = self.varName
        return item
    }

    func keys() -> [String] {
        ["textfield:\(self.varName)"]
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

    func newWidget() -> Widget {
        TextfieldWidget(self)
    }
}

class TextfieldWidget: NSObject, UITextViewDelegate, Widget {
    static let BORDER_COLOR: UIColor = UIColor.label
    static let BORDER_WIDTH: CGFloat = 0.7
    static let CORNER_RADIUS: CGFloat = 10.0
    static let ERROR_IMAGE = UIImage(systemName: "exclamationmark.circle")
    let container: TappableView
    let label: UILabel
    let textview: UITextView
    let errorImageView: UIImageView
    let errorLabel: UILabel
    let constraintSet = ConstraintSet()
    var spec: TextfieldSpec
    weak var session: ApplinSession?
    var initialized = false

    private let lock = NSLock()
    private var rpcTask: Task<Void, Never>?

    init(_ spec: TextfieldSpec) {
        print("TextfieldWidget.init(\(spec))")
        self.spec = spec

        self.container = TappableView()
        self.container.translatesAutoresizingMaskIntoConstraints = false
        //self.container.backgroundColor = pastelPink

        self.label = UILabel()
        self.label.translatesAutoresizingMaskIntoConstraints = false
        self.label.lineBreakMode = .byWordWrapping
        self.label.numberOfLines = 0

        self.errorImageView = UIImageView(image: Self.ERROR_IMAGE)
        self.errorImageView.translatesAutoresizingMaskIntoConstraints = false
        self.errorImageView.tintColor = .systemRed

        self.errorLabel = UILabel()
        self.errorLabel.translatesAutoresizingMaskIntoConstraints = false
        self.errorLabel.lineBreakMode = .byWordWrapping
        self.errorLabel.numberOfLines = 0

        self.textview = UITextView()
        self.textview.translatesAutoresizingMaskIntoConstraints = false
        self.textview.isScrollEnabled = false // Resize to fit text.
        self.textview.font = UIFont.systemFont(ofSize: 20)
        self.textview.layer.borderColor = Self.BORDER_COLOR.cgColor
        self.textview.layer.borderWidth = Self.BORDER_WIDTH
        self.textview.layer.cornerRadius = Self.CORNER_RADIUS
        // A tinted rectangle looks better, but has lower contrast:
        //self.textview.layer.backgroundColor = UIColor.systemGray6.cgColor
        self.container.addSubview(textview)
        NSLayoutConstraint.activate([
            self.container.widthAnchor.constraint(equalToConstant: 100_000.0).withPriority(.fittingSizeLevel),
            self.textview.widthAnchor.constraint(equalToConstant: 100_000.0).withPriority(.defaultHigh),
            self.textview.leftAnchor.constraint(equalTo: self.container.leftAnchor, constant: 4.0),
            self.textview.rightAnchor.constraint(equalTo: self.container.rightAnchor, constant: -4.0),
        ])
        super.init()
        self.textview.delegate = self
        self.container.onTap = { [weak self] in
            self?.textview.becomeFirstResponder()
        }
    }

    func getView() -> UIView {
        self.container
    }

    func isFocused() -> Bool {
        self.textview.isFirstResponder
    }

    func update(_ session: ApplinSession, _ spec: Spec, _ subs: [Widget]) throws {
        guard case let .textfield(textfieldSpec) = spec.value else {
            throw "Expected .text got: \(spec)"
        }
        if !subs.isEmpty {
            throw "Expected no subs got: \(subs)"
        }
        self.session = session
        if !self.initialized {
            self.textview.text = session.getStringVar(textfieldSpec.varName) ?? textfieldSpec.initialString ?? ""
            self.initialized = true
        }
        var constraints: [NSLayoutConstraint] = []
        // Label
        if let labelString = self.spec.label {
            self.label.text = labelString
            self.container.addSubview(self.label)
            constraints.append(contentsOf: [
                self.label.topAnchor.constraint(equalTo: self.container.topAnchor, constant: 8.0),
                self.label.leftAnchor.constraint(equalTo: self.container.leftAnchor, constant: 8.0),
                self.label.rightAnchor.constraint(equalTo: self.container.rightAnchor, constant: -8.0),
                self.textview.topAnchor.constraint(greaterThanOrEqualTo: self.label.bottomAnchor, constant: 4.0),
            ])
        } else {
            self.label.removeFromSuperview()
            constraints.append(self.textview.topAnchor.constraint(equalTo: self.container.topAnchor, constant: 4.0))
        }
        // Textview
        switch textfieldSpec.maxLines {
        case nil, 1:
            constraints.append(self.textview.heightAnchor.constraint(greaterThanOrEqualToConstant: 20))
        default:
            constraints.append(self.textview.heightAnchor.constraint(greaterThanOrEqualToConstant: 40))
        }
        let keyboardTypeChanged = self.textview.keyboardType != textfieldSpec.allow.keyboardType()
        if keyboardTypeChanged {
            print("TextfieldWidget(\(textfieldSpec.varName) keyboardType changed \(self.textview.keyboardType) -> \(textfieldSpec.allow.keyboardType())")
            self.textview.keyboardType = textfieldSpec.allow.keyboardType()
        }
        let newAutocapType = textfieldSpec.autoCapitalize?.textAutocapitalizationType() ?? .none
        let autocapTypeChanged = self.textview.autocapitalizationType != newAutocapType
        if autocapTypeChanged {
            print("TextfieldWidget(\(textfieldSpec.varName) autocapitalizationType changed \(self.textview.autocapitalizationType) -> \(newAutocapType)")
            self.textview.autocapitalizationType = newAutocapType
        }
        if keyboardTypeChanged || autocapTypeChanged {
            print("TextfieldWidget(\(textfieldSpec.varName) reloadInputViews()")
            self.textview.reloadInputViews()
        }
        // Error image and label
        if let errorString = self.spec.error {
            self.textview.layer.borderColor = UIColor.systemRed.cgColor
            self.textview.layer.borderWidth = TextfieldWidget.BORDER_WIDTH * 2.0
            self.textview.layer.cornerRadius = 0.0
            self.errorLabel.text = errorString
            self.container.addSubview(self.errorImageView)
            self.container.addSubview(self.errorLabel)
            NSLayoutConstraint.activate([
                // TODONT: Don't try to size the image by setting its frame size.  The image will
                //         randomly ignore this and get stretched.  Use constraints instead.
                self.errorImageView.heightAnchor.constraint(equalToConstant: 30),
                self.errorImageView.widthAnchor.constraint(equalTo: self.errorImageView.heightAnchor),

                self.errorImageView.topAnchor.constraint(greaterThanOrEqualTo: self.textview.bottomAnchor, constant: 4.0),
                self.errorImageView.leftAnchor.constraint(equalTo: self.container.leftAnchor, constant: 4.0),
                self.errorImageView.bottomAnchor.constraint(lessThanOrEqualTo: self.container.bottomAnchor, constant: -4.0),

                self.errorLabel.topAnchor.constraint(greaterThanOrEqualTo: self.textview.bottomAnchor, constant: 4.0),
                self.errorLabel.leftAnchor.constraint(equalTo: self.errorImageView.rightAnchor, constant: 4.0),
                self.errorLabel.rightAnchor.constraint(equalTo: self.container.rightAnchor, constant: -4.0),
                self.errorLabel.centerYAnchor.constraint(equalTo: self.errorImageView.centerYAnchor),
                self.errorLabel.bottomAnchor.constraint(lessThanOrEqualTo: self.container.bottomAnchor, constant: -4.0),
            ])
        } else {
            self.textview.layer.borderColor = TextfieldWidget.BORDER_COLOR.cgColor
            self.textview.layer.borderWidth = TextfieldWidget.BORDER_WIDTH
            self.textview.layer.cornerRadius = TextfieldWidget.CORNER_RADIUS
            self.errorLabel.text = nil
            self.errorImageView.removeFromSuperview()
            self.errorLabel.removeFromSuperview()
            constraints.append(self.textview.bottomAnchor.constraint(equalTo: self.container.bottomAnchor, constant: -4.0))
        }
        self.constraintSet.set(constraints)
    }

    // UITextViewDelegate

    func textViewDidChange(_: UITextView) {
        //print("textViewDidChange")
        self.session?.setStringVar(self.spec.varName, self.textview.text.isEmpty ? nil : self.textview.text)
        if let rpc = self.spec.rpc {
            self.lock.lock()
            defer {
                self.lock.unlock()
            }
            self.rpcTask?.cancel()
            self.rpcTask = Task { @MainActor in
                await sleep(ms: 3_000)
                if Task.isCancelled {
                    return
                }
                let _ = await self.session?.doActionsAsync(pageKey: self.spec.pageKey, [.rpc(rpc)])
            }
        }
    }
}
