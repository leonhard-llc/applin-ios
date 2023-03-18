import Foundation
import UIKit

struct TextfieldSpec: Equatable, Hashable, ToSpec {
    static let TYP = "textfield"

    let allow: ApplinAllow?
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

    init(
            pageKey: String,
            varName: String,
            allow: ApplinAllow? = nil,
            autoCapitalize: ApplinAutoCapitalize? = nil,
            error: String? = nil,
            initialString: String? = nil,
            label: String? = nil,
            maxChars: UInt32? = nil,
            maxLines: UInt32? = nil,
            minChars: UInt32? = nil,
            rpc: String? = nil
    ) throws {
        self.allow = allow
        self.autoCapitalize = autoCapitalize
        self.error = error
        self.initialString = initialString
        self.label = label
        self.maxChars = maxChars
        self.maxLines = maxLines
        self.minChars = minChars
        self.pageKey = pageKey
        self.rpc = rpc
        self.varName = varName
    }

    func toSpec() -> Spec {
        Spec(.textfield(self))
    }

    func keys() -> [String] {
        ["textfield:\(self.varName)"]
    }

    func keyboardType() -> UIKeyboardType {
        self.allow?.keyboardType() ?? .default
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
    let label: Label
    let errorView: ErrorView!
    let textview: UITextView
    let toolbar: UIToolbar
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

        self.label = Label()
        self.label.translatesAutoresizingMaskIntoConstraints = false
        self.label.lineBreakMode = .byWordWrapping
        self.label.numberOfLines = 0

        self.errorView = ErrorView()
        self.errorView.translatesAutoresizingMaskIntoConstraints = false
        self.errorView.text = spec.error

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

        // https://stackoverflow.com/a/28339340
        self.toolbar = UIToolbar(frame: CGRect.init(x: 0, y: 0, width: 0, height: 200))

        super.init()
        self.textview.delegate = self
        self.container.onTap = { [weak self] in
            self?.textview.becomeFirstResponder()
        }

        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(
                barButtonSystemItem: UIBarButtonItem.SystemItem.done,
                target: self /* Selector targets are weak references. */,
                action: #selector(self.doneButtonPressed)
        )
        self.toolbar.items = [flexSpace, doneButton]
        self.toolbar.sizeToFit()
        self.textview.inputAccessoryView = self.toolbar

        NSLayoutConstraint.activate([
            self.container.widthAnchor.constraint(equalToConstant: 100_000.0).withPriority(.fittingSizeLevel),
            self.textview.widthAnchor.constraint(equalToConstant: 100_000.0).withPriority(.defaultHigh),
            self.textview.leftAnchor.constraint(equalTo: self.container.leftAnchor, constant: 4.0),
            self.textview.rightAnchor.constraint(equalTo: self.container.rightAnchor, constant: -4.0),
            self.textview.bottomAnchor.constraint(equalTo: self.container.bottomAnchor, constant: -4.0),
        ])
    }

    func getView() -> UIView {
        self.container
    }

    func isFocused() -> Bool {
        self.textview.isFirstResponder
    }

    @objc
    func doneButtonPressed() {
        print("Done button pressed")
        self.textview.resignFirstResponder()
    }

