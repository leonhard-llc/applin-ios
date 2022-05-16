import Foundation
import SwiftUI

// TODO: Merge with Expand, Wide, & Tall?
struct MaggieSpacer: Equatable, Hashable, View {
    static let TYP = "spacer"

    var body: some View {
        Spacer()
                .background(Color.teal)
    }
}
