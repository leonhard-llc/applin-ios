import XCTest
import UIKit
@testable import applin_ios

class WidgetCacheTests: XCTestCase {
    var optTempDir: String?
    var config: ApplinConfig?
    var stateStore: StateStore?
    var session: ApplinSession?

    override func setUpWithError() throws {
        let tempDir = NSTemporaryDirectory() + "/" + UUID().uuidString
        try FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
        self.optTempDir = tempDir
        self.config = ApplinConfig(dataDirPath: tempDir, url: URL(string: "https://test1/")!)
        self.stateStore = StateStore(self.config!, ApplinState())
        self.session = ApplinSession(self.config!, self.stateStore!, nil, nil)
    }

    override func tearDownWithError() throws {
        if let tempDir = self.optTempDir {
            try FileManager.default.removeItem(atPath: tempDir)
        }
    }

    func testSimple() throws {
        let cache = WidgetCache()
        let widget1 = cache.updateAll(self.session!, Spec(.button(ButtonSpec(pageKey: "page1", text: "b1")))) as! ButtonWidget
        XCTAssertEqual(widget1.button.currentTitle, "  b1  ")
        let widget2 = cache.updateAll(self.session!, Spec(.button(ButtonSpec(pageKey: "page1", text: "b2")))) as! ButtonWidget
        XCTAssert(widget1 === widget2)
        XCTAssertEqual(widget2.button.currentTitle, "  b2  ")
    }

    func testStateless() throws {
        let cache = WidgetCache()
        let column1 = cache.updateAll(
                self.session!,
                Spec(.column(ColumnSpec([Spec(.text(TextSpec("t1")))], .start, spacing: 0.0)))
        ) as! ColumnWidget
        let label1 = column1.columnView.orderedSubviews.first!.subviews.first! as! UILabel
        XCTAssertEqual(label1.text, "t1")
        let column2 = cache.updateAll(
                self.session!,
                Spec(.column(ColumnSpec([Spec(.text(TextSpec("t2"))), Spec(.text(TextSpec("t1")))], .start, spacing: 0.0)))
        ) as! ColumnWidget
        XCTAssert(column1 !== column2)
        let label2a = column2.columnView.orderedSubviews[0].subviews.first as! UILabel
        let label2b = column2.columnView.orderedSubviews[1].subviews.first as! UILabel
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
