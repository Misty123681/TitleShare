// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import Foundation

struct AudiobookPlaybackRegion: Codable {
    let audioSectionsHash: String
    let audioSectionIndex: Int
    let startTime: Double
    let endTime: Double
    let endTimestamp: Date
}
