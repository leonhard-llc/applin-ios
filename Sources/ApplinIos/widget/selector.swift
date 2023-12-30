import Foundation
import OSLog
import UIKit

public struct SelectorSpec: Equatable, Hashable, ToSpec {
    static let TYP = "selector"

    let error: String?
    let initialString: String?
    let initialString1: String?
    let initialString2: String?
    let label: String?
    let options: [String]?
    let options1: [String]?
    let options2: [String]?
    let pollDelayMs: UInt32?
    let varName: String
    let varName1: String?
    let varName2: String?

    public init(
            varName: String,
            varName1: String? = nil,
            varName2: String? = nil,
            error: String? = nil,
            initialString: String? = nil,
            initialString1: String? = nil,
            initialString2: String? = nil,
            label: String? = nil,
            options: [String]? = nil,
            options1: [String]? = nil,
            options2: [String]? = nil,
            pollDelayMs: UInt32? = nil
    ) throws {
        self.error = error
        self.initialString = initialString
        self.initialString1 = initialString1
        self.initialString2 = initialString2
        self.label = label
        self.options = options
        self.options1 = options1
        self.options2 = options2
        self.pollDelayMs = pollDelayMs
        self.varName = varName
        self.varName1 = varName1
        self.varName2 = varName2
    }

    init(_ item: JsonItem) throws {
        self.error = item.error
        self.initialString = item.initial_string
        self.initialString1 = item.initial_string1
        self.initialString2 = item.initial_string2
        self.label = item.label
        self.options = item.options
        self.options1 = item.options1
        self.options2 = item.options2
        self.pollDelayMs = item.poll_delay_ms
        self.varName = try item.requireVar()
        self.varName1 = item.var_name1
        self.varName2 = item.var_name2
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(SelectorSpec.TYP)
        item.error = self.error
        item.initial_string = self.initialString
        item.initial_string1 = self.initialString1
        item.initial_string2 = self.initialString2
        item.label = self.label
        item.options = self.options
        item.options1 = self.options1
        item.options2 = self.options2
        item.poll_delay_ms = self.pollDelayMs
        item.var_name = self.varName
        item.var_name1 = self.varName1
        item.var_name2 = self.varName2
        return item
    }

    public func toSpec() -> Spec {
        Spec(.selector(self))
    }

    func keys() -> [String] {
        ["selector:\(self.varName)"]
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
        SelectorWidget.self
    }

    func newWidget(_ ctx: PageContext) -> Widget {
        SelectorWidget(ctx, self)
    }

    func visitActions(_ f: (ActionSpec) -> ()) {
    }
}

class SelectorWidget: NSObject, UIPickerViewDataSource, UIPickerViewDelegate, Widget {
    static let ERROR_IMAGE = UIImage(systemName: "exclamationmark.circle")
    static let logger = Logger(subsystem: "Applin", category: "SelectorWidget")
    let container: UIView
    let label: Label
    let errorView: ErrorView!
    let pickerView: UIPickerView
    let constraintSet = ConstraintSet()
    let ctx: PageContext
    var spec: SelectorSpec

    init(_ ctx: PageContext, _ spec: SelectorSpec) {
        self.ctx = ctx
        self.spec = spec

        self.container = UIView()
        self.container.translatesAutoresizingMaskIntoConstraints = false
        //self.container.backgroundColor = pastelPink

        self.label = Label()
        self.label.translatesAutoresizingMaskIntoConstraints = false
        self.label.lineBreakMode = .byWordWrapping
        self.label.numberOfLines = 0

        self.errorView = ErrorView()
        self.errorView.translatesAutoresizingMaskIntoConstraints = false
        self.errorView.text = spec.error

        self.pickerView = UIPickerView()
        self.pickerView.translatesAutoresizingMaskIntoConstraints = false
        self.pickerView.layer.borderWidth = 1.4
        self.container.addSubview(pickerView)

        super.init()
        self.pickerView.dataSource = self
        self.pickerView.delegate = self
        if let initial = ctx.varSet?.string(self.spec.varName) ?? self.spec.initialString,
           let row = self.spec.options?.firstIndex(of: initial) {
            self.pickerView.selectRow(row, inComponent: 0, animated: false)
        }
        if let varName = self.spec.varName1,
           let initial = ctx.varSet?.string(varName) ?? self.spec.initialString1,
           let row = self.spec.options1?.firstIndex(of: initial) {
            self.pickerView.selectRow(row, inComponent: 1, animated: false)
        }
        if let varName = self.spec.varName2,
           let initial = ctx.varSet?.string(varName) ?? self.spec.initialString2,
           let row = self.spec.options2?.firstIndex(of: initial) {
            self.pickerView.selectRow(row, inComponent: 2, animated: false)
        }

        NSLayoutConstraint.activate([
            // TODO: Fix error "[LayoutConstraints] Unable to simultaneously satisfy constraints."
            self.pickerView.widthAnchor.constraint(equalToConstant: 100_000.0).withPriority(.required),
            self.pickerView.leftAnchor.constraint(equalTo: self.container.leftAnchor, constant: 4.0),
            self.pickerView.rightAnchor.constraint(equalTo: self.container.rightAnchor, constant: -4.0),
            self.pickerView.bottomAnchor.constraint(equalTo: self.container.bottomAnchor),
        ])
    }

