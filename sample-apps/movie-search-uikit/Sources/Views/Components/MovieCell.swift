// MovieCell.swift
// Views/Components — result row: poster thumbnail, title, year, rating.

import UIKit

/// Collection-view list cell for one search result.
///
/// The poster loads through the injected `ImageLoading` actor; the task is
/// cancelled in `prepareForReuse()` so fast scrolling never paints a stale
/// image into a recycled cell.
final class MovieCell: UICollectionViewCell {

    // MARK: UI

    private let posterImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    /// In-flight poster download for the currently-configured movie.
    private var imageTask: Task<Void, Never>?

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
        posterImageView.contentMode = .scaleAspectFill
        posterImageView.clipsToBounds = true
        posterImageView.layer.cornerRadius = 6
        posterImageView.backgroundColor = .secondarySystemBackground
        posterImageView.tintColor = .tertiaryLabel
        posterImageView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = 2

        subtitleLabel.font = .preferredFont(forTextStyle: .subheadline)
        subtitleLabel.adjustsFontForContentSizeCategory = true
        subtitleLabel.textColor = .secondaryLabel

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 4
        textStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(posterImageView)
        contentView.addSubview(textStack)

        NSLayoutConstraint.activate([
            posterImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            posterImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            posterImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            posterImageView.widthAnchor.constraint(equalToConstant: 48),
            posterImageView.heightAnchor.constraint(equalToConstant: 72),

            textStack.leadingAnchor.constraint(equalTo: posterImageView.trailingAnchor, constant: 12),
            textStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            textStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    // MARK: Reuse

    override func prepareForReuse() {
        super.prepareForReuse()
        imageTask?.cancel()
        imageTask = nil
        posterImageView.image = nil
    }

    // MARK: Configuration

    func configure(with movie: Movie, imageLoader: ImageLoading) {
        titleLabel.text = movie.title

        let year = movie.releaseYear ?? "Year unknown"
        let rating = String(format: "★ %.1f", movie.rating)
        subtitleLabel.text = "\(year) · \(rating)"

        isAccessibilityElement = true
        accessibilityLabel = "\(movie.title), \(year), rated \(String(format: "%.1f", movie.rating)) out of 10"
        accessibilityTraits = .button

        posterImageView.image = UIImage(systemName: "film")
        if let url = movie.posterURL {
            imageTask = Task { [weak self, imageLoader] in
                guard let image = try? await imageLoader.image(from: url),
                      !Task.isCancelled else { return }
                self?.posterImageView.image = image
            }
        }
    }
}
