import Foundation
import UIKit

/// ColumnView exists because UITableView is incapable of updating widgets
/// without making them lose focus and dismiss the keyboard.
class ColumnView: UIView {
    // TODONT: Don't use UIStackView because its API is very difficult to use for dynamic updates.
    let SEPARATOR_THICKNESS: Float32 = 0.7
    let constraintSet = ConstraintSet()
    var alignment: ApplinHAlignment = .start
    var orderedSubviews: [UIView] = []
    var separatorColor: UIColor?
    var spacing: Float32 = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isOpaque = false
    }

    convenience init() {
        print("ColumnView.init")
        self.init(frame: CGRect.zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(_ alignment: ApplinHAlignment, separator: UIColor?, spacing: Float32, subviews: [UIView]) {
        print("ColumnView.update alignment=\(alignment) separator=\(String(describing: separator)) spacing=\(spacing) subviews=\(subviews)")
        self.alignment = alignment
        self.orderedSubviews = subviews
        self.separatorColor = separator
        self.spacing = spacing
        let subviewsSet = Set(subviews)
        let viewsToRemove: [UIView] = self.subviews.filter({ v in subviewsSet.contains(v) })
        for viewToRemove in viewsToRemove {
            print("ColumnView.update remove \(viewToRemove)")
            viewToRemove.removeFromSuperview()
        }
        for newView in subviews {
            print("ColumnView.update add \(newView)")
            self.addSubview(newView)
        }
        var newConstraints: [NSLayoutConstraint] = []
        // Top
        if let first = subviews.first {
            newConstraints.append(first.topAnchor.constraint(equalTo: self.topAnchor))
        }
        // Between
        let gap = CGFloat(self.spacing + (self.separatorColor == nil ? 0 : SEPARATOR_THICKNESS))
        for (n, a) in subviews.dropLast(1).enumerated() {
            let b = subviews[n + 1]
            newConstraints.append(b.topAnchor.constraint(equalTo: a.bottomAnchor, constant: gap))
        }
        // Bottom
        if let last = subviews.last {
            newConstraints.append(last.bottomAnchor.constraint(equalTo: self.bottomAnchor))
        }
        // Left, Right, and Alignment
        for view in subviews {
            switch self.alignment {
            case .start:
                newConstraints.append(view.leftAnchor.constraint(equalTo: self.leftAnchor))
                newConstraints.append(view.rightAnchor.constraint(lessThanOrEqualTo: self.rightAnchor))
            case .center:
                newConstraints.append(view.leftAnchor.constraint(greaterThanOrEqualTo: self.leftAnchor))
                newConstraints.append(view.centerXAnchor.constraint(equalTo: self.centerXAnchor))
                newConstraints.append(view.rightAnchor.constraint(lessThanOrEqualTo: self.rightAnchor))
            case .end:
                newConstraints.append(view.leftAnchor.constraint(greaterThanOrEqualTo: self.leftAnchor))
                newConstraints.append(view.rightAnchor.constraint(equalTo: self.rightAnchor))
            }
        }
        self.constraintSet.set(newConstraints)
    }

    override func draw(_ rect: CGRect) {
        if let color = self.separatorColor, let ctx = UIGraphicsGetCurrentContext() {
            // Draw a line left-to-right between subviews
            let left = 0.0
            let right = self.bounds.size.width
            ctx.setLineCap(.round)
            ctx.setLineWidth(CGFloat(SEPARATOR_THICKNESS))
            ctx.setStrokeColor(color.cgColor)
            ctx.beginPath()
            for (n, a) in self.orderedSubviews.dropLast(1).enumerated() {
                let b = self.orderedSubviews[n + 1]
                let y = (a.frame.maxY + b.frame.minY) / 2.0
                //print("ColumnView.draw (\(left), \(y)) -> (\(right), \(y))")
                ctx.move(to: CGPoint(x: left, y: y))
                ctx.addLine(to: CGPoint(x: right, y: y))
            }
            ctx.strokePath()
        }
    }
}