    func getView() -> UIView {
        self.container
    }

    func isFocused() -> Bool {
        self.pickerView.isFirstResponder
    }

    @objc
    func doneButtonPressed() {
        Self.logger.dbg("varName=\(self.spec.varName) doneButtonPressed")
        self.pickerView.resignFirstResponder()
    }

    func update(_ ctx: PageContext, _ spec: Spec, _ subs: [Widget]) throws {
        guard case let .selector(selectorSpec) = spec.value else {
            throw "Expected .selector got: \(spec)"
        }
        if !subs.isEmpty {
            throw "Expected no subs got: \(subs)"
        }
        Self.logger.dbg("varName=\(self.spec.varName) update spec=\(String(describing: selectorSpec))")
        self.spec = selectorSpec
        self.pickerView.reloadAllComponents()
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
        // TODO: Scroll into view after error appears or gets longer.
        if let errorString = self.spec.error {
            self.pickerView.layer.borderColor = UIColor.systemRed.cgColor
            self.errorView.text = errorString
            self.container.addSubview(self.errorView)
            constraints.append(contentsOf: [
                self.errorView.topAnchor.constraint(greaterThanOrEqualTo: prevBottomAnchor),
                self.errorView.leftAnchor.constraint(equalTo: self.container.leftAnchor, constant: 4.0),
                self.errorView.rightAnchor.constraint(equalTo: self.container.rightAnchor, constant: -4.0),
            ])
            prevBottomAnchor = self.errorView.bottomAnchor
        } else {
            self.pickerView.layer.borderColor = UIColor.clear.cgColor
            self.errorView.text = nil
            self.errorView.removeFromSuperview()
        }

        // Picker
        constraints.append(self.pickerView.topAnchor.constraint(greaterThanOrEqualTo: prevBottomAnchor))
        self.constraintSet.set(constraints)
    }

    // UIPickerViewDataSource

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        if self.spec.varName1 != nil,
           let options1 = self.spec.options1,
           !options1.isEmpty {
            if self.spec.varName2 != nil,
               let options2 = self.spec.options2,
               !options2.isEmpty {
                return 3
            }
            return 2
        }
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch component {
        case 0:
            return self.spec.options?.count ?? 0
        case 1:
            return self.spec.options1?.count ?? 0
        case 2:
            return self.spec.options2?.count ?? 0
        default:
            return 0
        }
    }

    // UIPickerViewDelegate

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch component {
        case 0:
            return self.spec.options?.get(row)
        case 1:
            return self.spec.options1?.get(row)
        case 2:
            return self.spec.options2?.get(row)
        default:
            return nil
        }
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        Self.logger.dbg("varName=\(self.spec.varName) didSelectRow")
        guard let value = self.pickerView(pickerView, titleForRow: row, forComponent: component) else {
            Self.logger.dbg("unknown option selected for varName=\(self.spec.varName) didSelectRow row=\(row) component=\(component)")
            return
        }
        let optVarName: String?
        switch component {
        case 0:
            optVarName = self.spec.varName
        case 1:
            optVarName = self.spec.varName1
        case 2:
            optVarName = self.spec.varName2
        default:
            return
        }
        guard let varName = optVarName else {
            return
        }
        self.ctx.varSet?.setString(varName, value)
        if let pollDelayMs = self.spec.pollDelayMs {
            self.ctx.foregroundPoller?.schedulePoll(delayMillis: pollDelayMs)
        }
    }
}
