import Foundation
import UIKit

struct FormData: Equatable, Hashable, WidgetDataProto {
    // This is needed because Swift tuples are not Equatable even if their fields are.
    // https://github.com/apple/swift-evolution/blob/main/proposals/0283-tuples-are-equatable-comparable-hashable.md
    static func ==(lhs: FormData, rhs: FormData) -> Bool {
        lhs.sections.count == rhs.sections.count
                && zip(lhs.sections, rhs.sections).allSatisfy({ (left, right) in left == right })
    }

    static let TYP = "form"
    var sections: [(String?, [WidgetData])]

    init(_ item: JsonItem, _ session: ApplinSession) throws {
        let widgets = try item.optWidgets(session) ?? []
        self.sections = []
        var unnamedSection: [WidgetData] = []
        for widget in widgets {
            switch widget {
            case let .formSection(sectionData):
                if !unnamedSection.isEmpty {
                    self.sections.append((nil, unnamedSection))
                    unnamedSection = []
                }
                self.sections.append((sectionData.optTitle, sectionData.widgets))
            default:
                unnamedSection.append(widget)
            }
        }
        if !unnamedSection.isEmpty {
            self.sections.append((nil, unnamedSection))
        }
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(FormData.TYP)
        var itemWidgets: [JsonItem] = []
        for (optTitle, widgets) in sections {
            if let title = optTitle {
                itemWidgets.append(FormSectionData(title, widgets).toJsonItem())
            } else {
                for widget in widgets {
                    itemWidgets.append(widget.inner().toJsonItem())
                }
            }
        }
        item.widgets = itemWidgets
        return item
    }

    func keys() -> [String] {
        []
    }

    func getTapActions() -> [ActionData]? {
        nil
    }

    func getView(_ session: ApplinSession, _ widgetCache: WidgetCache) -> UIView {
        let widget = widgetCache.removeForm() ?? FormWidget(self, session, widgetCache)
        widget.data = self
        widgetCache.putNextForm(widget)
        return widget.getView(session, widgetCache)
    }

    // This is needed because Swift tuples are not Equatable even if their fields are.
    // https://github.com/apple/swift-evolution/blob/main/proposals/0283-tuples-are-equatable-comparable-hashable.md
    func hash(into hasher: inout Hasher) {
        for section in self.sections {
            hasher.combine(section.0)
            hasher.combine(section.1)
        }
    }
}

private class ErrorCell: UITableViewCell {
    static let REUSE_ID = "ErrorCell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        var content = self.defaultContentConfiguration()
        content.text = "error"
        self.contentConfiguration = content
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("unimplemented")
    }
}

// TODO: Show disabled with disabled color.
private class DisclosureCell: UITableViewCell {
    static let REUSE_ID = "DisclosureCell"

    func update(_ text: String, enabled: Bool) {
        self.accessoryType = .disclosureIndicator
        var content = self.defaultContentConfiguration()
        content.text = text
        content.textProperties.color = enabled ? .label : .placeholderText
        self.contentConfiguration = content
    }
}

private class DisclosureSubtextCell: UITableViewCell {
    static let REUSE_ID = "DisclosureSubtextCell"

    func update(text: String, subText: String, enabled: Bool) {
        self.accessoryType = .disclosureIndicator
        var content = self.defaultContentConfiguration()
        content.text = text
        content.secondaryText = subText
        content.textProperties.color = enabled ? .label : .placeholderText
        content.secondaryTextProperties.color = enabled ? .label : .placeholderText
        self.contentConfiguration = content
    }
}

private extension UIListContentConfiguration {
    mutating func addPlaceholderImage(cellWidth: CGFloat) {
        if let spinnerPath = Bundle.main.path(forResource: "spinner", ofType: "gif") {
            // TODO: Animate spinner.
            self.image = UIImage(contentsOfFile: spinnerPath)
        } else {
            self.image = UIImage()
        }
        let height = cellWidth / 5
        self.imageProperties.reservedLayoutSize = CGSize(width: height, height: height)
        self.imageProperties.maximumSize = CGSize(width: height, height: height)
    }

