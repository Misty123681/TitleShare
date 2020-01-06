// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import UIKit

class AudiobookDetailsViewController: UIViewController {
    @IBOutlet var mainButton: PrimaryButton!
    @IBOutlet var coverImageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var subtitleLabel: UILabel!
    @IBOutlet var authorLabel: UILabel!
    @IBOutlet var narratorLabel: UILabel!
    @IBOutlet var publisherLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!

    var audiobook: Audiobook!
    private let resources: Resource = Resource()

    override func viewDidLoad() {
        super.viewDidLoad()

        audiobook.fetchLargeCoverImage()
        // Show the small image (if possible) when the large image isn't yet available
        if audiobook.largeCoverImageFileResource.value?.state.value.fileURL == nil, let fileURL = audiobook.smallCoverImageFileResource.value?.state.value.fileURL {
            coverImageView.image = (try? Data(contentsOf: fileURL)).flatMap({ UIImage(data: $0) })
        }
        resources.aggregate(resource: audiobook.largeCoverImageFileResource.watch(invokeNow: true) { [weak self] fileResource in
            guard let self = self, let fileResource = fileResource else { return }
            self.resources.aggregate(resource: fileResource.state.watch(invokeNow: true) { [weak self] state in
                guard let self = self else { return }
                guard let data = state.fileURL.flatMap({ try? Data(contentsOf: $0) }).flatMap({ UIImage(data: $0) }) else { return }
                self.coverImageView.image = data
            })
        })

        resources.aggregate(resource: audiobook.metadata.watch(invokeNow: true) { [weak self] metadata in
            guard let self = self else { return }
            self.titleLabel.text = metadata.title
            self.subtitleLabel.text = metadata.subtitle
            self.authorLabel.text =  metadata.author.isEmpty ? "" : "Author: " + metadata.author
            self.narratorLabel.text = metadata.narrator.isEmpty ? "" : "Narrator: " + metadata.narrator
            self.publisherLabel.text = metadata.publisher.isEmpty ? "" : "Publisher: " + metadata.publisher
            self.descriptionLabel.text = metadata.desc
        })

        let mainButtonTitle = audiobook.audiobookSections.value != nil
            ? "LISTEN NOW"
            : "DOWNLOAD"

        if let mainButton = mainButton {
            mainButton.setTitle(mainButtonTitle, for: .normal)
        }
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        switch segue.identifier {
        case "audiobookPlayer":
            guard let destination = segue.destination as? AudiobookPlayerViewController else { fatalError("Unexpected destination: \(segue.destination)") }
            destination.audiobook = audiobook
            break
        default:
            break
        }
    }

    // MARK: Actions

    @IBAction func mainActionTouchUp(_: UIButton) {
        if audiobook.audiobookSections.value != nil {
            performSegue(withIdentifier: "audiobookPlayer", sender: self)
        } else {
            audiobook.fetchAudiobookSections()
            navigationController?.popViewController(animated: true)
        }
    }
}
