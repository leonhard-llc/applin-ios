//import Foundation
//import SwiftUI
//import NiftyMarkdownFormatter
//
//enum MarkdownViewState {
//    case loading(Task<Void, Never>?)
//    case error(String)
//    case ok(String)
//}
//
//public struct MarkdownPageSpec: Equatable {
//    static func ==(lhs: MarkdownPageSpec, rhs: MarkdownPageSpec) -> Bool {
//        lhs.title == rhs.title
//                && lhs.url == rhs.url
//                && lhs.cache == rhs.cache
//    }
//
//    static let TYP = "markdown-page"
//    let title: String
//    let url: URL
//    let cache: Bool?
//    @State var state: MarkdownViewState = .loading(nil)
//
//    init(title: String, url: URL, cache: Bool? = nil) {
//        self.title = title
//        self.url = url
//        self.cache = cache
//    }
//
//    init(_ item: JsonItem, _ config: ApplinConfig) throws {
//        self.title = try item.requireTitle()
//        self.url = try item.requireUrl(config)
//        self.cache = item.cache
//    }
//
//    func toJsonItem() -> JsonItem {
//        let item = JsonItem(MarkdownPageSpec.TYP)
//        item.title = self.title
//        item.url = self.url.absoluteString
//        item.cache = self.cache
//        return item
//    }
//
//    func setError(_ msg: String) {
//        print(msg)
//        self.state = .error(msg)
//    }
//
//    func load() async {
//        do {
//            let urlSession = (self.cache ?? false)
//                    ? URLSession.shared : URLSession(configuration: URLSessionConfiguration.ephemeral)
//            let (data, urlResponse) = try await urlSession.data(from: self.url)
//            let response = urlResponse as! HTTPURLResponse
//            print("GET \(self.url) response: \(response), bodyLen=\(data.count)")
//            if response.statusCode != 200 {
//                let description = HTTPURLResponse.localizedString(
//                        forStatusCode: response.statusCode)
//                self.setError("\(response.statusCode) \(description)")
//                return
//            }
//            let contentType = response.value(forHTTPHeaderField: "content-type")?.lowercased() ?? ""
//            let base = contentType.split(
//                    separator: ";", maxSplits: 1, omittingEmptySubsequences: false)[0]
//            if base != "text/markdown" {
//                self.setError("Response is not text/markdown")
//                return
//            }
//            if data.count > 1 * 1024 * 1024 {
//                self.setError("Document is too big: \(data.count) bytes")
//                return
//            }
//            guard let string = String(data: data, encoding: String.Encoding.utf8) else {
//                self.setError("Response is not UTF-8")
//                return
//            }
//            self.state = .ok(string)
//        } catch {
//            print("ERROR GET \(self.url) : \(error)")
//            self.setError(error.localizedDescription)
//        }
//    }
//
//    func startLoad() {
//        switch self.state {
//        case .loading(.none), .error, .ok:
//            self.state = .loading(Task {
//                await self.load()
//            })
//        case .loading:
//            break
//        }
//    }
//
//    func stopLoad() {
//        if case let .loading(.some(task)) = self.state {
//            task.cancel()
//            self.state = .loading(nil)
//        }
//    }
//
//    public func toView(_ session: ApplinSession) -> AnyView {
//        switch self.state {
//        case .loading:
//            return AnyView(
//                    VStack {
//                        Spacer()
//                        ProgressView("Loading")
//                        Spacer()
//                        Button("Refresh") {
//                        }
//                                .disabled(true)
//                    }
//                            .onAppear(perform: self.startLoad)
//                            .onDisappear(perform: self.stopLoad)
//            )
//        case let .error(msg):
//            return AnyView(
//                    VStack {
//                        Spacer()
//                        Image(systemName: "xmark.octagon")
//                                .resizable()
//                                .aspectRatio(contentMode: .fit)
//                                .frame(width: 100)
//                        Text("ERROR")
//                        Text(msg).padding()
//                        Spacer()
//                        Button("Refresh") {
//                            self.startLoad()
//                        }
//                    })
//        case let .ok(markdown):
//            return AnyView(
//                    VStack {
//                        ScrollView(showsIndicators: true) {
//                            FormattedMarkdown(
//                                    markdown: markdown,
//                                    alignment: .leading,
//                                    spacing: 7.0
//                            )
//                                    .frame(maxWidth: .infinity, alignment: .leading)
//                                    .padding()
//                        }
//                        Button("Refresh") {
//                            self.startLoad()
//                        }
//                    })
//        }
//    }
//}
//
//class MarkdownPageController: UIHostingController<AnyView>, PageController {
//    var spec: MarkdownPageSpec?
//
//    func allowBackSwipe() -> Bool {
//        true
//    }
//
//    func update(
//            _ navController: NavigationController,
//            _ session: ApplinSession,
//            _ newSpec: MarkdownPageSpec
//    ) {
//        if newSpec == self.spec {
//            return
//        }
//        self.spec = newSpec
//        self.title = newSpec.title
//        self.rootView = newSpec.toView(session)
//    }
//}
