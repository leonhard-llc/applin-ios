import Foundation
import UIKit

class TableView: UIView {
    let SEPARATOR_THICKNESS: Float32 = 0.7
    let SEPARATOR_COLOR: CGColor = UIColor.separator.cgColor
    let constraintSet = ConstraintSet()
    var rowSeparators: [UInt] = []
    var spacing: CGFloat = 0
    var subviewRows: [[UIView?]] = []
    var rowSizers: [UIView] = []
    var colSizers: [UIView] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        //self.backgroundColor = pastelYellow
        self.isOpaque = false
    }

    convenience init() {
        print("TableView.init")
        self.init(frame: CGRect.zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(rowSeparators: [UInt], spacing: Float32, newSubviewRows: [[UIView?]]) {
        print("TableView.update rowSeparators=\(String(describing: rowSeparators)) spacing=\(spacing) newSubviewRows=\(newSubviewRows)")
        self.rowSeparators = rowSeparators
        self.spacing = CGFloat(spacing)
        let newSubviews = Set(newSubviewRows.flatMap({ $0 }).compactMap({ $0 }))
        for row in self.subviewRows {
            for optSubview in row {
                if let subview = optSubview, !newSubviews.contains(subview) {
                    print("TableView.update remove \(subview)")
                    subview.removeFromSuperview()
                }
            }
        }
        self.subviewRows = newSubviewRows
        let existingSubviews = Set(self.subviews)
        for subviewRow in self.subviewRows {
            for optSubview in subviewRow {
                if let subview = optSubview, !existingSubviews.contains(subview) {
                    //print("TableView.update add \(subview)")
                    subview.translatesAutoresizingMaskIntoConstraints = false
                    self.addSubview(subview)
                }
            }
        }
        var newConstraints: [NSLayoutConstraint] = []
        let numColumns = max(1, self.subviewRows.map({ row in row.count }).max() ?? 0)
        let numRows = max(1, self.subviewRows.count)
        print("TableView numColumns=\(numColumns) numRows=\(numRows)")
        while self.colSizers.count < numColumns {
            let view = UIView()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.backgroundColor = pastelBlue
            self.addSubview(view)
            self.colSizers.append(view)
        }
        while self.colSizers.count > numColumns {
            self.colSizers.popLast()?.removeFromSuperview()
        }
        while self.rowSizers.count < numRows {
            let view = UIView()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.backgroundColor = pastelGreen
            // view.isHidden = true
            self.addSubview(view)
            self.rowSizers.append(view)
        }
        while self.rowSizers.count > numRows {
            self.rowSizers.popLast()?.removeFromSuperview()
        }
        print("TableView colSizers.count=\(self.colSizers.count) rowSizers.count=\(self.rowSizers.count)")
        // Sizer dimensions.
        newConstraints.append(contentsOf: self.colSizers.map(
                { view in view.heightAnchor.constraint(equalToConstant: 0.0) }))
        newConstraints.append(contentsOf: self.colSizers.map(
                { view in view.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 1.0 / CGFloat(self.colSizers.count)).withPriority(.defaultLow) }))
        newConstraints.append(contentsOf: self.rowSizers.map(
                { view in view.heightAnchor.constraint(equalToConstant: 8.0).withPriority(.defaultLow) }))
        newConstraints.append(contentsOf: self.rowSizers.map(
                { view in view.widthAnchor.constraint(equalToConstant: 0.0) }))
        // Sizers stick to top and left edges.
        newConstraints.append(contentsOf: self.colSizers.map(
                { view in view.topAnchor.constraint(equalTo: self.topAnchor) }))
        newConstraints.append(contentsOf: self.rowSizers.map(
                { view in view.leftAnchor.constraint(equalTo: self.leftAnchor) }))
        // First & last sizers stick to edges.
        newConstraints.append(contentsOf: [
            self.colSizers.first!.leftAnchor.constraint(equalTo: self.leftAnchor),
            self.colSizers.last!.rightAnchor.constraint(equalTo: self.rightAnchor),
            self.rowSizers.first!.topAnchor.constraint(equalTo: self.topAnchor),
            self.rowSizers.last!.bottomAnchor.constraint(equalTo: self.bottomAnchor),
        ])
        // Sizers stick to each other
        newConstraints.append(contentsOf: zip(self.colSizers, self.colSizers.dropFirst()).map({ (left, right) in
            left.rightAnchor.constraint(lessThanOrEqualTo: right.leftAnchor)
        }))
        newConstraints.append(contentsOf: zip(self.rowSizers, self.rowSizers.dropFirst()).map({ (above, below) in
            below.topAnchor.constraint(greaterThanOrEqualTo: above.bottomAnchor)
        }))
        //// Widgets
        for (row, rowSizer) in zip(self.subviewRows, self.rowSizers) {
            for (optView, colSizer) in zip(row, self.colSizers) {
                if let view = optView {
                    newConstraints.append(contentsOf: [
                        view.centerXAnchor.constraint(equalTo: colSizer.centerXAnchor),
                        view.centerYAnchor.constraint(equalTo: rowSizer.centerYAnchor),
                        view.leftAnchor.constraint(greaterThanOrEqualTo: colSizer.leftAnchor, constant: self.spacing),
                        view.rightAnchor.constraint(lessThanOrEqualTo: colSizer.rightAnchor, constant: -self.spacing),
                        view.topAnchor.constraint(greaterThanOrEqualTo: rowSizer.topAnchor, constant: self.spacing),
                        view.bottomAnchor.constraint(lessThanOrEqualTo: rowSizer.bottomAnchor, constant: -self.spacing),
                    ])
                }
            }
        }
        self.constraintSet.set(newConstraints)
    }

    override func draw(_ rect: CGRect) {
        if !self.rowSeparators.isEmpty, let ctx = UIGraphicsGetCurrentContext() {
            // Draw a line left-to-right between rows.
            let left = 0.0 + self.spacing
            let right = max(0.0, self.bounds.size.width - self.spacing)
            ctx.setLineCap(.round)
            ctx.setLineWidth(CGFloat(SEPARATOR_THICKNESS))
            ctx.setStrokeColor(SEPARATOR_COLOR)
            ctx.beginPath()
            for rowSeparator in self.rowSeparators {
                if let rowSizer = self.rowSizers.get(Int(rowSeparator)) {
                    let y = rowSizer.frame.minY - CGFloat(SEPARATOR_THICKNESS / 2.0)
                    ctx.move(to: CGPoint(x: left, y: y))
                    ctx.addLine(to: CGPoint(x: right, y: y))
                }
            }
            ctx.strokePath()
        }
    }
}
