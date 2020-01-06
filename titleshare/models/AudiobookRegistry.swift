// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import Apollo
import Foundation

/**
 Provides de-duplication and persistence of Audiobooks.
 */
class AudiobookRegistry {
    private let audiobooksController: AudiobooksController
    private var audiobooksById: [Audiobook.Id: WeakAudiobook] = [:]

    init(from memento: Memento?, intoOwnedAudiobooks: inout [Audiobook], audiobooksController: AudiobooksController, fileResourceController: FileResourceController) {
        self.audiobooksController = audiobooksController
        if let memento = memento {
            restore(from: memento, intoOwnedAudiobooks: &intoOwnedAudiobooks, audiobooksController: audiobooksController, fileResourceController: fileResourceController)
        }
    }

    public func audiobook(id: Audiobook.Id) -> Audiobook? {
        return audiobooksById[id]?.audiobook
    }

    func remember(audiobook: Audiobook) {
        assert(audiobooksById[audiobook.id] == nil)
        audiobooksById[audiobook.id] = WeakAudiobook(audiobook: audiobook)
    }

    func forget(audiobook: Audiobook) {
        assert(audiobooksById[audiobook.id] != nil)
        audiobooksById[audiobook.id] = nil
    }
}

extension AudiobookRegistry {
    struct Memento: Codable {
        let audiobooks: [Audiobook.Memento]
    }

    var memento: Memento {
        return Memento(audiobooks: audiobooksById.values.compactMap({ $0.audiobook?.memento }))
    }

    fileprivate func restore(from memento: Memento, intoOwnedAudiobooks: inout [Audiobook], audiobooksController: AudiobooksController, fileResourceController: FileResourceController) {
        intoOwnedAudiobooks = memento.audiobooks.map({ Audiobook(from: $0, audiobooksController: audiobooksController, audiobookRegistry: self, fileResourceController: fileResourceController) })
    }
}

fileprivate struct WeakAudiobook {
    weak var audiobook: Audiobook?
}
