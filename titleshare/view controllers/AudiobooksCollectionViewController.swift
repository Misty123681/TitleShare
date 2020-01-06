// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import MaterialComponents.MaterialSnackbar
import UIKit

fileprivate let snackbarCategory = "audiobooksFetchIssue"

class AudiobooksCollectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, AudiobookCellViewModelDelegate {
    var model: Model!
    var viewDidLoadAction: (() ->  Void)?
    @IBOutlet private var sourceSegmentedControl: UISegmentedControl!
    @IBOutlet private var collectionView: UICollectionView!
    @IBOutlet private var collectionViewLayout: UICollectionViewFlowLayout!
    private var viewModel: AudiobooksCollectionViewModel!
    private var segueAudiobookTarget: Audiobook?
    private var watchAudiobooksResource: Resource = Resource()
    private var resources = Resource()
  
    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.register(UINib(nibName: "AudiobooksCollectionCell", bundle: nil), forCellWithReuseIdentifier: "audiobook")
        collectionView.register(UINib(nibName: "AudiobooksCollectionHeaderCell", bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "sectionHeader")
        collectionView.refreshControl = UIRefreshControl()
        adjustCollectionViewLayout(totalWidth: view.frame.size.width)
        synchroniseSourceSegmentedControl()
        collectionView.reloadData()
        model.userAudiobooks.refresh()
        resources.aggregate(resource: model.userAudiobooks.state.watch(invokeNow: false) { state in
            MDCSnackbarManager.dismissAndCallCompletionBlocks(withCategory: snackbarCategory)
            if !state.fetching, let lastFetchError = state.lastFetchError {
                let message = MDCSnackbarMessage()
                switch lastFetchError {
                case .networkError:
                    message.text = "Failed to refresh due to a network issue"
                case .serverError:
                    message.text = "Failed to refresh due to a server issue"
                }
                if state.audiobooks != nil {
                    message.duration = 6.0
                } else {
                    // First app run, show the message for as long as possible
                    message.duration = MDCSnackbarMessageDurationMax
                }
                message.category = snackbarCategory
                MDCSnackbarManager.show(message)
            }
        })

        if let refreshControl = collectionView.refreshControl {
            refreshControl.addTarget(self, action: #selector(refresh(sender:)), for: UIControl.Event.valueChanged)
        }
        
        if let viewDidLoadAction = viewDidLoadAction {
            viewDidLoadAction()
        }
    }

    @objc func refresh(sender _: AnyObject) {
        model.userAudiobooks.refresh()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        adjustCollectionViewLayout(totalWidth: size.width)
    }

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        switch segue.identifier {
        case "audiobookDetails":
            guard let destination = segue.destination as? AudiobookDetailsViewController else { fatalError("Unexpected destination: \(segue.destination)") }
            guard let audiobook = segueAudiobookTarget else { fatalError("segueAudiobookTarget expected") }
            destination.audiobook = audiobook
            segueAudiobookTarget = nil
            break
        case "audiobookPlayer":
            guard let destination = segue.destination as? AudiobookPlayerViewController else { fatalError("Unexpected destination: \(segue.destination)") }
            guard let audiobook = segueAudiobookTarget else { fatalError("segueAudiobookTarget expected") }
            destination.audiobook = audiobook
            segueAudiobookTarget = nil
            break
        default:
            break
        }
    }
    
