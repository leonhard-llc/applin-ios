import Foundation
import UIKit

/// RowView exists because UITableView is incapable of updating widgets
/// without making them lose focus and dismiss the keyboard.
class RowView: UIView {
    // TODONT: Don't use UIStackView because its API is very difficult to use for dynamic updates.
    let constraintSet = ConstraintSet()
    var alignment: ApplinVAlignment = .center
    var orderedSubviews: [UIView] = []
    var separatorColor: UIColor?
    var spacing: Float32 = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isOpaque = false
    }

    convenience init() {
        self.init(frame: CGRect.zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not implemented")
    }

    func update(_ alignment: ApplinVAlignment, spacing: Float32, subviews: [UIView]) {
        //Self.logger.debug("update alignment=\(alignment) separator=\(String(describing: separator)) spacing=\(spacing) subviews=\(subviews)")
        self.alignment = alignment
        self.orderedSubviews = subviews
        self.spacing = spacing
        let newSubviews = Set(subviews)
        for subview in self.subviews {
            if !newSubviews.contains(subview) {
                subview.removeFromSuperview(self)
            }
        }
        let existingSubviews = Set(self.subviews)
        for subview in subviews {
            if !existingSubviews.contains(subview) {
                subview.translatesAutoresizingMaskIntoConstraints = false
                self.addSubview(subview)
            }
        }
        var newConstraints: [NSLayoutConstraint] = []
        // Left
        if let first = subviews.first {
            newConstraints.append(first.leftAnchor.constraint(equalTo: self.leftAnchor))
        }
        // Between
        let gap = CGFloat(Float32.maximum(self.spacing, 0.0))
        for (n, a) in subviews.dropLast(1).enumerated() {
            let b = subviews[n + 1]
            newConstraints.append(b.leftAnchor.constraint(equalTo: a.rightAnchor, constant: gap))
        }
        // Right
        if let last = subviews.last {
            newConstraints.append(last.rightAnchor.constraint(equalTo: self.rightAnchor))
        }
        // Top, Bottom, and Alignment
        for view in subviews {
            switch self.alignment {
            case .top:
                newConstraints.append(view.topAnchor.constraint(equalTo: self.topAnchor))
                newConstraints.append(view.bottomAnchor.constraint(lessThanOrEqualTo: self.bottomAnchor))
            case .center:
                newConstraints.append(view.topAnchor.constraint(greaterThanOrEqualTo: self.topAnchor))
                newConstraints.append(view.centerYAnchor.constraint(equalTo: self.centerYAnchor))
                newConstraints.append(view.bottomAnchor.constraint(lessThanOrEqualTo: self.bottomAnchor))
            case .bottom:
                newConstraints.append(view.topAnchor.constraint(greaterThanOrEqualTo: self.topAnchor))
                newConstraints.append(view.bottomAnchor.constraint(equalTo: self.bottomAnchor))
            }
        }
        self.constraintSet.set(newConstraints)
        self.setNeedsDisplay()
    }

    override public var description: String {
        "RowView{\(self.address) \(self.orderedSubviews.count) cols}"
    }
}
