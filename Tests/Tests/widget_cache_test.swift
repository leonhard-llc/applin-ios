import XCTest
import UIKit
@testable import ApplinIos

class WidgetCacheTests: XCTestCase {
    var optTempDir: String?
    var config: ApplinConfig?
    var ctx: PageContext?

    override func setUpWithError() throws {
        let tempDir = NSTemporaryDirectory() + "/" + UUID().uuidString
        try FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
        self.optTempDir = tempDir
        self.config = try ApplinConfig(
                appStoreAppId: 0,
                showPageOnFirstStartup: "/",
                staticPages: [
                    // Required
                    StaticPageKeys.APPLIN_CLIENT_ERROR: StaticPages.applinClientError,
                    StaticPageKeys.APPLIN_PAGE_NOT_LOADED: StaticPages.pageNotLoaded,
                    StaticPageKeys.APPLIN_NETWORK_ERROR: StaticPages.applinNetworkError,
                    StaticPageKeys.APPLIN_SERVER_ERROR: StaticPages.applinServerError,
                    StaticPageKeys.APPLIN_STATE_LOAD_ERROR: StaticPages.applinStateLoadError,
                    StaticPageKeys.APPLIN_USER_ERROR: StaticPages.applinUserError,
                ],
                urlForDebugBuilds: URL(string: "https://test1/")!,
                urlForSimulatorBuilds: URL(string: "https://test1/")!,
                licenseKey: nil)
        self.ctx = PageContext(nil, hasPrevPage: false, pageKey: "/", nil, nil, nil)
    }

    override func tearDownWithError() throws {
        if let tempDir = self.optTempDir {
            try FileManager.default.removeItem(atPath: tempDir)
        }
    }

    func testSimple() throws {
        let cache = WidgetCache()
        let widget1 = cache.updateAll(
                self.ctx!,
                ButtonSpec(text: "b1", []).toSpec()
        ) as! ButtonWidget
        XCTAssertEqual(widget1.button.currentTitle, "  b1  ")
        let widget2 = cache.updateAll(
                self.ctx!,
                ButtonSpec(text: "b2", []).toSpec()
        ) as! ButtonWidget
        XCTAssert(widget1 === widget2)
        XCTAssertEqual(widget2.button.currentTitle, "  b2  ")
    }

    func testStatefulWithoutKey() throws {
        let cache = WidgetCache()
        let scroll1 = cache.updateAll(
                self.ctx!,
                ScrollSpec(TextSpec("t1")).toSpec()
        ) as! ScrollWidget
        let label1 = scroll1.scrollView.subviews.last! as! PaddedLabel
        XCTAssertEqual(label1.text, "t1")
        let scroll2 = cache.updateAll(
                self.ctx!,
                ScrollSpec(TextSpec("t2")).toSpec()
        ) as! ScrollWidget
        XCTAssert(scroll1 === scroll2)
        let label2 = scroll1.scrollView.subviews.last! as! PaddedLabel
        XCTAssertEqual(label2.text, "t2")
        XCTAssert(label1 === label2)
    }

    func testStateless() throws {
        let cache = WidgetCache()
        let column1 = cache.updateAll(
                self.ctx!,
                ColumnSpec([TextSpec("t1")]).toSpec()
        ) as! ColumnWidget
        let label1 = column1.columnView.orderedSubviews.first!.subviews.first! as! Label
        XCTAssertEqual(label1.text, "t1")
        let column2 = cache.updateAll(
                self.ctx!,
                ColumnSpec([TextSpec("t2"), TextSpec("t1")]).toSpec()
        ) as! ColumnWidget
        XCTAssert(column1 === column2)
        let label2a = column2.columnView.orderedSubviews[0].subviews.first as! Label
        let label2b = column2.columnView.orderedSubviews[1].subviews.first as! Label
        XCTAssert(label1 !== label2a)
        XCTAssertEqual(label2a.text, "t2")
        XCTAssert(label1 === label2b)
        XCTAssertEqual(label2b.text, "t1")
    }

    func testImageLabelBug() throws {
        let cache = WidgetCache()
        let column1 = cache.updateAll(
                self.ctx!,
                ColumnSpec([TextSpec("t2"), TextSpec("t1")]).toSpec()
        ) as! ColumnWidget
        let label1 = column1.columnView.orderedSubviews.first!.subviews.first! as! Label
        XCTAssertEqual(label1.text, "t1")
        let column2 = cache.updateAll(
                self.ctx!,
                ColumnSpec([TextSpec("t2"), TextSpec("t1")]).toSpec()
        ) as! ColumnWidget
        XCTAssert(column1 === column2)
        let label2a = column2.columnView.orderedSubviews[0].subviews.first as! Label
        let label2b = column2.columnView.orderedSubviews[1].subviews.first as! Label
        XCTAssert(label1 !== label2a)
        XCTAssertEqual(label2a.text, "t2")
        XCTAssert(label1 === label2b)
        XCTAssertEqual(label2b.text, "t1")
    }

    // TODO(mleonhard) Test stateful widget updates.
    // TODO(mleonhard) Test focusable widget updates.
    // TODO(mleonhard) Test matching order: focused, focusable, stateful, stateless.

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
}
