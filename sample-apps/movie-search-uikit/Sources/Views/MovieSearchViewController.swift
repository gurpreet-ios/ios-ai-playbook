// MovieSearchViewController.swift
// Views layer — dumb renderer for SearchState. No navigation, no
// networking, no business logic: bind, render, forward events.

import UIKit

/// The search screen: a `UISearchController` feeding keystrokes to the
/// ViewModel, and a diffable-data-source collection view rendering whatever
/// `SearchState` comes back.
final class MovieSearchViewController: UIViewController {

    // MARK: Types

    private enum Section {
        case results
    }

    // MARK: Dependencies

    private let viewModel: MovieSearchViewModel
    private let imageLoader: ImageLoading

    // MARK: UI

    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Section, Movie>!
    private let searchController = UISearchController(searchResultsController: nil)
    private let statusView = EmptyStateView()
    private let activityIndicator = UIActivityIndicatorView(style: .large)

    // MARK: Initialisation

    init(viewModel: MovieSearchViewModel, imageLoader: ImageLoading) {
        self.viewModel = viewModel
        self.imageLoader = imageLoader
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Programmatic UI only — init(coder:) is not supported.")
    }

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Movies"
        view.backgroundColor = .systemBackground
        configureCollectionView()
        configureSearchController()
        configureDataSource()
        bindViewModel()
    }

    // MARK: Configuration

    private func configureCollectionView() {
        let configuration = UICollectionLayoutListConfiguration(appearance: .plain)
        let layout = UICollectionViewCompositionalLayout.list(using: configuration)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.delegate = self
        collectionView.keyboardDismissMode = .onDrag
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func configureSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search movies"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }

    private func configureDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<MovieCell, Movie> {
            [imageLoader] cell, _, movie in
            cell.configure(with: movie, imageLoader: imageLoader)
        }

        dataSource = UICollectionViewDiffableDataSource<Section, Movie>(
            collectionView: collectionView
        ) { collectionView, indexPath, movie in
            collectionView.dequeueConfiguredReusableCell(
                using: cellRegistration,
                for: indexPath,
                item: movie
            )
        }
    }

    // MARK: Binding

    private func bindViewModel() {
        viewModel.state.bind { [weak self] state in
            self?.render(state)
        }
    }

    // MARK: Rendering

    private func render(_ state: SearchState) {
        switch state {
        case .idle:
            applySnapshot(movies: [])
            showStatus(
                title: "Find a movie",
                message: "Search by title to get started.",
                systemImage: "magnifyingglass"
            )

        case .loading:
            statusView.removeFromSuperview()
            showActivityIndicator()

        case .loaded(let movies):
            hideOverlays()
            applySnapshot(movies: movies)

        case .empty(let query):
            applySnapshot(movies: [])
            showStatus(
                title: "No results",
                message: "Nothing matched “\(query)”. Try another title.",
                systemImage: "film"
            )

        case .failed(let message):
            applySnapshot(movies: [])
            showStatus(
                title: "Something went wrong",
                message: message,
                systemImage: "exclamationmark.triangle"
            )
        }
    }

    private func applySnapshot(movies: [Movie]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Movie>()
        snapshot.appendSections([.results])
        snapshot.appendItems(movies, toSection: .results)
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    // MARK: Overlays

    private func showStatus(title: String, message: String, systemImage: String) {
        activityIndicator.stopAnimating()
        statusView.configure(title: title, message: message, systemImage: systemImage)
        collectionView.backgroundView = statusView
    }

    private func showActivityIndicator() {
        collectionView.backgroundView = nil
        if activityIndicator.superview == nil {
            activityIndicator.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(activityIndicator)
            NSLayoutConstraint.activate([
                activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ])
        }
        activityIndicator.startAnimating()
    }

    private func hideOverlays() {
        activityIndicator.stopAnimating()
        collectionView.backgroundView = nil
    }
}

// MARK: - UISearchResultsUpdating

extension MovieSearchViewController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        viewModel.searchTextDidChange(searchController.searchBar.text ?? "")
    }
}

// MARK: - UICollectionViewDelegate

extension MovieSearchViewController: UICollectionViewDelegate {

    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        collectionView.deselectItem(at: indexPath, animated: true)
        viewModel.didSelectMovie(dataSource.itemIdentifier(for: indexPath))
    }
}