    func update(_ session: ApplinSession, _ state: ApplinState, _ spec: Spec, _ subs: [Widget]) throws {
        guard case let .textfield(textfieldSpec) = spec.value else {
            throw "Expected .text got: \(spec)"
        }
        if !subs.isEmpty {
            throw "Expected no subs got: \(subs)"
        }
        print("TextfieldWidget.update(\(textfieldSpec))")
        self.spec = textfieldSpec
        self.session = session
        if !self.initialized {
            self.textview.text = state.getStringVar(self.spec.varName) ?? self.spec.initialString ?? ""
            self.initialized = true
        }
        var constraints: [NSLayoutConstraint] = []
        var prevBottomAnchor: NSLayoutYAxisAnchor = self.container.topAnchor
        // Label
        if let labelString = self.spec.label {
            self.label.text = labelString
            self.container.addSubview(self.label)
            constraints.append(contentsOf: [
                self.label.topAnchor.constraint(equalTo: prevBottomAnchor, constant: 8.0),
                self.label.leftAnchor.constraint(equalTo: self.container.leftAnchor, constant: 8.0),
                self.label.rightAnchor.constraint(equalTo: self.container.rightAnchor, constant: -8.0),
            ])
            prevBottomAnchor = self.label.bottomAnchor
        } else {
            self.label.removeFromSuperview()
        }
        // Error image and label
        // TODO: Scroll textview into view after error appears or gets longer.
        if let errorString = self.spec.error {
            self.textview.layer.borderColor = UIColor.systemRed.cgColor
            self.textview.layer.borderWidth = TextfieldWidget.BORDER_WIDTH * 2.0
            self.textview.layer.cornerRadius = 0.0
            self.errorView.text = errorString
            self.container.addSubview(self.errorView)
            constraints.append(contentsOf: [
                self.errorView.topAnchor.constraint(greaterThanOrEqualTo: prevBottomAnchor),
                self.errorView.leftAnchor.constraint(equalTo: self.container.leftAnchor, constant: 4.0),
                self.errorView.rightAnchor.constraint(equalTo: self.container.rightAnchor, constant: -4.0),
            ])
            prevBottomAnchor = self.errorView.bottomAnchor
        } else {
            self.textview.layer.borderColor = TextfieldWidget.BORDER_COLOR.cgColor
            self.textview.layer.borderWidth = TextfieldWidget.BORDER_WIDTH
            self.textview.layer.cornerRadius = TextfieldWidget.CORNER_RADIUS
            self.errorView.text = nil
            self.errorView.removeFromSuperview()
        }

        // Textview
        constraints.append(self.textview.topAnchor.constraint(greaterThanOrEqualTo: prevBottomAnchor, constant: 4.0))
        switch self.spec.maxLines {
        case nil, 1:
            constraints.append(self.textview.heightAnchor.constraint(greaterThanOrEqualToConstant: 20))
        default:
            constraints.append(self.textview.heightAnchor.constraint(greaterThanOrEqualToConstant: 40))
        }
        let keyboardTypeChanged = self.textview.keyboardType != self.spec.keyboardType()
        if keyboardTypeChanged {
            print("TextfieldWidget(\(self.spec.varName) keyboardType changed \(self.textview.keyboardType) -> \(self.spec.keyboardType())")
            self.textview.keyboardType = self.spec.keyboardType()
        }
        let newAutocapType = self.spec.autoCapitalize?.textAutocapitalizationType() ?? .none
        let autocapTypeChanged = self.textview.autocapitalizationType != newAutocapType
        if autocapTypeChanged {
            print("TextfieldWidget(\(self.spec.varName) autocapitalizationType changed \(self.textview.autocapitalizationType) -> \(newAutocapType)")
            self.textview.autocapitalizationType = newAutocapType
        }
        if keyboardTypeChanged || autocapTypeChanged {
            print("TextfieldWidget(\(self.spec.varName) reloadInputViews()")
            self.textview.reloadInputViews()
        }
        self.constraintSet.set(constraints)
    }

    // UITextViewDelegate

    func textViewDidChange(_: UITextView) {
        //print("textViewDidChange")
        self.session?.mutex.lock({ state in
            state.setStringVar(self.spec.varName, self.textview.text.isEmpty ? nil : self.textview.text)
        })
        if let rpcPath = self.spec.rpc {
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
                do {
                    _ = try await self.session?.rpcCaller?.rpc(optPageKey: self.spec.pageKey, path: rpcPath, method: "POST")
                } catch let e as ApplinError {
                    print("TextField rpc error: \(e)")
                } catch let e {
                    print("TextField rpc unexpected error: \(e)")
                }
            }
        }
    }
}
