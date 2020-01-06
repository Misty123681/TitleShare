// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import AVFoundation
import Foundation
import MediaPlayer
import os

protocol AudiobookPlayerDelegate: class {
    func busyStateDidChange()
    func pauseStateDidChange()
    func audioSectionChanged(sectionIndex: Int)
}

class AudiobookPlayer: NSObject, AVAudioPlayerDelegate {
    
    struct AudiobookPosition {
        let audioSectionIndex: Int
        let time: Double
    }
    
    private let _log = OSLog()
    private let _audiobook: Audiobook
    private let _cryptController: CryptController
    private var _narrationAudioPlayer: AVAudioPlayer?
    private var _soundtrackAudioPlayer: AVAudioPlayer?
    private let _defaultNarrationVolume: Float
    private let _defaultSoundtrackVolume: Float
    private var _playbackRegions: [AudiobookPlaybackRegion]?
    private var _playbackStartedAt: AudiobookPosition?
    private var _decryptedNarrationSelfDestructingFile: CryptController.SelfDestructingFile?
    private var _decryptedSoundtrackSelfDestructingFile: CryptController.SelfDestructingFile?
    private let _logPlaybackQueue = DispatchQueue(label: "logPlaybackQueue")

    var currentSectionIndex: Int
    var totalAudioSections: Int
    weak var delegate: AudiobookPlayerDelegate?
    private let resources = Resource()
    private var playResources = Resource()

    private var _remoteCommandCenterPauseCommand: Any?
    private var _remoteCommandCenterPlayCommand: Any?
    private var _remoteCommandCenterTogglePlayPauseCommand: Any?
    private var _remoteCommandCenterSkipBackwardCommand: Any?
    private var _remoteCommandCenterSkipForwardCommand: Any?
    private var _remoteCommandCenterPreviousTrackCommand: Any?
    private var _remoteCommandCenterNextTrackCommand: Any?

