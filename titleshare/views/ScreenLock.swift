// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import UIKit

class ScreenLock: UIView {
    var _activityIndicator: UIActivityIndicatorView?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    func lock() {
        assert(_activityIndicator != nil)
        _activityIndicator!.startAnimating()
        isHidden = false
    }

    func unlock() {
        assert(_activityIndicator != nil)
        _activityIndicator!.stopAnimating()
        isHidden = true
    }

    func coverParent() {
        if superview != nil {
            // Cover super view
            topAnchor.constraint(equalTo: superview!.topAnchor).isActive = true
            bottomAnchor.constraint(equalTo: superview!.bottomAnchor).isActive = true
            leadingAnchor.constraint(equalTo: superview!.leadingAnchor).isActive = true
            trailingAnchor.constraint(equalTo: superview!.trailingAnchor).isActive = true
        }
    }

    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func draw(_ rect: CGRect) {
     // Drawing code
     }
     */

    private func setupUI() {
        if _activityIndicator == nil {
            _activityIndicator = UIActivityIndicatorView(style: .gray)
        }

        translatesAutoresizingMaskIntoConstraints = false

        let ai = _activityIndicator!
        addSubview(ai)
        ai.translatesAutoresizingMaskIntoConstraints = false
        ai.heightAnchor.constraint(equalToConstant: 25).isActive = true
        ai.widthAnchor.constraint(equalToConstant: 25).isActive = true
        ai.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        ai.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -10).isActive = true

        backgroundColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 0.5)

        layer.zPosition = 10000
        isHidden = true
    }
}
