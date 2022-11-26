import Foundation
import UIKit

struct FormTextfieldData: Equatable, Hashable {
    static let TYP = "form-textfield"
    let checkRpc: String?
    let label: String
    let pageKey: String
    let textfieldData: TextfieldData

    init(pageKey: String, _ item: JsonItem) throws {
        self.checkRpc = item.checkRpc
        self.label = try item.requireLabel()
        self.pageKey = pageKey
        self.textfieldData = try TextfieldData(pageKey: pageKey, item)
    }

    func toJsonItem() -> JsonItem {
        let item = self.textfieldData.toJsonItem()
        item.typ = FormTextfieldData.TYP
        item.checkRpc = self.checkRpc
        item.label = self.label
        return item
    }

    func keys() -> [String] {
        ["form-textfield:\(self.textfieldData.varName)"]
    }

    func priority() -> WidgetPriority {
        .focusable
    }

    func subs() -> [Spec] {
        []
    }

    func widgetClass() -> AnyClass {
        FormTextfieldWidget.self
    }

    func widget() -> WidgetProto {
        FormTextfieldWidget(self)
    }

    func vars() -> [(String, Var)] {
        [(self.textfieldData.varName, .string(self.textfieldData.initialString ?? ""))]
    }
}

class FormTextfieldWidget: WidgetProto {
    static let errorImage = UIImage(systemName: "exclamationmark.circle")
    let container: TappableView
    let label: UILabel
    let textfieldWidget: TextfieldWidget
    let errorImageView: UIImageView
    let errorLabel: UILabel
    let constraintSet = ConstraintSet()
    var data: FormTextfieldData
    weak var session: ApplinSession?
    var errorMessage: String?

    init(_ data: FormTextfieldData) {
        print("FormTextfieldWidget.init(\(data))")
        self.container = TappableView()
        self.container.translatesAutoresizingMaskIntoConstraints = false
        //self.container.backgroundColor = pastelPink

        self.label = UILabel()
        self.label.translatesAutoresizingMaskIntoConstraints = false
        self.label.lineBreakMode = .byWordWrapping
        self.label.numberOfLines = 0
        self.container.addSubview(label)

        self.errorImageView = UIImageView(image: Self.errorImage)
        self.errorImageView.translatesAutoresizingMaskIntoConstraints = false
        self.errorImageView.tintColor = .systemRed
        self.container.addSubview(self.errorImageView)

        self.errorLabel = UILabel()
        self.errorLabel.translatesAutoresizingMaskIntoConstraints = false
        self.errorLabel.lineBreakMode = .byWordWrapping
        self.errorLabel.numberOfLines = 0
        self.container.addSubview(self.errorLabel)

        self.textfieldWidget = TextfieldWidget(data.textfieldData)
        let textfield = self.textfieldWidget.getView()
        self.container.addSubview(textfield)

        NSLayoutConstraint.activate([
            self.container.widthAnchor.constraint(equalToConstant: 100_000.0).withPriority(.defaultLow),

            self.label.topAnchor.constraint(equalTo: self.container.topAnchor, constant: 8.0),
            self.label.leftAnchor.constraint(equalTo: self.container.leftAnchor, constant: 8.0),
            self.label.rightAnchor.constraint(equalTo: self.container.rightAnchor, constant: -8.0),

            // TODONT: Don't try to size the image by setting its frame size.  The image will
            //         randomly ignore this and get stretched.  Use constraints instead.
            self.errorImageView.heightAnchor.constraint(equalToConstant: 30),
            self.errorImageView.widthAnchor.constraint(equalTo: self.errorImageView.heightAnchor),

            textfield.topAnchor.constraint(greaterThanOrEqualTo: self.label.bottomAnchor, constant: 4.0),
            textfield.leftAnchor.constraint(equalTo: self.container.leftAnchor, constant: 4.0),
            textfield.rightAnchor.constraint(equalTo: self.container.rightAnchor, constant: -4.0),
            textfield.bottomAnchor.constraint(equalTo: self.container.bottomAnchor, constant: -4.0),
        ])

        self.data = data
        //self.errorMessage = "Error1"
        self.container.onTap = { [weak self] in
            self?.textfieldWidget.getView().becomeFirstResponder()
        }
        // TODO: Register onChanged callback and do checkRpc.
    }

    func keys() -> [String] {
        self.data.keys()
    }

    func getView() -> UIView {
        self.container
    }

    func isFocused() -> Bool {
        self.textfieldWidget.getView().isFocused
    }

    func update(_ session: ApplinSession, _ spec: Spec, _ subs: [WidgetProto]) throws {
        guard case let .formTextfield(data) = spec.value else {
            throw "Expected .text got: \(spec)"
        }
        if !subs.isEmpty {
            throw "Expected no subs got: \(subs)"
        }
        self.data = data
        self.session = session
        self.label.text = self.data.label
        try self.textfieldWidget.update(session, Spec(.textfield(self.data.textfieldData)), [])
        let textfield = self.textfieldWidget.getView()
        if let errorMessage = self.errorMessage {
            self.errorImageView.isHidden = false
            self.errorLabel.isHidden = false
            self.errorLabel.text = errorMessage
            constraintSet.set([
                self.errorImageView.topAnchor.constraint(greaterThanOrEqualTo: self.label.bottomAnchor, constant: 4.0),
                self.errorImageView.leftAnchor.constraint(equalTo: self.container.leftAnchor, constant: 4.0),
                self.errorImageView.bottomAnchor.constraint(lessThanOrEqualTo: textfield.topAnchor, constant: -4.0),

                self.errorLabel.topAnchor.constraint(greaterThanOrEqualTo: self.label.bottomAnchor, constant: 4.0),
                self.errorLabel.leftAnchor.constraint(equalTo: self.errorImageView.rightAnchor, constant: 4.0),
                self.errorLabel.rightAnchor.constraint(equalTo: self.container.rightAnchor, constant: -4.0),
                self.errorLabel.centerYAnchor.constraint(equalTo: self.errorImageView.centerYAnchor),
                self.errorLabel.bottomAnchor.constraint(lessThanOrEqualTo: textfield.topAnchor, constant: -4.0),
            ])
            textfield.layer.borderColor = UIColor.systemRed.cgColor
            textfield.layer.borderWidth = TextfieldWidget.BORDER_WIDTH * 2.0
            textfield.layer.cornerRadius = 0.0
        } else {
            self.errorImageView.isHidden = true
            self.errorLabel.isHidden = true
            self.errorLabel.text = nil
            constraintSet.set([])
            textfield.layer.borderColor = TextfieldWidget.BORDER_COLOR.cgColor
            textfield.layer.borderWidth = TextfieldWidget.BORDER_WIDTH
            textfield.layer.cornerRadius = TextfieldWidget.CORNER_RADIUS
        }
    }
}
