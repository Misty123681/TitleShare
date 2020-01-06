// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import Apollo
import Foundation
import os

class Model {
    let audiobookRegistry: AudiobookRegistry
    let fileResourceController: FileResourceController
    let userAudiobooks: UserAudiobooks
    let userState: UserState
    private let modelFileURL: URL
    private let _log = OSLog()

    init(userController: UserController, audiobooksController: AudiobooksController, applicationFileURLs: ApplicationFileURLs, authenticationController: AuthenticationController, cryptController: CryptController) {
        modelFileURL = applicationFileURLs.modelFileURL
        let memento = Model.load(modelFileURL: modelFileURL)
        // Note: fileResources and audiobooks strongly retain the decoded entities during this early phase (auto release makes this all a bit moot, but explicit is better)
        var fileResources: [FileResource] = []
        fileResourceController = FileResourceController(from: memento?.fileResourceController, intoOwnedFileResources: &fileResources, authenticationController: authenticationController, fileResourceDirectoryURL: applicationFileURLs.fileResourceDirectoryURL, cryptController: cryptController)
        applicationFileURLs.cleanFileResourceDirectory(fileResourcesToKeep: fileResources)
        applicationFileURLs.cleanSupersededCaches()
        var audiobooks: [Audiobook] = []
        audiobookRegistry = AudiobookRegistry(from: memento?.audiobookRegistry, intoOwnedAudiobooks: &audiobooks, audiobooksController: audiobooksController, fileResourceController: fileResourceController)
        userAudiobooks = UserAudiobooks(from: memento?.userAudiobooks, audiobooksController: audiobooksController, audiobookRegistry: audiobookRegistry, fileResourceController: fileResourceController)
        userState = UserState(from: memento?.userState, userController: userController)

        // Unnecessary, but here for clarity
        audiobooks.removeAll()
        fileResources.removeAll()
    }
}

extension Model {
    struct Memento: Codable {
        let fileResourceController: FileResourceController.Memento
        let audiobookRegistry: AudiobookRegistry.Memento
        let userAudiobooks: UserAudiobooks.Memento
        let userState: UserState.Memento
    }

    var memento: Memento {
        return Memento(fileResourceController: fileResourceController.memento, audiobookRegistry: audiobookRegistry.memento, userAudiobooks: userAudiobooks.memento, userState: userState.memento)
    }

    public func save() {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(memento)
            try data.write(to: modelFileURL, options: [.atomic])
        } catch {
            // Intentionally do nothing
            os_log("Error saving model. %@", log: _log, type: .error, String(describing: error))
        }
    }

    fileprivate static func load(modelFileURL: URL) -> Memento? {
        do {
            guard let data = try? Data(contentsOf: modelFileURL) else { return nil }
            let decoder = JSONDecoder()
            return try decoder.decode(Memento.self, from: data)
        } catch {
            // This path really shouldn't happen
            os_log("Error loading model. %@", log: OSLog(), type: .error, String(describing: error))
            return nil
        }
    }
}
