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
    let pageKey: String
    var sections: [(String?, [WidgetData])]

    init(_ session: ApplinSession, pageKey: String, _ item: JsonItem) throws {
        self.pageKey = pageKey
        let widgets = try item.optWidgets(session, pageKey: pageKey) ?? []
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

    func canTap() -> Bool {
        false
    }

    func tap(_ session: ApplinSession, _ cache: WidgetCache) {
    }

    func getView(_ session: ApplinSession, _ cache: WidgetCache) -> UIView {
        let widget = cache.removeForm() ?? FormWidget(session, cache, self.pageKey, self)
        widget.dataSource.update(self)
        cache.putNextForm(widget)
        return widget.getView()
    }

    // This is needed because Swift tuples are not Equatable even if their fields are.
    // https://github.com/apple/swift-evolution/blob/main/proposals/0283-tuples-are-equatable-comparable-hashable.md
    func hash(into hasher: inout Hasher) {
        for section in self.sections {
            hasher.combine(section.0)
            hasher.combine(section.1)
        }
    }

    func vars() -> [(String, Var)] {
        self.sections.flatMap({ section in
            section.1.flatMap({ widget in
                widget.inner().vars()
            })
        })
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
        Task { [content] in
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
        Task { [content] in
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
    let helper = SuperviewHelper()

    func update(_ session: ApplinSession, _ cache: WidgetCache, _ widgetData: WidgetData) {
        let subView = widgetData.inner().getView(session, cache)
        if subView.superview != self.contentView {
            helper.removeSubviewsAndConstraints(self.contentView)
            self.contentView.addSubview(subView)
            // subView.clipsToBounds = true
            self.helper.setConstraints([
                subView.topAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.topAnchor),
                subView.bottomAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.bottomAnchor),
                subView.leadingAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.leadingAnchor),
                subView.trailingAnchor.constraint(lessThanOrEqualTo: self.contentView.layoutMarginsGuide.trailingAnchor),
            ])
        }
    }
}

class KeyboardAvoidingTableView: UITableView {
    // https://www.hackingwithswift.com/example-code/uikit/how-to-adjust-a-uiscrollview-to-fit-the-keyboard
    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func adjustForKeyboard(notification: Notification) {
        guard let frameNsValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }
        let relativeFrame = self.convert(frameNsValue.cgRectValue, from: self.window)
        print("adjustForKeyboard frameNsValue=\(frameNsValue), relativeFrame=\(relativeFrame)")
        if notification.name == UIResponder.keyboardWillHideNotification {
            self.contentInset = .zero
        } else {
            self.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: relativeFrame.height - self.safeAreaInsets.bottom, right: 0)
        }
    }
}

// This class exists to work around "'self' used before 'super.init' call" in

// sub-class of UITableViewDiffableDataSource.
// Apple's engineers didn't give a fuck when they made this API. :(
// To whoever made this API:
//  - Fuck you for not documenting how to actually use this API!
//  - Fuck you for making the API so shitty that I have to make THREE CLASSES,
//    one subclass, and implement two protocols just to use it,
//    and maintain this complicated code!
//  - Fuck you for making me waste days just to use your shitty widget!
//  - Fuck you for not making this stuff composable!
//  - Fuck you for not documenting keyboard show/hide behavior and how to
//    handle it properly!
//  - I'm making Applin so people can make apps without dealing with your shit.
//    Fuck you!
class InnerDataSource {
    weak var weakSession: ApplinSession?
    weak var weakCache: WidgetCache?
    var data: FormData

    init(_ session: ApplinSession, _ cache: WidgetCache, _ data: FormData) {
        self.weakSession = session
        self.weakCache = cache
        self.data = data
    }

    func getWidgetData(_ indexPath: IndexPath) -> WidgetData? {
        self.data.sections.get(indexPath.section)?.1.get(indexPath.row)
    }

    func getCell(_ tableView: UITableView, _ indexPath: IndexPath, _ id: String) -> UITableViewCell {
        // print("form cellForRowAt \(indexPath.section).\(indexPath.row)")
        guard let session = self.weakSession,
              let cache = self.weakCache,
              let widgetData = self.getWidgetData(indexPath)
        else {
            return tableView.dequeueReusableCell(withIdentifier: ErrorCell.REUSE_ID, for: indexPath)
        }
        switch widgetData {
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
            cell.update(session, cache, widgetData)
            return cell
        }
    }
}

// We must subclass UITableViewDiffableDataSource because otherwise

// there is no way to specify section headers.
// The Apple engineers who designed this API did a poor job, and a worse job on the docs. :(
class FormWidgetDataSource: UITableViewDiffableDataSource<String, String> {
    var inner: InnerDataSource

    init(_ session: ApplinSession, _ cache: WidgetCache, _ tableView: UITableView, _ data: FormData) {
        let inner = InnerDataSource(session, cache, data)
        weak var weakInner = inner
        self.inner = inner
        super.init(tableView: tableView) {
            (tableView: UITableView, indexPath: IndexPath, itemIdentifier: String) -> UITableViewCell? in
            if let inner = weakInner {
                return inner.getCell(tableView, indexPath, itemIdentifier)
            } else {
                return nil
            }
        }
    }

