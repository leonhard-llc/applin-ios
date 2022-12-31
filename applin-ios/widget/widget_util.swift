import UIKit

let pastelYellow = UIColor(hue: 48.0 / 360.0, saturation: 0.56, brightness: 0.96, alpha: 1.0)
let pastelPeach = UIColor(hue: 19.0 / 360.0, saturation: 0.28, brightness: 1.0, alpha: 1.0)
let pastelPink = UIColor(hue: 0.0, saturation: 0.2, brightness: 1.0, alpha: 1.0)
let pastelLavender = UIColor(hue: 299.0 / 360.0, saturation: 0.23, brightness: 1.0, alpha: 1.0)
let pastelBlue = UIColor(hue: 210.0 / 360.0, saturation: 0.25, brightness: 1.0, alpha: 1.0)
let pastelMint = UIColor(hue: 171.0 / 360.0, saturation: 0.36, brightness: 0.93, alpha: 1.0)
let pastelGreen = UIColor(hue: 144.0 / 360.0, saturation: 0.41, brightness: 0.96, alpha: 1.0)
let pastelYellowGreen = UIColor(hue: 66.0 / 360.0, saturation: 0.66, brightness: 0.91, alpha: 1.0)

class ConstraintHolder {
    private var constraint: NSLayoutConstraint?

    func set(_ constraint: NSLayoutConstraint?) {
        self.constraint?.isActive = false
        self.constraint = constraint
        self.constraint?.isActive = true
    }
}

class ConstraintSet {
    private var constraints: [NSLayoutConstraint] = []

    func set(_ constraints: [NSLayoutConstraint]) {
        NSLayoutConstraint.deactivate(self.constraints)
        self.constraints = constraints
        NSLayoutConstraint.activate(self.constraints)
    }
}

class SingleViewContainerHelper {
    private weak var superView: UIView?
    private weak var subView: UIView?
    private var constraints: [NSLayoutConstraint] = []

    init(superView: UIView) {
        self.superView = superView
    }

    func update(_ newSubView: UIView, _ constraintsFn: () -> [NSLayoutConstraint]) {
        guard let superView = self.superView else {
            return
        }
        if newSubView === self.subView {
            return
        }
        NSLayoutConstraint.deactivate(self.constraints)
        self.subView?.removeFromSuperview()
        superView.addSubview(newSubView)
        self.subView = newSubView
        self.constraints = constraintsFn()
        NSLayoutConstraint.activate(self.constraints)
        //self.subView?.setNeedsDisplay()
    }
}

extension NSLayoutConstraint {
    func withPriority(_ priority: UILayoutPriority) -> NSLayoutConstraint {
        self.priority = priority
        return self
    }
}

// From https://www.biteinteractive.com/control-target-and-action-in-ios-14/
extension UIControl {
    func addAction(for event: UIControl.Event, handler: @escaping UIActionHandler) {
        self.addAction(UIAction(handler: handler), for: event)
    }
}

extension UIViewController {
    func dismissAsync(animated: Bool) async {
        await withCheckedContinuation() { continuation in
            self.dismiss(animated: animated) {
                continuation.resume()
            }
        }
    }
}