    init(for audiobook: Audiobook, cryptController: CryptController) {
        _audiobook = audiobook
        _cryptController = cryptController
        currentSectionIndex = 0
        _playbackStartedAt = nil
        _playbackRegions = nil
        _defaultNarrationVolume = Float(1.0)
        _defaultSoundtrackVolume = Float(1.0)
        totalAudioSections = 0
        busy = false
        super.init()

        resources.aggregate(resource: audiobook.audiobookSections.watch(invokeNow: true) { [weak self] sections in
            guard let sections = sections else { return }
            self?.resources.aggregate(resource: sections.items.watch(invokeNow: true) { [weak self] items in
                self?.totalAudioSections = items?.count ?? 0
            })
        })

        try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback, mode: AVAudioSession.Mode.spokenAudio)
        try? AVAudioSession.sharedInstance().setActive(true)
        NotificationCenter.default.addObserver(self, selector: #selector(onAudioSessionEvent(notification:)), name: AVAudioSession.interruptionNotification, object: nil)

        configureRemoteCommands()

        var nowPlayingInfo: [String: Any] = [
            MPMediaItemPropertyMediaType: MPMediaType.audioBook.rawValue,
            MPMediaItemPropertyAlbumTitle: audiobook.metadata.value.title,
        ]

        let fileURL = audiobook.smallCoverImageFileResource.value?.state.value.fileURL
        let image = fileURL.flatMap({ try? Data(contentsOf: $0) }).flatMap({ UIImage(data: $0) })
        if let image = image {
            let albumArtwork = MPMediaItemArtwork(boundsSize: image.size) { _ in
                return image
            }
            nowPlayingInfo[MPMediaItemPropertyArtwork] = albumArtwork
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    deinit {
        let remoteCommandCenter = MPRemoteCommandCenter.shared()
        remoteCommandCenter.pauseCommand.removeTarget(_remoteCommandCenterPauseCommand)
        remoteCommandCenter.playCommand.removeTarget(_remoteCommandCenterPlayCommand)
        remoteCommandCenter.togglePlayPauseCommand.removeTarget(_remoteCommandCenterTogglePlayPauseCommand)
        remoteCommandCenter.skipBackwardCommand.removeTarget(_remoteCommandCenterSkipBackwardCommand)
        remoteCommandCenter.skipForwardCommand.removeTarget(_remoteCommandCenterSkipForwardCommand)
        remoteCommandCenter.previousTrackCommand.removeTarget(_remoteCommandCenterPreviousTrackCommand)
        remoteCommandCenter.nextTrackCommand.removeTarget(_remoteCommandCenterNextTrackCommand)
    }

    private(set) var busy: Bool {
        didSet {
            delegate?.busyStateDidChange()
        }
    }

    var currentTime: TimeInterval {
        return _narrationAudioPlayer?.currentTime ?? 0
    }

    var totalTime: TimeInterval {
        return _narrationAudioPlayer?.duration ?? 0
    }

    var isPlaying: Bool {
        return _narrationAudioPlayer?.isPlaying ?? false
    }

    func play(sectionIndex: Int, time: TimeInterval) {
        playResources = Resource()
        playResources.aggregate(resource: _audiobook.audiobookSections.watch(invokeNow: true) { [weak self] sections in
            guard let self = self, let sections = sections else { return }

            self.playResources.aggregate(resource: sections.items.watch(invokeNow: true) { [weak self] items in
                guard let self = self, let items = items, items.count > 0 else { return }
                var safeSectionIndex = sectionIndex
                var safeTime = time
                
                if safeSectionIndex < 0 || safeSectionIndex >= items.count {
                    // Play from the start if the section does not exist.
                    safeSectionIndex = 0
                    safeTime = 0
                }

                let section = items[safeSectionIndex]

                let playIfAvailable: (FileResource.State) -> Void = { [weak self] _ in
                    guard let self = self else { return }
                    if section.narrationFileResource.state.value.available, (section.soundtrackFileResource?.state.value.available ?? true) {
                        if self.isPlaying {
                            self.endPlaybackRegion(self.currentTime)
                        }
                        self.currentSectionIndex = safeSectionIndex
                        self.setupPlayerAndPlay(for: section, time: safeTime)
                    }
                }

                if let soundtrackResource = section.soundtrackFileResource {
                    self.playResources.aggregate(resource: soundtrackResource.state.watch(invokeNow: false, watchHandler: playIfAvailable))
                }

                self.playResources.aggregate(resource: section.narrationFileResource.state.watch(invokeNow: true, watchHandler: playIfAvailable))
            })
        })
    }

    func seek(_ time: TimeInterval) {
        guard let np = _narrationAudioPlayer else { return }

        var safeTime = time
        if safeTime > np.duration {
            safeTime = np.duration - 1
        }

        if safeTime < 0 {
            safeTime = 0
        }

        if isPlaying {
            endPlaybackRegion(np.currentTime)
        }

        np.currentTime = safeTime
        _soundtrackAudioPlayer?.currentTime = np.currentTime

        if isPlaying {
            startPlaybackRegion(currentSectionIndex, safeTime)
        }

        updateNowPlayingInfo()
    }

    func pause() {
        _narrationAudioPlayer?.pause()
        _soundtrackAudioPlayer?.pause()
        endPlaybackRegion(currentTime)
        delegate?.pauseStateDidChange()
    }

    func play() {
        startPlaybackRegion(currentSectionIndex, currentTime)
        _narrationAudioPlayer?.play()
        _soundtrackAudioPlayer?.play()
        delegate?.pauseStateDidChange()
    }

    func playAtTime() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                let narrationAudioPlayer = self._narrationAudioPlayer
            else { return }

            // 0.1 is a small skip into the future
            let startTime = narrationAudioPlayer.deviceCurrentTime + 0.1
            narrationAudioPlayer.play(atTime: startTime)
            self._soundtrackAudioPlayer?.play(atTime: startTime)
            self.delegate?.pauseStateDidChange()
            self.startPlaybackRegion(self.currentSectionIndex, self.currentTime)
        }
    }

    func stop() {
        endPlaybackRegion(currentTime)
        _narrationAudioPlayer?.stop()
        _soundtrackAudioPlayer?.stop()
    }

    func setNarrationVolume(_ volume: Float) {
        guard let np = _narrationAudioPlayer else { return }

        if np.prepareToPlay() {
            _soundtrackAudioPlayer?.prepareToPlay()
            np.volume = volume
        }
    }

    func setSoundtrackVolume(_ volume: Float) {
        guard let np = _narrationAudioPlayer, let sp = _soundtrackAudioPlayer else { return }

        if np.prepareToPlay(), sp.prepareToPlay() {
            sp.volume = volume
        }
    }

    func getPlaybackRegions(clear: Bool) -> [AudiobookPlaybackRegion]? {
        return _logPlaybackQueue.sync {
            let playbackRegions = self._playbackRegions

            if clear {
                self._playbackRegions = nil
            }

            return playbackRegions
        }
    }