    func update(_ newData: FormData) {
        // https://developer.apple.com/documentation/uikit/uitableviewdiffabledatasource
        // https://developer.apple.com/documentation/uikit/nsdiffabledatasourcesnapshot
        self.inner.data = newData
        var snapshot = NSDiffableDataSourceSnapshot<String, String>()
        // Add unique IDs to snapshot to prevent NSInternalInconsistencyException
        // "Fatal: supplied item identifiers are not unique. Duplicate identifiers"
        var sectionIds: Dictionary<String, Int> = Dictionary()

        func makeUniqueSectionId(_ id: String) -> String {
            if var count = sectionIds[id] {
                count += 1
                sectionIds[id] = count
                return "applin-\(count)-\(id)"
            } else {
                sectionIds[id] = 0
                return id
            }
        }

        var widgetIds: Dictionary<String, Int> = Dictionary()

        func makeUniqueWidgetId(sectionId: String, _ id: String) -> String {
            if var count = widgetIds[id] {
                count += 1
                widgetIds[id] = count
                return "applin-\(sectionId)-\(count)-\(id)"
            } else {
                widgetIds[id] = 0
                return id
            }
        }

        var unnamedSectionCount = 0

        func nextUnnamedSectionName() -> String {
            unnamedSectionCount += 1
            return "applin-unnamed-section-\(unnamedSectionCount)"
        }

        for (optSectionName, widgetDatas) in self.inner.data.sections {
            let sectionId = makeUniqueSectionId(optSectionName ?? nextUnnamedSectionName())
            snapshot.appendSections([sectionId])
            var generatedKeyCount = 0

            func nextGeneratedKey() -> String {
                generatedKeyCount += 1
                return "\(sectionId)-\(generatedKeyCount)"
            }

            snapshot.appendItems(widgetDatas.map() { widgetData in

                makeUniqueWidgetId(sectionId: sectionId, widgetData.inner().keys().first ?? nextGeneratedKey())
            })
        }
        self.apply(snapshot)
    }

    // UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        self.inner.data.sections.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        self.inner.data.sections.get(section)?.0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.inner.data.sections.get(section)?.1.count ?? 0
    }

    // This does not remove the top padding for UITableView.Style.grouped.

    // func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    //     if section == 0 {
    //         return 0.0
    //     } else {
    //         return UITableView.automaticDimension
    //     }
    // }
}

class FormWidget: NSObject, UITableViewDelegate, WidgetProto {
    let pageKey: String
    var dataSource: FormWidgetDataSource!
    var tableView: KeyboardAvoidingTableView!

    init(_ session: ApplinSession, _ cache: WidgetCache, _ pageKey: String, _ data: FormData) {
        self.pageKey = pageKey
        let tableView = KeyboardAvoidingTableView(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(ErrorCell.self, forCellReuseIdentifier: ErrorCell.REUSE_ID)
        tableView.register(DisclosureCell.self, forCellReuseIdentifier: DisclosureCell.REUSE_ID)
        tableView.register(DisclosureSubtextCell.self, forCellReuseIdentifier: DisclosureSubtextCell.REUSE_ID)
        tableView.register(DisclosureImageCell.self, forCellReuseIdentifier: DisclosureImageCell.REUSE_ID)
        tableView.register(DisclosureImageSubtextCell.self, forCellReuseIdentifier: DisclosureImageSubtextCell.REUSE_ID)
        tableView.register(TextCell.self, forCellReuseIdentifier: TextCell.REUSE_ID)
        tableView.register(WidgetCell.self, forCellReuseIdentifier: WidgetCell.REUSE_ID)
        tableView.contentInsetAdjustmentBehavior = .never // Only works for UITableView.Style.plain.
        tableView.keyboardDismissMode = .interactive
        // tableView.allowsSelection = true
        // tableView.allowsMultipleSelection = false
        // tableView.selectionFollowsFocus = true
        // tableView.isUserInteractionEnabled = true
        self.dataSource = FormWidgetDataSource(session, cache, tableView, data)
        // tableView.dataSource = dataSource
        self.tableView = tableView
        super.init()
        self.tableView.delegate = self
        self.dataSource.update(data)
    }

    func keys() -> [String] {
        self.dataSource.inner.data.keys()
    }

    func getView() -> UIView {
        return self.tableView
    }

    // UITableViewDelegate

    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        self.dataSource.inner.getWidgetData(indexPath)?.inner().canTap() ?? false
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // print("form didSelectRowAt \(indexPath.section).\(indexPath.row)")
        if let inner = self.dataSource.inner.getWidgetData(indexPath)?.inner(),
           let session = self.dataSource.inner.weakSession,
           let cache = self.dataSource.inner.weakCache {
            inner.tap(session, cache)
        }
        self.tableView.deselectRow(at: indexPath, animated: false)
    }
}
