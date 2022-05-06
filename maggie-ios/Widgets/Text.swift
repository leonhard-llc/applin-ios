import Foundation
import SwiftUI

struct MaggieText: Equatable, Hashable, View {
    static let TYP = "text"
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    init(_ item: JsonItem) throws {
        self.text = try item.takeText()
    }
    
    func toJsonItem() -> JsonItem {
        let item = JsonItem(MaggieText.TYP)
        item.text = self.text
        return item
    }
    
    var body: some View {
        Text(self.text)
            .padding(1.0)
            .border(Color.yellow)
            .padding(1.0)
    }
}
