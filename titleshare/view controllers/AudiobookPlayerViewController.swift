// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import UIKit

class AudiobookPlayerViewController: UIViewController, AudiobookPlayerDelegate {
    var cryptController: CryptController!
    var audiobook: Audiobook!
    var model: Model!

    @IBOutlet var soundtrackSwitch: UISwitch!
    @IBOutlet var narrationVolumeImage: UIImageView!
    @IBOutlet var soundtrackVolumeImage: UIImageView!
    @IBOutlet var soundtrackVolumeSlider: UISlider!
    @IBOutlet var soundtrackControlsView: UIView!
    @IBOutlet var chapterProgressSlider: UISlider!
    @IBOutlet var bottomControlsView: UIView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var subtitleLabel: UILabel!
    @IBOutlet var coverImageView: UIImageView!
    @IBOutlet var timeProgressLabel: UILabel!
    @IBOutlet var totalTimeLabel: UILabel!
    @IBOutlet var playPauseButton: UIButton!
    @IBOutlet var busyView: UIView!
    @IBOutlet var showTocButton: UIBarButtonItem!

    private let resources: Resource = Resource()
    private var player: AudiobookPlayer?
    private var uiUpdateTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()

        chapterProgressSlider.setThumbImage(UIImage(named: "ic_slider_knob"), for: UIControl.State.normal)

        audiobook.fetchLargeCoverImage()
        resources.aggregate(resource: audiobook.largeCoverImageFileResource.watch(invokeNow: true) { [weak self] fileResource in
            guard let self = self, let fileResource = fileResource else { return }
            self.resources.aggregate(resource: fileResource.state.watch(invokeNow: true) { [weak self] state in
                guard let self = self else { return }
                self.coverImageView.image = state.fileURL.flatMap { try? Data(contentsOf: $0) }.flatMap { UIImage(data: $0) }
            })
        })

        // Setup tap gesture for narration-soundtrack slider
        let soundtrackSliderTap = UITapGestureRecognizer(target: self, action: #selector(soundtrackSliderTapped(gesture:)))
        soundtrackVolumeSlider.addGestureRecognizer(soundtrackSliderTap)

        resources.aggregate(resource: audiobook.metadata.watch(invokeNow: true) { [weak self] metadata in
            guard let self = self else { return }

            if !metadata.hasSoundtrack {
                self.soundtrackControlsView.isHidden = true
                self.soundtrackControlsView.heightAnchor.constraint(equalToConstant: 0).isActive = true
                self.view.layoutIfNeeded()
            }

            self.titleLabel.text = metadata.title
        })

        player = AudiobookPlayer(for: audiobook, cryptController: cryptController)
        player!.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(willResignActive), name: UIApplication.willResignActiveNotification, object: nil)

