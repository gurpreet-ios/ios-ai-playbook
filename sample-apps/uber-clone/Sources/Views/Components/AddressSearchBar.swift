// AddressSearchBar.swift
// UberClone – Views / Components
// iOS 17+ · Swift 6 · SwiftUI

import SwiftUI

// MARK: - AddressSearchBar

/// A styled text field for entering addresses (pickup / dropoff).
///
/// Pure presentation component — no business logic.
/// Uses `@Binding` for two-way data flow with the parent view.
struct AddressSearchBar: View {

    // MARK: - Properties

    @Binding var text: String

    let placeholder: String
    let icon: String

    // MARK: - Focus

    @FocusState private var isFocused: Bool

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            // Leading icon
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isFocused ? .blue : .secondary)
                .frame(width: 24, height: 24)

            // Text field
            TextField(placeholder, text: $text)
                .font(.body)
                .focused($isFocused)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()

            // Clear button
            if !text.isEmpty {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        text = ""
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(
                    isFocused ? Color.blue.opacity(0.5) : Color.clear,
                    lineWidth: 1.5
                )
        )
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .animation(.easeInOut(duration: 0.2), value: text.isEmpty)
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    VStack(spacing: 16) {
        AddressSearchBar(
            text: .constant("123 Main St"),
            placeholder: "Pickup location",
            icon: "circle.fill"
        )
        AddressSearchBar(
            text: .constant(""),
            placeholder: "Where to?",
            icon: "mappin.circle.fill"
        )
    }
    .padding()
}
#endif
