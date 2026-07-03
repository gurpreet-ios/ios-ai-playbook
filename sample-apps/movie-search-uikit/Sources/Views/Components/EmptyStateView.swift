// EmptyStateView.swift
// Views/Components — one placeholder view for idle, empty, and error states.

import UIKit

/// Centered icon + title + message, used as the collection view's
/// `backgroundView` for every non-content `SearchState`.
final class EmptyStateView: UIView {

    // MARK: UI

    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()

    // MARK: Initialisation

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Programmatic UI only — init(coder:) is not supported.")
    }

    // MARK: Layout

    private func configureLayout() {
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = .tertiaryLabel
        iconImageView.preferredSymbolConfiguration = .init(textStyle: .largeTitle, scale: .large)

        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textAlignment = .center

        messageLabel.font = .preferredFont(forTextStyle: .subheadline)
        messageLabel.adjustsFontForContentSizeCategory = true
        messageLabel.textColor = .secondaryLabel
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [iconImageView, titleLabel, messageLabel])
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -32)
        ])
    }

    // MARK: Configuration

    func configure(title: String, message: String, systemImage: String) {
        iconImageView.image = UIImage(systemName: systemImage)
        titleLabel.text = title
        messageLabel.text = message

        isAccessibilityElement = true
        accessibilityLabel = "\(title). \(message)"
    }
}