        // Always use the local bookmark if there is one, otherwise fetch it from the server
        if let bookmark = audiobook.bookmark.value {
            player!.play(sectionIndex: bookmark.audioSectionIndex, time: bookmark.time)
        } else {
            audiobook.fetchBookmark { [weak self] bookmark in
                if let bookmark = bookmark {
                    self?.player?.play(sectionIndex: bookmark.audioSectionIndex, time: bookmark.time)
                } else {
                    self?.player?.play(sectionIndex: 0, time: 0)
                }
            }
        }
    }

    @objc func willResignActive(_: Notification) {
        logPlayback()
    }

    override func viewWillDisappear(_ animated: Bool) {
        if navigationController?.viewControllers.firstIndex(of: self) ?? NSNotFound == NSNotFound {
            player?.stop()
            logPlayback()
            uiUpdateTimer?.invalidate()
            player = nil
        }

        super.viewWillDisappear(animated)
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        switch segue.identifier {
        case "showToc":
            guard let tocViewController = segue.destination as? AudiobookPlayerTocTableViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }

            tocViewController.audiobook = audiobook
            tocViewController.selectedAudioSectionIndex = player?.currentSectionIndex
            tocViewController.audioSectionWasSelected = { [weak self] selectedIndex in
                self?.player?.play(sectionIndex: selectedIndex, time: 0)
            }
        default:
            break
        }
    }

    // MARK: Actions

    @IBAction func playOrPauseTouchUp(_: UIButton) {
        guard let player = self.player else { return }
        if player.isPlaying {
            player.pause()
        } else {
            player.play()
        }
    }

    @IBAction func forward30secTouchUp(_: UIButton) {
        guard let player = self.player else { return }
        player.seek(player.currentTime + 30)
    }

    @IBAction func rewind30secTouchUp(_: UIButton) {
        guard let player = self.player else { return }
        player.seek(player.currentTime - 30)
    }

    @IBAction func soundtrackSwitchToggled(_: UISwitch) {
        if soundtrackSwitch.isOn {
            player?.setSoundtrackVolume(getSoundtrackVolume())
            soundtrackVolumeSlider?.isEnabled = true
        } else {
            player?.setSoundtrackVolume(0)
            soundtrackVolumeSlider?.isEnabled = false
        }
    }

    @IBAction func soundtrackMixChanged(_: UISlider) {
        player?.setSoundtrackVolume(getSoundtrackVolume())
        player?.setNarrationVolume(getNarrationVolume())
    }

    @objc
    func soundtrackSliderTapped(gesture: UIGestureRecognizer) {
        setSliderValue(gesture)
        player?.setSoundtrackVolume(getSoundtrackVolume())
        player?.setNarrationVolume(getNarrationVolume())
    }

    @IBAction func chapterProgressChanged(_ sender: UISlider) {
        player?.seek(TimeInterval(sender.value))
    }

    // MARK: AudiobookPlayerDelegate

    func busyStateDidChange() {
        DispatchQueue.main.async { [weak self] in
            self?.synchroniseWithPlayerBusyState()
        }
    }

    func pauseStateDidChange() {
        synchroniseWithPlayerPlayingState()
       
        if let player = self.player, !player.isPlaying {
            logPlayback()
            DispatchQueue.main.async { [weak self] in
                self?.model?.save()
            }
        }
    }

    func audioSectionChanged(sectionIndex _: Int) {
        DispatchQueue.main.async { [weak self] in
            self?.synchroniseWithPlayerSection()
        }
        logPlayback()
    }

    // MARK: Private functions

    private func synchroniseWithPlayerBusyState() {
        guard let player = self.player else { return }
        showTocButton.isEnabled = !player.busy
        busyView.isHidden = !player.busy
    }

    private func synchroniseWithPlayerSection() {
        guard let player = self.player else { return }

        totalTimeLabel.text = stringFormat(from: player.totalTime)
        chapterProgressSlider.minimumValue = 0
        chapterProgressSlider.maximumValue = Float(player.totalTime)
        subtitleLabel.text = String(format: "File %d of %d", player.currentSectionIndex + 1, player.totalAudioSections)
        synchroniseWithPlayerPlayingState()
        synchroniseWithPlayerTime()

        if uiUpdateTimer == nil {
            uiUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                self?.synchroniseWithPlayerTime()
            }
        }
    }

    private func synchroniseWithPlayerTime() {
        guard let player = self.player else { return }

        timeProgressLabel.text = stringFormat(from: player.currentTime)

        if !chapterProgressSlider.isHighlighted {
            chapterProgressSlider.setValue(Float(player.currentTime), animated: true)
        }
    }

    private func synchroniseWithPlayerPlayingState() {
        if let player = self.player, player.isPlaying {
            playPauseButton.setImage(UIImage(named: "ic_pause_big"), for: UIControl.State.normal)
        } else {
            playPauseButton.setImage(UIImage(named: "ic_play_big"), for: UIControl.State.normal)
        }
    }

    private func setSliderValue(_ gesture: UIGestureRecognizer) {
        guard let slider = gesture.view as? UISlider else { return }

        let pt = gesture.location(in: slider)
        let percentage = pt.x / slider.bounds.size.width
        let delta = Float(percentage) * (slider.maximumValue - slider.minimumValue)
        let value = slider.minimumValue + delta
        slider.setValue(value, animated: true)
    }

    private func getSoundtrackVolume() -> Float {
        let v = soundtrackVolumeSlider.value

        if v >= 0.5 {
            return 1.0
        }

        return v * 2
    }

    private func getNarrationVolume() -> Float {
        let v = soundtrackVolumeSlider.value

        if v <= 0.5 {
            return 1.0
        }

        return (1 - v) * 2
    }

    private func logPlayback() {
        if let playbackRegions = player?.getPlaybackRegions(clear: true) {
            audiobook.logPlayback(for: playbackRegions)
        }
    }
}

private func stringFormat(from timeInterval: TimeInterval) -> String {
    let interval = Int(timeInterval)
    let seconds = interval % 60
    let minutes = (interval / 60) % 60
    let hours = (interval / 3600)
    return String(format: "%0.2ld:%0.2ld:%0.2ld", hours, minutes, seconds)
}
