// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import Foundation

struct AudiobookMetadata: Codable {
    public let organisationName: String
    public let title: String
    public let subtitle: String
    public let desc: String
    public let author: String
    public let narrator: String
    public let publisher: String
    public let releaseDate: Date?
    public let totalDuration: TimeInterval
    public let hasSoundtrack: Bool
    let coverImageUrl256x256: URL?
    let coverImageUrl1024x1024: URL?
    public let language: String
    public let genre: String
    public let secondGenre: String?
    let audioSectionsHash: String

    init(graphql: ContentItemsQuery.Data.SearchContent.Item) {
        organisationName = graphql.organisation.name
        title = graphql.title
        subtitle = graphql.subtitle
        desc = graphql.description
        author = graphql.author
        narrator = graphql.narrator
        publisher = graphql.publisher
        releaseDate = graphql.releaseDate
        totalDuration = Double(graphql.totalDuration)
        hasSoundtrack = graphql.hasSoundtrack
        coverImageUrl256x256 = graphql.coverImageUris.first.flatMap({ URL(string: $0) })
        coverImageUrl1024x1024 = graphql.coverImageUris.last.flatMap({ URL(string: $0) })
        language = graphql.language.name
        genre = graphql.genre.name
        secondGenre = graphql.secondGenre?.name
        audioSectionsHash = graphql.audioSectionsHash
    }
}
