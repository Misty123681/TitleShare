// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import os
import UIKit

class AudiobooksCollectionHeaderCell: UICollectionViewCell {
    @IBOutlet var lastRefreshedLabel: UILabel!

    private var _resources: Resource?
    private weak var _timer: Timer?
    private let _calendar = Calendar(identifier: .gregorian)

    public override init(frame: CGRect) {
        super.init(frame: frame)
        createTimer()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        createTimer()
    }

    private func createTimer() {
        let timer = Timer(timeInterval: 60.0, repeats: true, block: { [weak self] _ in self?.updateUI() })
        timer.tolerance = 15.0
        RunLoop.current.add(timer, forMode: .default)
        _timer = timer
    }

    deinit {
        _timer?.invalidate()
    }

    var dateFetched: Date? {
        didSet {
            updateUI()
        }
    }

    private func updateUI() {
        let state = determineState()
        lastRefreshedLabel.text = state.text
        switch state.urgency {
        case .none:
            lastRefreshedLabel.textColor = UIColor.darkGray
        case .warning:
            lastRefreshedLabel.textColor = UIColor.orange
        case .serious:
            lastRefreshedLabel.textColor = UIColor.red
        }
    }

    fileprivate struct State {
        let text: String
        let urgency: Urgency
    }

    fileprivate enum Urgency {
        case none
        case warning
        case serious
    }

    private func determineState() -> State {
        if let dateFetched = dateFetched {
            let dateComponents = _calendar.dateComponents([.day, .hour, .minute], from: dateFetched, to: Date())
            let days = dateComponents.day!
            let hours = dateComponents.hour!
            let minutes = dateComponents.minute!
            let textualDuration: String
            let urgency: Urgency
            if days > 0 {
                textualDuration = "\(days) day\(days == 1 ? "" : "s") ago"
                urgency = .serious
            } else if hours > 0 {
                textualDuration = "\(hours) hour\(hours == 1 ? "" : "s") ago"
                urgency = .warning
            } else if minutes > 3 {
                textualDuration = "\(minutes) minute\(minutes == 1 ? "" : "s") ago"
                urgency = .none
            } else {
                textualDuration = "Just Now"
                urgency = .none
            }
            return State(text: "Updated \(textualDuration)", urgency: urgency)
        }
        return State(text: "", urgency: .none)
    }
}
