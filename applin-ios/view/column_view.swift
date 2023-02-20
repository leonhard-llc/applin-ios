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
        self.translatesAutoresizingMaskIntoConstraints = false
    }

    convenience init() {
        print("ColumnView.init")
        self.init(frame: CGRect.zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func separatorThickness() -> Float32? {
        self.separatorColor == nil ? nil : SEPARATOR_THICKNESS
    }

    func gap() -> Float32 {
        Float32.maximum(self.spacing, self.separatorThickness() ?? 0.0)
    }

    func update(_ alignment: ApplinHAlignment, separator: UIColor?, spacing: Float32, subviews: [UIView]) {
        //print("ColumnView.update alignment=\(alignment) separator=\(String(describing: separator)) spacing=\(spacing) subviews=\(subviews)")
        self.alignment = alignment
        self.orderedSubviews = subviews
        self.separatorColor = separator
        self.spacing = spacing
        let newSubviews = Set(subviews)
        for subview in self.subviews {
            if !newSubviews.contains(subview) {
                //print("ColumnView.update remove \(subview)")
                subview.removeFromSuperview()
            }
        }
        let existingSubviews = Set(self.subviews)
        for subview in subviews {
            if !existingSubviews.contains(subview) {
                //print("ColumnView.update add \(subview)")
                self.addSubview(subview)
            }
        }
        var newConstraints: [NSLayoutConstraint] = []
        // Top
        if let first = subviews.first {
            let topGap = CGFloat(self.separatorThickness() ?? 0.0)
            newConstraints.append(first.topAnchor.constraint(equalTo: self.topAnchor, constant: topGap))
        }
        // Between
        for (n, a) in subviews.dropLast(1).enumerated() {
            let b = subviews[n + 1]
            newConstraints.append(b.topAnchor.constraint(equalTo: a.bottomAnchor, constant: CGFloat(self.gap())))
        }
        // Bottom
        if let last = subviews.last {
            let bottomGap = CGFloat(0.0 - (self.separatorThickness() ?? 0.0))
            newConstraints.append(last.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: bottomGap))
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
        self.setNeedsDisplay()
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
            if let first = self.orderedSubviews.first, let sepThickness = self.separatorThickness() {
                let y = first.frame.minY - CGFloat(sepThickness / 2.0)
                ctx.move(to: CGPoint(x: left, y: y))
                ctx.addLine(to: CGPoint(x: right, y: y))
            }
            for (n, a) in self.orderedSubviews.dropLast(1).enumerated() {
                let b = self.orderedSubviews[n + 1]
                let y = (a.frame.maxY + b.frame.minY) / 2.0
                //print("ColumnView.draw (\(left), \(y)) -> (\(right), \(y))")
                ctx.move(to: CGPoint(x: left, y: y))
                ctx.addLine(to: CGPoint(x: right, y: y))
            }
            if let last = self.orderedSubviews.last, let sepThickness = self.separatorThickness() {
                let y = last.frame.maxY + CGFloat(sepThickness / 2.0)
                ctx.move(to: CGPoint(x: left, y: y))
                ctx.addLine(to: CGPoint(x: right, y: y))
            }
            ctx.strokePath()
        }
    }
}
