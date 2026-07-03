// MovieDetailViewController.swift
// Views layer — scrolling detail screen with a bindable favorite button.

import UIKit

/// Shows one movie: poster, title, metadata, overview, and a star button in
/// the navigation bar whose state is bound to the ViewModel.
final class MovieDetailViewController: UIViewController {

    // MARK: Dependencies

    private let viewModel: MovieDetailViewModel
    private let imageLoader: ImageLoading

    // MARK: UI

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let posterImageView = UIImageView()
    private let titleLabel = UILabel()
    private let metadataLabel = UILabel()
    private let overviewLabel = UILabel()
    private var favoriteButton: UIBarButtonItem!

    /// Poster download, cancelled if the screen is popped mid-flight.
    private var imageTask: Task<Void, Never>?

    // MARK: Initialisation

    init(viewModel: MovieDetailViewModel, imageLoader: ImageLoading) {
        self.viewModel = viewModel
        self.imageLoader = imageLoader
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Programmatic UI only — init(coder:) is not supported.")
    }

    deinit {
        imageTask?.cancel()
    }

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.largeTitleDisplayMode = .never
        configureLayout()
        configureFavoriteButton()
        populate()
        bindViewModel()
    }

    // MARK: Configuration

    private func configureLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.alignment = .fill
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        posterImageView.contentMode = .scaleAspectFill
        posterImageView.clipsToBounds = true
        posterImageView.layer.cornerRadius = 12
        posterImageView.backgroundColor = .secondarySystemBackground
        posterImageView.image = UIImage(systemName: "film")
        posterImageView.tintColor = .tertiaryLabel
        posterImageView.isAccessibilityElement = true

        titleLabel.font = .preferredFont(forTextStyle: .title1)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = 0

        metadataLabel.font = .preferredFont(forTextStyle: .subheadline)
        metadataLabel.adjustsFontForContentSizeCategory = true
        metadataLabel.textColor = .secondaryLabel

        overviewLabel.font = .preferredFont(forTextStyle: .body)
        overviewLabel.adjustsFontForContentSizeCategory = true
        overviewLabel.numberOfLines = 0

        [posterImageView, titleLabel, metadataLabel, overviewLabel].forEach {
            contentStack.addArrangedSubview($0)
        }

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -16),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32),

            // 2:3 poster ratio, standard for movie one-sheets.
            posterImageView.heightAnchor.constraint(equalTo: posterImageView.widthAnchor, multiplier: 1.5)
        ])
    }

    private func configureFavoriteButton() {
        favoriteButton = UIBarButtonItem(
            image: UIImage(systemName: "star"),
            style: .plain,
            target: self,
            action: #selector(favoriteTapped)
        )
        navigationItem.rightBarButtonItem = favoriteButton
    }

    // MARK: Population

    private func populate() {
        title = viewModel.titleText
        titleLabel.text = viewModel.titleText
        metadataLabel.text = viewModel.metadataText
        overviewLabel.text = viewModel.overviewText
        posterImageView.accessibilityLabel = "Poster for \(viewModel.titleText)"

        if let url = viewModel.movie.posterURL {
            imageTask = Task { [weak self, imageLoader] in
                guard let image = try? await imageLoader.image(from: url),
                      !Task.isCancelled else { return }
                self?.posterImageView.contentMode = .scaleAspectFill
                self?.posterImageView.image = image
            }
        }
    }

    // MARK: Binding

    private func bindViewModel() {
        viewModel.isFavorite.bind { [weak self] isFavorite in
            self?.renderFavorite(isFavorite)
        }
    }

    private func renderFavorite(_ isFavorite: Bool) {
        favoriteButton.image = UIImage(systemName: isFavorite ? "star.fill" : "star")
        favoriteButton.accessibilityLabel = isFavorite
            ? "Remove from favorites"
            : "Add to favorites"
    }

    // MARK: Actions

    @objc private func favoriteTapped() {
        viewModel.toggleFavorite()
    }
}
