// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import Apollo
import Foundation

class AudiobookSection {
    public let title: String
    public let narrationFileResource: FileResource
    public let soundtrackFileResource: FileResource?

    convenience init(from memento: Memento, fileResourceController: FileResourceController) {
        self.init(title: memento.title, narrationRemoteURL: memento.narrationRemoteURL, soundtrackRemoteURL: memento.soundtrackRemoteURL, fileResourceController: fileResourceController)
    }

    init(title: String, narrationRemoteURL: URL, soundtrackRemoteURL: URL?, fileResourceController: FileResourceController) {
        self.title = title
        narrationFileResource = fileResourceController.fileResource(remoteURL: narrationRemoteURL, encrypted: true)
        soundtrackFileResource = soundtrackRemoteURL.map({ fileResourceController.fileResource(remoteURL: $0, encrypted: true) })
    }
}

extension AudiobookSection {
    struct Memento: Codable {
        let title: String
        let narrationRemoteURL: URL
        let soundtrackRemoteURL: URL?
    }

    var memento: Memento {
        return Memento(title: title, narrationRemoteURL: narrationFileResource.remoteURL, soundtrackRemoteURL: soundtrackFileResource?.remoteURL)
    }
}