    private func setupPlayerAndPlay(for section: AudiobookSection, time: TimeInterval) {
        if !section.narrationFileResource.state.value.available { return }
        if section.soundtrackFileResource != nil {
            if !section.soundtrackFileResource!.state.value.available { return }
        }

        let narrationURL = section.narrationFileResource.state.value.fileURL!
        let soundtrackURL = section.soundtrackFileResource?.state.value.fileURL
        setupPlayerAndPlay(with: narrationURL, and: soundtrackURL, time: time)
    }

    private func setupPlayerAndPlay(with narrationURL: URL, and soundtrackURL: URL?, time: TimeInterval) {
        let narrationVolume = _narrationAudioPlayer?.volume ?? _defaultNarrationVolume
        let soundtrackVolume = _soundtrackAudioPlayer?.volume ?? _defaultSoundtrackVolume

        busy = true
        _narrationAudioPlayer = nil
        _soundtrackAudioPlayer = nil
        let playersReadyDispatchGroup = DispatchGroup()
        var narrationAudioPlayer: AVAudioPlayer?
        var decryptedNarrationSelfDestructingFile: CryptController.SelfDestructingFile?
        var soundtrackAudioPlayer: AVAudioPlayer?
        var decryptedSoundtrackSelfDestructingFile: CryptController.SelfDestructingFile?
        let start = Date()
        DispatchQueue.global().async(group: playersReadyDispatchGroup) { [weak self] in
            guard let self = self else { return }
            do {
                decryptedNarrationSelfDestructingFile = try self._cryptController.decryptToSelfDestructingFile(srcURL: narrationURL)
                narrationAudioPlayer = try AVAudioPlayer(contentsOf: decryptedNarrationSelfDestructingFile!.fileURL)
                narrationAudioPlayer!.numberOfLoops = 0
                narrationAudioPlayer!.volume = narrationVolume
                narrationAudioPlayer!.delegate = self
            } catch {
                os_log("Error creating instance of AVAudioPlayer for narration with URL %@. %@", log: self._log, type: .default, String(describing: narrationURL), String(describing: error))
            }
        }
        if let soundtrackURL = soundtrackURL {
            DispatchQueue.global().async(group: playersReadyDispatchGroup) { [weak self] in
                guard let self = self else { return }
                do {
                    decryptedSoundtrackSelfDestructingFile = try self._cryptController.decryptToSelfDestructingFile(srcURL: soundtrackURL)
                    soundtrackAudioPlayer = try AVAudioPlayer(contentsOf: decryptedSoundtrackSelfDestructingFile!.fileURL)
                    soundtrackAudioPlayer!.numberOfLoops = 0
                    soundtrackAudioPlayer!.volume = soundtrackVolume
                } catch {
                    os_log("Error creating instance of AVAudioPlayer for soundtrack with URL %@. %@", log: self._log, type: .default, String(describing: soundtrackURL), String(describing: error))
                }
            }
        }
        playersReadyDispatchGroup.notify(queue: .global()) { [weak self] in
            guard let self = self else { return }
            self.busy = false
            guard narrationAudioPlayer != nil else { return }
            guard soundtrackURL == nil || soundtrackAudioPlayer != nil else { return }
            let duration = Date().timeIntervalSince(start)
            os_log("Decryption and player initialisation took %@s", log: self._log, type: .info, String(describing: duration))
            self._narrationAudioPlayer = narrationAudioPlayer
            self._decryptedNarrationSelfDestructingFile = decryptedNarrationSelfDestructingFile
            self._soundtrackAudioPlayer = soundtrackAudioPlayer
            self._decryptedSoundtrackSelfDestructingFile = decryptedSoundtrackSelfDestructingFile
            self.seek(time)
            self.delegate?.audioSectionChanged(sectionIndex: self.currentSectionIndex)
            self.updateNowPlayingInfo()
            self.playAtTime()
        }
    }

    @objc private func onAudioSessionEvent(notification: Notification) {
        guard let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                return
        }
        
