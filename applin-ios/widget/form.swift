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
                self.sections.append((sectionData.title, sectionData.widgets))
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

class FormCell: UITableViewCell {
    static let cellReuseIdentifier = "FormCell"
    var optHelper: SuperviewHelper?

    required init?(coder aDecoder: NSCoder) {
        fatalError("unimplemented")
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    func error() {
        if let helper = self.optHelper {
            helper.removeSubviewsAndConstraints(self.contentView)
        }
        self.optHelper = nil
        var content = self.defaultContentConfiguration()
        content.text = "error"
        self.contentConfiguration = content
    }

    func setWidget(_ widget: WidgetData, _ session: ApplinSession, _ widgetCache: WidgetCache) {
        if let helper = self.optHelper {
            helper.removeSubviewsAndConstraints(self.contentView)
        }
        self.optHelper = nil
        self.accessoryType = .none
        switch widget {
        case let .text(inner):
            var content = self.defaultContentConfiguration()
            content.text = inner.text
            self.contentConfiguration = content
        case let .formDetail(inner):
            var content = self.defaultContentConfiguration()
            content.text = inner.text
            content.secondaryText = inner.subText
            // TODO: Add photo.
            self.contentConfiguration = content
            self.accessoryType = .disclosureIndicator
        default:
            let subView = widget.inner().getView(session, widgetCache)
            // subView.clipsToBounds = true
            self.contentView.addSubview(subView)
            self.optHelper = SuperviewHelper(constraints: [
                subView.topAnchor.constraint(equalTo: self.contentView.safeAreaLayoutGuide.topAnchor),
                subView.bottomAnchor.constraint(lessThanOrEqualTo: self.contentView.safeAreaLayoutGuide.bottomAnchor),
                subView.leadingAnchor.constraint(equalTo: self.contentView.safeAreaLayoutGuide.leadingAnchor),
                subView.trailingAnchor.constraint(lessThanOrEqualTo: self.contentView.safeAreaLayoutGuide.trailingAnchor),
            ])
        }
    }
}

class FormWidget: NSObject, UITableViewDataSource, UITableViewDelegate, WidgetProto {
    var data: FormData
    weak var weakSession: ApplinSession?
    weak var weakWidgetCache: WidgetCache?
    var tableView: UITableView!

    init(_ data: FormData, _ session: ApplinSession, _ widgetCache: WidgetCache) {
        print("FormWidget.init(\(data))")
        self.data = data
        self.weakSession = session
        self.weakWidgetCache = widgetCache
        self.tableView = UITableView()
        super.init()
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.tableView.register(FormCell.self, forCellReuseIdentifier: FormCell.cellReuseIdentifier)
        self.tableView.dataSource = self
        self.tableView.delegate = self
    }

    func keys() -> [String] {
        self.data.keys()
    }

    func getView(_: ApplinSession, _: WidgetCache) -> UIView {
        // Apple's docs omit this.
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

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("tableView cellForRowAt \(indexPath)")
        let tableViewCell = tableView.dequeueReusableCell(withIdentifier: FormCell.cellReuseIdentifier, for: indexPath)
        let formCell = tableViewCell as! FormCell
        guard let session = self.weakSession,
              let widgetCache = self.weakWidgetCache,
              let widget = self.data.sections.get(indexPath.section)?.1.get(indexPath.row)
        else {
            formCell.error()
            return formCell
        }
        print("tableView cellForRowAt \(indexPath): \(widget)")
        formCell.setWidget(widget, session, widgetCache)
        return formCell
    }

    // UITableViewDelegate

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        switch self.data.sections.get(indexPath.section)?.1.get(indexPath.row) {
        case .formDetail:
            break
        default:
            return nil
        }
        return indexPath
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch self.data.sections.get(indexPath.section)?.1.get(indexPath.row) {
        case let .formDetail(inner):
            self.weakSession?.doActions(inner.actions)
        default:
            break
        }
        self.tableView.deselectRow(at: indexPath, animated: false)
    }
}
