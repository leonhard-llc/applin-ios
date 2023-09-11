import OSLog
import UIKit

private let LOGGER = Logger(subsystem: "Applin", category: "WidgetUtil")

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
    public weak var superView: UIView?
    private weak var subView: UIView?
    private var constraints: [NSLayoutConstraint] = []

    init() {
    }

    init(superView: UIView) {
        self.superView = superView
    }

    func clear() {
        NSLayoutConstraint.deactivate(self.constraints)
        self.constraints = []
        self.subView?.removeFromSuperview(self.superView)
        self.subView = nil
    }

    func update(_ newSubView: UIView, _ constraintsFn: () -> [NSLayoutConstraint]) {
        guard let superView = self.superView else {
            return
        }
        if newSubView === self.subView {
            return
        }
        self.clear()
        superView.addSubview(newSubView)
        self.subView = newSubView
        self.constraints = constraintsFn()
        NSLayoutConstraint.activate(self.constraints)
        //self.subView?.setNeedsDisplay()
    }
}

public extension NSLayoutConstraint {
    func withPriority(_ priority: UILayoutPriority) -> NSLayoutConstraint {
        self.priority = priority
        return self
    }
}

public class SyncCell<T> {
    let lock = NSLock()
    private var value: T

    init(_ value: T) {
        self.value = value
    }

    public func get() -> T {
        self.lock.lock()
        defer {
            self.lock.unlock()
        }
        return self.value
    }

    public func set(_ newValue: T) -> T {
        self.lock.lock()
        defer {
            self.lock.unlock()
        }
        let oldValue = self.value
        self.value = newValue
        return oldValue
    }
}

public extension Task {
    var resultSync: Result<Success, Failure> {
        get {
            let cell = SyncCell<Result<Success, Failure>?>(nil)
            let semaphore = DispatchSemaphore(value: 0)
            let task = self
            Task<(), Never>(priority: .high) {
                let result = await task.result
                let _ = cell.set(result)
                semaphore.signal()
            }
            semaphore.wait()
            return cell.get()!
        }
    }
}

// From https://www.biteinteractive.com/control-target-and-action-in-ios-14/
extension UIControl {
    func addAction(for event: UIControl.Event, handler: @escaping UIActionHandler) {
        self.addAction(UIAction(handler: handler), for: event)
    }
}

public extension UIView {
    func removeFromSuperview(_ superView: UIView?) {
        if self.superview === superView {
            LOGGER.trace("removeFromSuperview superView=\(superView) view=\(self)")
            self.removeFromSuperview()
        }
    }
}

extension UIViewController {
    func dismissAsync(animated: Bool) async {
        await withCheckedContinuation { continuation in
            self.dismiss(animated: animated) {
                continuation.resume()
            }
        }
    }

    func presentAsync(_ ctl: UIViewController, animated: Bool) async {
        await withCheckedContinuation { continuation in
            self.present(ctl, animated: animated) {
                continuation.resume()
            }
        }
    }
}
