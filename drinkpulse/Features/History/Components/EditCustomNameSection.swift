import SwiftUI

struct EditCustomNameSection: View {
    @Binding var customName: String
    let categoryDefaultName: String

    var body: some View {
        Section(String(localized: "editDrink.customName")) {
            TextField(categoryDefaultName, text: $customName)
                .autocorrectionDisabled()
                .accessibilityLabel(String(localized: "editDrink.customName"))
        }
    }
}
