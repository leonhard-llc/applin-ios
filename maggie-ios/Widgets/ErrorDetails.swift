import Foundation
import SwiftUI

struct MaggieErrorDetails: Equatable, Hashable, View {
    static let TYP = "error-details"
    let error: String

    init(_ session: MaggieSession) {
        self.error = session.error ?? "no error"
    }

    var body: some View {
        Text(self.error)
    }
}
