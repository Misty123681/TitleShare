// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import UIKit

class AudiobooksCollectionCell: UICollectionViewCell {
    @IBOutlet var coverImage: UIImageView! {
        didSet {
            let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(primaryAction))
            gestureRecognizer.numberOfTapsRequired = 1
            coverImage.addGestureRecognizer(gestureRecognizer)
        }
    }

    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var playableLabel: UILabel! {
        didSet {
            playableLabel.textColor = AppColor.appAqua
            playableLabel.shadowColor = UIColor.black
        }
    }

    @IBOutlet var updatableView: UIView! {
        didSet {
            updatableView.backgroundColor = AppColor.appPink
            updatableView.alpha = 0.8
        }
    }

    @IBOutlet var circleProgressBar: CircleProgressBar! {
        didSet {
            circleProgressBar.startAngle = -90
            circleProgressBar.progressBarProgressColor = AppColor.appAqua
        }
    }

    @IBOutlet var secondaryActionImage: UIImageView! {
        didSet {
            let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(secondaryAction))
            gestureRecognizer.numberOfTapsRequired = 1
            secondaryActionImage.addGestureRecognizer(gestureRecognizer)
        }
    }

    private var _perAudiobookResources: Resource?
    private var _perAudiobookCoverImageResource: Resource?
    private var _animateProgressUpdate: Bool = false

    var viewModel: AudiobookCellViewModel! {
        didSet {
            _perAudiobookResources = nil
            _perAudiobookCoverImageResource = nil
            guard let viewModel = viewModel else { return }
            _animateProgressUpdate = false
            let perAudiobookResources = Resource()
            perAudiobookResources.aggregate(resource: viewModel.title.watch(invokeNow: true) { [weak self] in
                self?.titleLabel.text = $0
            })
            perAudiobookResources.aggregate(resource: viewModel.state.watch(invokeNow: true) { [weak self] in
                self?.adjustForState(state: $0)
            })
            perAudiobookResources.aggregate(resource: viewModel.coverImageFileResource.watch(invokeNow: true) { [weak self] in
                guard let self = self else { return }
                if let fileResource = $0 {
                    self._perAudiobookCoverImageResource = fileResource.state.watch(invokeNow: true, watchHandler: { [weak self] state in
                        guard let self = self else { return }
                        let image = state.fileURL.flatMap({ try? Data(contentsOf: $0) }).flatMap({ UIImage(data: $0) })
                        self.setCoverImage(image: image)
                    })
                } else {
                    self._perAudiobookCoverImageResource = nil
                    self.setCoverImage(image: nil)
                }
            })
            _perAudiobookResources = perAudiobookResources
        }
    }

    override func traitCollectionDidChange(_: UITraitCollection?) {
        adjustForCurrentTraitCollection()
    }

    private func adjustForCurrentTraitCollection() {
        switch traitCollection.horizontalSizeClass {
        case .regular:
            circleProgressBar.hintTextFont = UIFont(name: "Avenir-Medium", size: 20)
            break
        case .compact, .unspecified:
            circleProgressBar.hintTextFont = UIFont(name: "Avenir-Medium", size: 20)
            break
        }
    }

    private func setCoverImage(image: UIImage?) {
        if let image = image {
            titleLabel.isHidden = true
            coverImage.image = image
        } else {
            titleLabel.isHidden = false
            coverImage.image = UIImage(named: "views_AudiobooksCollectionCell_coverImagePlaceholder")!
        }
    }

    private func adjustForState(state: AudiobookCellViewModel.State) {
        updatableView.isHidden = !state.downloadedAndUpdatable

        switch state.secondaryAction {
        case .download:
            secondaryActionImage.image = UIImage(named: "views_AudiobooksCollectionCell_downloadBadge")!
            secondaryActionImage.contentMode = .scaleAspectFill
        case .more:
            secondaryActionImage.image = UIImage(named: "views_AudiobooksCollectionCell_moreBadge")!
            secondaryActionImage.contentMode = .topRight
        case .remove:
            secondaryActionImage.image = UIImage(named: "views_AudiobooksCollectionCell_removeBadge")!
            secondaryActionImage.contentMode = .topRight
        }

        playableLabel.isHidden = !state.downloadingButPlayable

        if let progress = state.progress {
            circleProgressBar.isHidden = false
            // First progress display for a given assigned audiobook must not be animated
            circleProgressBar.setProgress(CGFloat(progress), animated: _animateProgressUpdate)
            // but subsequent progress display can be animated (until audiobook reassignment)
            _animateProgressUpdate = true
        } else {
            circleProgressBar.isHidden = true
        }
    }

    @IBAction func moreInfoAction() {
        viewModel.presentAudiobookDetails()
    }

    @objc func primaryAction() {
        viewModel.performPrimaryAction()
    }

    @objc func secondaryAction() {
        viewModel.performSecondaryAction(originatingLocation: .viewRect(view: coverImage, rect: CGRect(x: coverImage.bounds.midX, y: coverImage.bounds.midY, width: 0, height: 0)))
    }
}
