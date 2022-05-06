import Foundation
import SwiftUI

struct MaggieSpinner: Equatable, Hashable, View {
    static let TYP = "spinner"
    
    var body: some View {
        ProgressView()
    }
}
