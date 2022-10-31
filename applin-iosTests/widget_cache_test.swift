import XCTest
import UIKit
@testable import applin_ios

class WidgetCacheTests: XCTestCase {
    func testSimple() throws {
        let session = ApplinSession(nil, nil, nil, URL(string: "https://test1/")!)
        let cache = WidgetCache()
        let widget1 = cache.updateAll(session, .text(TextData("t1"))) as! TextWidget
        XCTAssertEqual(widget1.label.text, "t1")
        let widget2 = cache.updateAll(session, .text(TextData("t2"))) as! TextWidget
        XCTAssert(widget1 === widget2)
        XCTAssertEqual(widget2.label.text, "t2")
    }

    func testStateless() throws {
        let session = ApplinSession(nil, nil, nil, URL(string: "https://test1/")!)
        let cache = WidgetCache()
        let column1 = cache.updateAll(
                session,
                .column(ColumnData([.text(TextData("t1"))], .start, spacing: 0.0))
        ) as! ColumnWidget
        let label1 = column1.view.subviews.first!.subviews.first! as! UILabel
        XCTAssertEqual(label1.text, "t1")
        let column2 = cache.updateAll(
                session,
                .column(ColumnData([.text(TextData("t2")), .text(TextData("t1"))], .start, spacing: 0.0))
        ) as! ColumnWidget
        XCTAssert(column1 !== column2)
        let label2a = column2.view.subviews[0].subviews.first as! UILabel
        let label2b = column2.view.subviews[1].subviews.first as! UILabel
        XCTAssert(label1 !== label2a)
        XCTAssertEqual(label2a.text, "t2")
        XCTAssert(label1 === label2b)
        XCTAssertEqual(label2b.text, "t1")
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
}