    mutating func loadImage(_ session: ApplinSession, _ url: URL) async throws {
        let data = try await session.fetch(url)
        guard let image = UIImage(data: data) else {
            throw ApplinError.deserializeError("error loading image from \(url.absoluteString)")
        }
        self.image = image
    }
}

private class DisclosureImageCell: UITableViewCell {
    static let REUSE_ID = "DisclosureImageCell"
    var optPhotoUrl: URL?

    func update(_ session: ApplinSession,
                text: String,
                photoUrl: URL,
                enabled: Bool
    ) {
        self.optPhotoUrl = photoUrl
        self.accessoryType = .disclosureIndicator
        var content = self.defaultContentConfiguration()
        content.text = text
        content.textProperties.color = enabled ? .label : .placeholderText
        content.addPlaceholderImage(cellWidth: self.bounds.width)
        self.contentConfiguration = content
        Task.init { [content] in
            var content2 = content
            try await content2.loadImage(session, photoUrl)
            DispatchQueue.main.async { [weak self, content2] in
                if self?.optPhotoUrl == photoUrl {
                    print("image \(photoUrl)")
                    self?.contentConfiguration = content2
                }
            }
        }
    }
}

private class DisclosureImageSubtextCell: UITableViewCell {
    static let REUSE_ID = "DisclosureImageSubtextCell"
    var optPhotoUrl: URL?

    func update(_ session: ApplinSession,
                text: String,
                subText: String,
                photoUrl: URL,
                enabled: Bool
    ) {
        self.optPhotoUrl = photoUrl
        self.accessoryType = .disclosureIndicator
        var content = self.defaultContentConfiguration()
        content.text = text
        content.secondaryText = subText
        content.textProperties.color = enabled ? .label : .placeholderText
        content.secondaryTextProperties.color = enabled ? .label : .placeholderText
        content.addPlaceholderImage(cellWidth: self.bounds.width)
        self.contentConfiguration = content
        Task.init { [content] in
            var content2 = content
            try await content2.loadImage(session, photoUrl)
            DispatchQueue.main.async { [weak self, content2] in
                if self?.optPhotoUrl == photoUrl {
                    print("image \(photoUrl)")
                    self?.contentConfiguration = content2
                }
            }
        }
    }
}

private class TextCell: UITableViewCell {
    static let REUSE_ID = "TextCell"

    func update(_ text: String) {
        var content = self.defaultContentConfiguration()
        content.text = text
        self.contentConfiguration = content
    }
}

private class WidgetCell: UITableViewCell {
    static let REUSE_ID = "WidgetCell"
    var optHelper: SuperviewHelper?

    func update(_ session: ApplinSession, _ widgetCache: WidgetCache, _ widget: WidgetData) {
        if let helper = self.optHelper {
            helper.removeSubviewsAndConstraints(self.contentView)
            self.optHelper = nil
        }
        let subView = widget.inner().getView(session, widgetCache)
        // subView.clipsToBounds = true
        self.contentView.addSubview(subView)
        self.optHelper = SuperviewHelper(constraints: [
            subView.topAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.topAnchor),
            subView.bottomAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.bottomAnchor),
            subView.leadingAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.leadingAnchor),
            subView.trailingAnchor.constraint(lessThanOrEqualTo: self.contentView.layoutMarginsGuide.trailingAnchor),
        ])
    }
}

class FormWidget: NSObject, UITableViewDataSource, UITableViewDelegate, WidgetProto {
    var data: FormData
    weak var weakSession: ApplinSession?
    weak var weakWidgetCache: WidgetCache?
    var tableView: UITableView!