    // MARK: - UICollectionViewDataSource

    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        return viewModel.audiobooks.value.items.count
    }

    func collectionView(_: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let audiobookCollectionCell = collectionView.dequeueReusableCell(withReuseIdentifier: "audiobook", for: indexPath) as! AudiobooksCollectionCell
        audiobookCollectionCell.viewModel = viewModel.audiobooks.value.items[indexPath.item]
        return audiobookCollectionCell
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader else { fatalError() }
        let audiobookCollectionHeaderCell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "sectionHeader", for: indexPath) as! AudiobooksCollectionHeaderCell
        audiobookCollectionHeaderCell.dateFetched = viewModel.audiobooks.value.dateFetched
        return audiobookCollectionHeaderCell
    }

    // MARK: - UICollectionViewDelegate

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, referenceSizeForHeaderInSection _: Int) -> CGSize {
        if viewModel.showSectionHeader {
            return CGSize(width: 50, height: 50)
        } else {
            return CGSize(width: 50, height: 0)
        }
    }

    // MARK: - AudiobookCellViewModelDelegate

    func presentAudiobookDetails(audiobook: Audiobook) {
        segueAudiobookTarget = audiobook
        performSegue(withIdentifier: "audiobookDetails", sender: self)
    }

    func presentAudiobookPlayer(audiobook: Audiobook) {
        segueAudiobookTarget = audiobook
        performSegue(withIdentifier: "audiobookPlayer", sender: self)
    }

    func confirmAudiobookAction(originatingLocation: OriginatingLocation, removeAction: AudiobookCellViewModelDelegateRemoveAction, updateAction: (() -> Void)?) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        switch removeAction {
        case let .cancelDownloadAndRemoveFromDevice(action):
            alertController.addAction(UIAlertAction(title: "Cancel download", style: .destructive, handler: { _ in action() }))
        case let .removeFromDevice(action):
            alertController.addAction(UIAlertAction(title: "Remove from device", style: .destructive, handler: { _ in action() }))
        }
        if let action = updateAction {
            alertController.addAction(UIAlertAction(title: "Update", style: .default, handler: { _ in action() }))
        }
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.setupPopoverPresentationController(originatingLocation: originatingLocation)
        present(alertController, animated: true, completion: nil)
    }

    // MARK: - Actions

    @IBAction func sourceSegmentedControlValueChanged() {
        synchroniseSourceSegmentedControl()
        collectionView.reloadData()
    }

    // MARK: - Internal

    private func synchroniseSourceSegmentedControl() {
        switch sourceSegmentedControl.selectedSegmentIndex {
        case 0:
            viewModel = UserCloudAudiobooksCollectionViewModel(userAudiobooks: model.userAudiobooks, audiobookCellViewModelDelegate: self)
            break
        case 1:
            viewModel = UserDeviceAudiobooksCollectionViewModel(userAudiobooks: model.userAudiobooks, audiobookCellViewModelDelegate: self)
            break
        default:
            fatalError()
        }
        watchAudiobooksResource = viewModel.audiobooks.watch(invokeNow: false) { [weak self] _ in
            self?.collectionView.reloadData()
            self?.collectionView.refreshControl?.endRefreshing()
        }
    }

    private func adjustCollectionViewLayout(totalWidth: CGFloat) {
        let columnCount: Int
        let externalPadding: CGFloat
        let internalPadding: CGFloat
        if totalWidth >= 1366 {
            columnCount = 5
            externalPadding = 100.0
            internalPadding = 44.0
        } else if totalWidth >= 769 {
            columnCount = 4
            externalPadding = 44.0
            internalPadding = externalPadding
        } else if totalWidth >= 600 {
            columnCount = 3
            externalPadding = 34.0
            internalPadding = externalPadding
        } else {
            columnCount = 2
            externalPadding = 24.0
            internalPadding = externalPadding
        }
        let totalInternalPadding = internalPadding * CGFloat(columnCount - 1)
        let totalExternalPadding = externalPadding * 2
        let cellWidth = ((totalWidth - totalExternalPadding - totalInternalPadding) / CGFloat(columnCount)).rounded(.down)
        let cellHeight = cellWidth + 60.0
        collectionViewLayout.minimumInteritemSpacing = internalPadding
        collectionViewLayout.minimumLineSpacing = internalPadding
        collectionViewLayout.sectionInset = UIEdgeInsets(top: externalPadding, left: externalPadding, bottom: externalPadding, right: externalPadding)
        collectionViewLayout.itemSize = CGSize(width: cellWidth, height: cellHeight)
    }
}
