// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import Apollo
import Foundation

public typealias ValidatedString = String

public typealias Long = Int64

extension Int64: JSONDecodable {
    public init(jsonValue value: JSONValue) throws {
        guard let number = value as? NSNumber else {
            throw JSONDecodingError.couldNotConvert(value: value, to: Int64.self)
        }
        self = number.int64Value
    }
}

extension Date: JSONDecodable, JSONEncodable {
    public init(jsonValue value: JSONValue) throws {
        guard let number = value as? NSNumber else {
            throw JSONDecodingError.couldNotConvert(value: value, to: Int64.self)
        }
        self = Date(timeIntervalSince1970: Double(number.int64Value) / 1000)
    }

    public var jsonValue: JSONValue {
        return String(Int64(timeIntervalSince1970 * 1000))
    }
}