    init(_ data: FormData, _ session: ApplinSession, _ widgetCache: WidgetCache) {
        self.data = data
        self.weakSession = session
        self.weakWidgetCache = widgetCache
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(ErrorCell.self, forCellReuseIdentifier: ErrorCell.REUSE_ID)
        tableView.register(DisclosureCell.self, forCellReuseIdentifier: DisclosureCell.REUSE_ID)
        tableView.register(DisclosureSubtextCell.self, forCellReuseIdentifier: DisclosureSubtextCell.REUSE_ID)
        tableView.register(DisclosureImageCell.self, forCellReuseIdentifier: DisclosureImageCell.REUSE_ID)
        tableView.register(DisclosureImageSubtextCell.self, forCellReuseIdentifier: DisclosureImageSubtextCell.REUSE_ID)
        tableView.register(TextCell.self, forCellReuseIdentifier: TextCell.REUSE_ID)
        tableView.register(WidgetCell.self, forCellReuseIdentifier: WidgetCell.REUSE_ID)
        tableView.contentInsetAdjustmentBehavior = .never // Only works for UITableView.Style.plain.
        // tableView.allowsSelection = true
        // tableView.allowsMultipleSelection = false
        // tableView.selectionFollowsFocus = true
        // tableView.isUserInteractionEnabled = true
        self.tableView = tableView
        super.init()
        self.tableView.dataSource = self
        self.tableView.delegate = self
    }

    func keys() -> [String] {
        self.data.keys()
    }

    func getView(_: ApplinSession, _: WidgetCache) -> UIView {
        self.tableView.reloadData()
        return self.tableView
    }

    // UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        self.data.sections.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        self.data.sections.get(section)?.0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.data.sections.get(section)?.1.count ?? 0
    }

    // This does not remove the top padding for UITableView.Style.grouped.
    // func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    //     if section == 0 {
    //         return 0.0
    //     } else {
    //         return UITableView.automaticDimension
    //     }
    // }

    private func getWidget(_ indexPath: IndexPath) -> WidgetData? {
        self.data.sections.get(indexPath.section)?.1.get(indexPath.row)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // print("form cellForRowAt \(indexPath.section).\(indexPath.row)")
        guard let session = self.weakSession,
              let widgetCache = self.weakWidgetCache,
              let widget = self.getWidget(indexPath)
        else {
            return tableView.dequeueReusableCell(withIdentifier: ErrorCell.REUSE_ID, for: indexPath)
        }
        switch widget {
        case let .text(data):
            let cell = tableView.dequeueReusableCell(withIdentifier: TextCell.REUSE_ID, for: indexPath) as! TextCell
            cell.update(data.text)
            return cell
        case let .formDetail(data):
            switch (data.subText, data.photoUrl) {
            case (.none, .none):
                let cell = tableView.dequeueReusableCell(
                        withIdentifier: DisclosureCell.REUSE_ID, for: indexPath) as! DisclosureCell
                cell.update(data.text, enabled: !data.actions.isEmpty)
                return cell
            case let (.some(subText), .none):
                let cell = tableView.dequeueReusableCell(
                        withIdentifier: DisclosureSubtextCell.REUSE_ID, for: indexPath) as! DisclosureSubtextCell
                cell.update(text: data.text, subText: subText, enabled: !data.actions.isEmpty)
                return cell
            case let (.none, .some(photoUrl)):
                let cell = tableView.dequeueReusableCell(
                        withIdentifier: DisclosureImageCell.REUSE_ID, for: indexPath) as! DisclosureImageCell
                cell.update(session, text: data.text, photoUrl: photoUrl, enabled: !data.actions.isEmpty)
                return cell
            case let (.some(subText), .some(photoUrl)):
                let cell = tableView.dequeueReusableCell(
                        withIdentifier: DisclosureImageSubtextCell.REUSE_ID, for: indexPath) as! DisclosureImageSubtextCell
                cell.update(session, text: data.text, subText: subText, photoUrl: photoUrl, enabled: !data.actions.isEmpty)
                return cell
            }
        default:
            let cell = tableView.dequeueReusableCell(
                    withIdentifier: WidgetCell.REUSE_ID, for: indexPath) as! WidgetCell
            cell.update(session, widgetCache, widget)
            return cell
        }
    }

    // UITableViewDelegate

    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        let result = self.getWidget(indexPath)?.inner().getTapActions() != nil
        // print("form shouldHighlightRowAt \(indexPath.section).\(indexPath.row) \(result)")
        return result
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // print("form didSelectRowAt \(indexPath.section).\(indexPath.row)")
        if let actions = self.getWidget(indexPath)?.inner().getTapActions() {
            self.weakSession?.doActions(actions)
            self.tableView.deselectRow(at: indexPath, animated: false)
        }
    }
}