        if type == .began {
            if isPlaying {
                pause()
            }
        } else if type == .ended {
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    play();
                }
            }
        }
    }

    private func updateNowPlayingInfo() {
        let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
        if var nowPlayingInfo = nowPlayingInfoCenter.nowPlayingInfo {
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = totalTime
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
            nowPlayingInfo[MPMediaItemPropertyTitle] = String(format: "File %d of %d", currentSectionIndex + 1, totalAudioSections)
            nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
        }
    }

    private func configureRemoteCommands() {
        let remoteCommandCenter = MPRemoteCommandCenter.shared()

        _remoteCommandCenterPauseCommand = remoteCommandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            self?.updateNowPlayingInfo()
            return .success
        }

        _remoteCommandCenterPlayCommand = remoteCommandCenter.playCommand.addTarget { [weak self] _ in
            self?.play()
            self?.updateNowPlayingInfo()
            return .success
        }

        _remoteCommandCenterTogglePlayPauseCommand = remoteCommandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            if let self = self {
                if self.isPlaying {
                    self.pause()
                } else {
                    self.play()
                }
                self.updateNowPlayingInfo()
            }
            return .success
        }

        _remoteCommandCenterSkipBackwardCommand = remoteCommandCenter.skipBackwardCommand.addTarget { [weak self] event in
            guard let event = event as? MPSkipIntervalCommandEvent, let self = self else { return .commandFailed }
            self.seek(self.currentTime - event.interval)
            return .success
        }
        remoteCommandCenter.skipBackwardCommand.preferredIntervals = [30]

        _remoteCommandCenterSkipForwardCommand = remoteCommandCenter.skipForwardCommand.addTarget { [weak self] event in
            guard let event = event as? MPSkipIntervalCommandEvent, let self = self else { return .commandFailed }
            self.seek(self.currentTime + event.interval)
            return .success
        }
        remoteCommandCenter.skipForwardCommand.preferredIntervals = [30]

        _remoteCommandCenterPreviousTrackCommand = remoteCommandCenter.previousTrackCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            self.play(sectionIndex: self.currentSectionIndex - 1, time: 0)
            return .success
        }

        _remoteCommandCenterNextTrackCommand = remoteCommandCenter.nextTrackCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            self.play(sectionIndex: self.currentSectionIndex + 1, time: 0)
            return .success
        }

        remoteCommandCenter.stopCommand.isEnabled = false
        remoteCommandCenter.enableLanguageOptionCommand.isEnabled = false
        remoteCommandCenter.disableLanguageOptionCommand.isEnabled = false
        remoteCommandCenter.changePlaybackRateCommand.isEnabled = false
        remoteCommandCenter.changeRepeatModeCommand.isEnabled = false
        remoteCommandCenter.changeShuffleModeCommand.isEnabled = false
        remoteCommandCenter.seekForwardCommand.isEnabled = false
        remoteCommandCenter.seekBackwardCommand.isEnabled = false
        remoteCommandCenter.changePlaybackPositionCommand.isEnabled = false
        remoteCommandCenter.ratingCommand.isEnabled = false
        remoteCommandCenter.likeCommand.isEnabled = false
        remoteCommandCenter.dislikeCommand.isEnabled = false
        remoteCommandCenter.bookmarkCommand.isEnabled = false
    }

    private func startPlaybackRegion(_ audioSectionIndex: Int, _ time: Double) {
        _logPlaybackQueue.async {
            self._playbackStartedAt = AudiobookPosition(audioSectionIndex: audioSectionIndex, time: time)
        }
    }

    private func endPlaybackRegion(_ endTime: Double) {
        let audioSectionIndex = self.currentSectionIndex
        
        _logPlaybackQueue.async {
            guard let start = self._playbackStartedAt, start.audioSectionIndex == audioSectionIndex else {
                self._playbackStartedAt = nil
                return
            }

            let minimumPlaybackDuration = 2.0 // 2 seconds
            let playbackDuration = endTime - start.time
            if playbackDuration < minimumPlaybackDuration {
                self._playbackStartedAt = nil
                return
            }
            
            let audioSectionsHash = self._audiobook.audiobookSections.value?.audioSectionsHash ?? ""
            let newRegion = AudiobookPlaybackRegion(audioSectionsHash: audioSectionsHash, audioSectionIndex: start.audioSectionIndex, startTime: start.time, endTime: endTime, endTimestamp: Date())
            if var playbackRegions = self._playbackRegions {
                playbackRegions.append(newRegion)
                self._playbackRegions = playbackRegions
            } else {
                self._playbackRegions = [newRegion]
            }

            self._playbackStartedAt = nil
        }
    }

    // MARK: AVAudioPlayerDelegate functions

    func audioPlayerDidFinishPlaying(_: AVAudioPlayer, successfully _: Bool) {
        endPlaybackRegion(totalTime)
        
        let nextSectionIndex = currentSectionIndex + 1
        if nextSectionIndex < totalAudioSections {
            play(sectionIndex: nextSectionIndex, time: 0)
        } else {
            stop()
        }
        
        delegate?.pauseStateDidChange()
    }
}
