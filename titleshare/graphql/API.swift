//  This file was automatically generated and should not be edited.

import Apollo

public enum SignUpWithCodeActionRequired: RawRepresentable, Equatable, Hashable, Apollo.JSONDecodable, Apollo.JSONEncodable {
  public typealias RawValue = String
  case login
  case setPassword
  /// Auto generated constant for unknown enum values
  case __unknown(RawValue)

  public init?(rawValue: RawValue) {
    switch rawValue {
      case "LOGIN": self = .login
      case "SET_PASSWORD": self = .setPassword
      default: self = .__unknown(rawValue)
    }
  }

  public var rawValue: RawValue {
    switch self {
      case .login: return "LOGIN"
      case .setPassword: return "SET_PASSWORD"
      case .__unknown(let value): return value
    }
  }

  public static func == (lhs: SignUpWithCodeActionRequired, rhs: SignUpWithCodeActionRequired) -> Bool {
    switch (lhs, rhs) {
      case (.login, .login): return true
      case (.setPassword, .setPassword): return true
      case (.__unknown(let lhsValue), .__unknown(let rhsValue)): return lhsValue == rhsValue
      default: return false
    }
  }
}

public struct ImageSizeInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(height: Int, width: Int) {
    graphQLMap = ["height": height, "width": width]
  }

  public var height: Int {
    get {
      return graphQLMap["height"] as! Int
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "height")
    }
  }

  public var width: Int {
    get {
      return graphQLMap["width"] as! Int
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "width")
    }
  }
}

public enum ContentType: RawRepresentable, Equatable, Hashable, Apollo.JSONDecodable, Apollo.JSONEncodable {
  public typealias RawValue = String
  case audiobook
  /// Auto generated constant for unknown enum values
  case __unknown(RawValue)

  public init?(rawValue: RawValue) {
    switch rawValue {
      case "AUDIOBOOK": self = .audiobook
      default: self = .__unknown(rawValue)
    }
  }

  public var rawValue: RawValue {
    switch self {
      case .audiobook: return "AUDIOBOOK"
      case .__unknown(let value): return value
    }
  }

  public static func == (lhs: ContentType, rhs: ContentType) -> Bool {
    switch (lhs, rhs) {
      case (.audiobook, .audiobook): return true
      case (.__unknown(let lhsValue), .__unknown(let rhsValue)): return lhsValue == rhsValue
      default: return false
    }
  }
}

public struct PlaybackRegion: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(audioSectionsHash: GraphQLID, audioSectionIndex: Int, startTime: Double, endTime: Double, endTimestamp: Date) {
    graphQLMap = ["audioSectionsHash": audioSectionsHash, "audioSectionIndex": audioSectionIndex, "startTime": startTime, "endTime": endTime, "endTimestamp": endTimestamp]
  }

  public var audioSectionsHash: GraphQLID {
    get {
      return graphQLMap["audioSectionsHash"] as! GraphQLID
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "audioSectionsHash")
    }
  }

  /// The zero based index of the audio section
  public var audioSectionIndex: Int {
    get {
      return graphQLMap["audioSectionIndex"] as! Int
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "audioSectionIndex")
    }
  }

  /// Start time in seconds within the audio section
  public var startTime: Double {
    get {
      return graphQLMap["startTime"] as! Double
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "startTime")
    }
  }

  /// End time in seconds within the audio section
  public var endTime: Double {
    get {
      return graphQLMap["endTime"] as! Double
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "endTime")
    }
  }

  public var endTimestamp: Date {
    get {
      return graphQLMap["endTimestamp"] as! Date
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "endTimestamp")
    }
  }
}

public enum RoleType: RawRepresentable, Equatable, Hashable, Apollo.JSONDecodable, Apollo.JSONEncodable {
  public typealias RawValue = String
  case sysAdmin
  case orgAdmin
  case consumer
  /// Auto generated constant for unknown enum values
  case __unknown(RawValue)

  public init?(rawValue: RawValue) {
    switch rawValue {
      case "SYS_ADMIN": self = .sysAdmin
      case "ORG_ADMIN": self = .orgAdmin
      case "CONSUMER": self = .consumer
      default: self = .__unknown(rawValue)
    }
  }

  public var rawValue: RawValue {
    switch self {
      case .sysAdmin: return "SYS_ADMIN"
      case .orgAdmin: return "ORG_ADMIN"
      case .consumer: return "CONSUMER"
      case .__unknown(let value): return value
    }
  }

  public static func == (lhs: RoleType, rhs: RoleType) -> Bool {
    switch (lhs, rhs) {
      case (.sysAdmin, .sysAdmin): return true
      case (.orgAdmin, .orgAdmin): return true
      case (.consumer, .consumer): return true
      case (.__unknown(let lhsValue), .__unknown(let rhsValue)): return lhsValue == rhsValue
      default: return false
    }
  }
}

public final class JoinCodeMutation: GraphQLMutation {
  public let operationDefinition =
    "mutation joinCode($code: String!) {\n  joinCode(input: {code: $code}) {\n    __typename\n    ... on ContentCollection {\n      name\n    }\n  }\n}"

  public var code: String

  public init(code: String) {
    self.code = code
  }

  public var variables: GraphQLMap? {
    return ["code": code]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("joinCode", arguments: ["input": ["code": GraphQLVariable("code")]], type: .nonNull(.object(JoinCode.selections))),
    ]

    public private(set) var resultMap: ResultMap

    public init(unsafeResultMap: ResultMap) {
      self.resultMap = unsafeResultMap
    }

    public init(joinCode: JoinCode) {
      self.init(unsafeResultMap: ["__typename": "Mutation", "joinCode": joinCode.resultMap])
    }

    public var joinCode: JoinCode {
      get {
        return JoinCode(unsafeResultMap: resultMap["joinCode"]! as! ResultMap)
      }
      set {
        resultMap.updateValue(newValue.resultMap, forKey: "joinCode")
      }
    }

    public struct JoinCode: GraphQLSelectionSet {
      public static let possibleTypes = ["User", "Organisation", "Content", "UserGroup", "ContentCollection"]

      public static let selections: [GraphQLSelection] = [
        GraphQLTypeCase(
          variants: ["ContentCollection": AsContentCollection.selections],
          default: [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          ]
        )
      ]

      public private(set) var resultMap: ResultMap

      public init(unsafeResultMap: ResultMap) {
        self.resultMap = unsafeResultMap
      }

      public static func makeUser() -> JoinCode {
        return JoinCode(unsafeResultMap: ["__typename": "User"])
      }

      public static func makeOrganisation() -> JoinCode {
        return JoinCode(unsafeResultMap: ["__typename": "Organisation"])
      }

      public static func makeContent() -> JoinCode {
        return JoinCode(unsafeResultMap: ["__typename": "Content"])
      }

      public static func makeUserGroup() -> JoinCode {
        return JoinCode(unsafeResultMap: ["__typename": "UserGroup"])
      }

      public static func makeContentCollection(name: String) -> JoinCode {
        return JoinCode(unsafeResultMap: ["__typename": "ContentCollection", "name": name])
      }

      public var __typename: String {
        get {
          return resultMap["__typename"]! as! String
        }
        set {
          resultMap.updateValue(newValue, forKey: "__typename")
        }
      }

      public var asContentCollection: AsContentCollection? {
        get {
          if !AsContentCollection.possibleTypes.contains(__typename) { return nil }
          return AsContentCollection(unsafeResultMap: resultMap)
        }
        set {
          guard let newValue = newValue else { return }
          resultMap = newValue.resultMap
        }
      }

      public struct AsContentCollection: GraphQLSelectionSet {
        public static let possibleTypes = ["ContentCollection"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("name", type: .nonNull(.scalar(String.self))),
        ]

        public private(set) var resultMap: ResultMap

        public init(unsafeResultMap: ResultMap) {
          self.resultMap = unsafeResultMap
        }

        public init(name: String) {
          self.init(unsafeResultMap: ["__typename": "ContentCollection", "name": name])
        }

        public var __typename: String {
          get {
            return resultMap["__typename"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "__typename")
          }
        }

        public var name: String {
          get {
            return resultMap["name"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "name")
          }
        }
      }
    }
  }
}

public final class LoginUserMutation: GraphQLMutation {
  public let operationDefinition =
    "mutation loginUser($email: ValidatedString!, $password: ValidatedString!) {\n  login(input: {email: $email, password: $password}) {\n    __typename\n    token\n  }\n}"

  public var email: ValidatedString
  public var password: ValidatedString

  public init(email: ValidatedString, password: ValidatedString) {
    self.email = email
    self.password = password
  }

  public var variables: GraphQLMap? {
    return ["email": email, "password": password]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("login", arguments: ["input": ["email": GraphQLVariable("email"), "password": GraphQLVariable("password")]], type: .nonNull(.object(Login.selections))),
    ]

    public private(set) var resultMap: ResultMap

    public init(unsafeResultMap: ResultMap) {
      self.resultMap = unsafeResultMap
    }

    public init(login: Login) {
      self.init(unsafeResultMap: ["__typename": "Mutation", "login": login.resultMap])
    }

    public var login: Login {
      get {
        return Login(unsafeResultMap: resultMap["login"]! as! ResultMap)
      }
      set {
        resultMap.updateValue(newValue.resultMap, forKey: "login")
      }
    }

    public struct Login: GraphQLSelectionSet {
      public static let possibleTypes = ["LoginResponse"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("token", type: .nonNull(.scalar(String.self))),
      ]

      public private(set) var resultMap: ResultMap

      public init(unsafeResultMap: ResultMap) {
        self.resultMap = unsafeResultMap
      }

      public init(token: String) {
        self.init(unsafeResultMap: ["__typename": "LoginResponse", "token": token])
      }

      public var __typename: String {
        get {
          return resultMap["__typename"]! as! String
        }
        set {
          resultMap.updateValue(newValue, forKey: "__typename")
        }
      }

      public var token: String {
        get {
          return resultMap["token"]! as! String
        }
        set {
          resultMap.updateValue(newValue, forKey: "token")
        }
      }
    }
  }
}

public final class LogoutMutation: GraphQLMutation {
  public let operationDefinition =
    "mutation logout {\n  logout\n}"

  public init() {
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("logout", type: .scalar(Bool.self)),
    ]

    public private(set) var resultMap: ResultMap

    public init(unsafeResultMap: ResultMap) {
      self.resultMap = unsafeResultMap
    }

    public init(logout: Bool? = nil) {
      self.init(unsafeResultMap: ["__typename": "Mutation", "logout": logout])
    }

    public var logout: Bool? {
      get {
        return resultMap["logout"] as? Bool
      }
      set {
        resultMap.updateValue(newValue, forKey: "logout")
      }
    }
  }
}

public final class MeQuery: GraphQLQuery {
  public let operationDefinition =
    "query me {\n  me {\n    __typename\n    ...UserDetails\n  }\n}"

  public var queryDocument: String { return operationDefinition.appending(UserDetails.fragmentDefinition) }

  public init() {
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Query"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("me", type: .nonNull(.object(Me.selections))),
    ]

    public private(set) var resultMap: ResultMap

    public init(unsafeResultMap: ResultMap) {
      self.resultMap = unsafeResultMap
    }

    public init(me: Me) {
      self.init(unsafeResultMap: ["__typename": "Query", "me": me.resultMap])
    }

    public var me: Me {
      get {
        return Me(unsafeResultMap: resultMap["me"]! as! ResultMap)
      }
      set {
        resultMap.updateValue(newValue.resultMap, forKey: "me")
      }
    }

    public struct Me: GraphQLSelectionSet {
      public static let possibleTypes = ["User"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLFragmentSpread(UserDetails.self),
      ]

      public private(set) var resultMap: ResultMap

      public init(unsafeResultMap: ResultMap) {
        self.resultMap = unsafeResultMap
      }

      public var __typename: String {
        get {
          return resultMap["__typename"]! as! String
        }
        set {
          resultMap.updateValue(newValue, forKey: "__typename")
        }
      }

      public var fragments: Fragments {
        get {
          return Fragments(unsafeResultMap: resultMap)
        }
        set {
          resultMap += newValue.resultMap
        }
      }

      public struct Fragments {
        public private(set) var resultMap: ResultMap

        public init(unsafeResultMap: ResultMap) {
          self.resultMap = unsafeResultMap
        }

        public var userDetails: UserDetails {
          get {
            return UserDetails(unsafeResultMap: resultMap)
          }
          set {
            resultMap += newValue.resultMap
          }
        }
      }
    }
  }
}

public final class UpdateMeMutation: GraphQLMutation {
  public let operationDefinition =
    "mutation updateMe($firstName: ValidatedString, $lastName: ValidatedString) {\n  updateMe(input: {firstName: $firstName, lastName: $lastName}) {\n    __typename\n    ...UserDetails\n  }\n}"

  public var queryDocument: String { return operationDefinition.appending(UserDetails.fragmentDefinition) }

  public var firstName: ValidatedString?
  public var lastName: ValidatedString?

  public init(firstName: ValidatedString? = nil, lastName: ValidatedString? = nil) {
    self.firstName = firstName
    self.lastName = lastName
  }

  public var variables: GraphQLMap? {
    return ["firstName": firstName, "lastName": lastName]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("updateMe", arguments: ["input": ["firstName": GraphQLVariable("firstName"), "lastName": GraphQLVariable("lastName")]], type: .nonNull(.object(UpdateMe.selections))),
    ]

    public private(set) var resultMap: ResultMap

    public init(unsafeResultMap: ResultMap) {
      self.resultMap = unsafeResultMap
    }

    public init(updateMe: UpdateMe) {
      self.init(unsafeResultMap: ["__typename": "Mutation", "updateMe": updateMe.resultMap])
    }

    public var updateMe: UpdateMe {
      get {
        return UpdateMe(unsafeResultMap: resultMap["updateMe"]! as! ResultMap)
      }
      set {
        resultMap.updateValue(newValue.resultMap, forKey: "updateMe")
      }
    }

    public struct UpdateMe: GraphQLSelectionSet {
      public static let possibleTypes = ["User"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLFragmentSpread(UserDetails.self),
      ]

      public private(set) var resultMap: ResultMap

      public init(unsafeResultMap: ResultMap) {
        self.resultMap = unsafeResultMap
      }

      public var __typename: String {
        get {
          return resultMap["__typename"]! as! String
        }
        set {
          resultMap.updateValue(newValue, forKey: "__typename")
        }
      }

      public var fragments: Fragments {
        get {
          return Fragments(unsafeResultMap: resultMap)
        }
        set {
          resultMap += newValue.resultMap
        }
      }

      public struct Fragments {
        public private(set) var resultMap: ResultMap

        public init(unsafeResultMap: ResultMap) {
          self.resultMap = unsafeResultMap
        }

        public var userDetails: UserDetails {
          get {
            return UserDetails(unsafeResultMap: resultMap)
          }
          set {
            resultMap += newValue.resultMap
          }
        }
      }
    }
  }
}

public final class RequestPasswordResetMutation: GraphQLMutation {
  public let operationDefinition =
    "mutation requestPasswordReset($email: ValidatedString!) {\n  requestPasswordReset(input: {email: $email}) {\n    __typename\n    success\n  }\n}"

  public var email: ValidatedString

  public init(email: ValidatedString) {
    self.email = email
  }

  public var variables: GraphQLMap? {
    return ["email": email]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("requestPasswordReset", arguments: ["input": ["email": GraphQLVariable("email")]], type: .nonNull(.object(RequestPasswordReset.selections))),
    ]

    public private(set) var resultMap: ResultMap

    public init(unsafeResultMap: ResultMap) {
      self.resultMap = unsafeResultMap
    }

    public init(requestPasswordReset: RequestPasswordReset) {
      self.init(unsafeResultMap: ["__typename": "Mutation", "requestPasswordReset": requestPasswordReset.resultMap])
    }

    public var requestPasswordReset: RequestPasswordReset {
      get {
        return RequestPasswordReset(unsafeResultMap: resultMap["requestPasswordReset"]! as! ResultMap)
      }
      set {
        resultMap.updateValue(newValue.resultMap, forKey: "requestPasswordReset")
      }
    }

    public struct RequestPasswordReset: GraphQLSelectionSet {
      public static let possibleTypes = ["RequestPasswordResetResponse"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("success", type: .nonNull(.scalar(Bool.self))),
      ]

      public private(set) var resultMap: ResultMap

      public init(unsafeResultMap: ResultMap) {
        self.resultMap = unsafeResultMap
      }

      public init(success: Bool) {
        self.init(unsafeResultMap: ["__typename": "RequestPasswordResetResponse", "success": success])
      }

      public var __typename: String {
        get {
          return resultMap["__typename"]! as! String
        }
        set {
          resultMap.updateValue(newValue, forKey: "__typename")
        }
      }

      public var success: Bool {
        get {
          return resultMap["success"]! as! Bool
        }
        set {
          resultMap.updateValue(newValue, forKey: "success")
        }
      }
    }
  }
}

public final class SignUpWithCodeMutation: GraphQLMutation {
  public let operationDefinition =
    "mutation signUpWithCode($email: ValidatedString!, $code: ValidatedString!) {\n  signUpWithCode(input: {email: $email, code: $code, useCookie: false}) {\n    __typename\n    ... on SignUpWithCodeLoggedInResponse {\n      token\n    }\n    ... on SignUpWithCodeActionRequiredResponse {\n      actionRequired\n    }\n  }\n}"

  public var email: ValidatedString
  public var code: ValidatedString

  public init(email: ValidatedString, code: ValidatedString) {
    self.email = email
    self.code = code
  }

  public var variables: GraphQLMap? {
    return ["email": email, "code": code]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("signUpWithCode", arguments: ["input": ["email": GraphQLVariable("email"), "code": GraphQLVariable("code"), "useCookie": false]], type: .nonNull(.object(SignUpWithCode.selections))),
    ]

    public private(set) var resultMap: ResultMap

    public init(unsafeResultMap: ResultMap) {
      self.resultMap = unsafeResultMap
    }

    public init(signUpWithCode: SignUpWithCode) {
      self.init(unsafeResultMap: ["__typename": "Mutation", "signUpWithCode": signUpWithCode.resultMap])
    }

    public var signUpWithCode: SignUpWithCode {
      get {
        return SignUpWithCode(unsafeResultMap: resultMap["signUpWithCode"]! as! ResultMap)
      }
      set {
        resultMap.updateValue(newValue.resultMap, forKey: "signUpWithCode")
      }
    }

    public struct SignUpWithCode: GraphQLSelectionSet {
      public static let possibleTypes = ["SignUpWithCodeLoggedInResponse", "SignUpWithCodeActionRequiredResponse"]

      public static let selections: [GraphQLSelection] = [
        GraphQLTypeCase(
          variants: ["SignUpWithCodeLoggedInResponse": AsSignUpWithCodeLoggedInResponse.selections, "SignUpWithCodeActionRequiredResponse": AsSignUpWithCodeActionRequiredResponse.selections],
          default: [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          ]
        )
      ]

      public private(set) var resultMap: ResultMap

      public init(unsafeResultMap: ResultMap) {
        self.resultMap = unsafeResultMap
      }

      public static func makeSignUpWithCodeLoggedInResponse(token: String) -> SignUpWithCode {
        return SignUpWithCode(unsafeResultMap: ["__typename": "SignUpWithCodeLoggedInResponse", "token": token])
      }

      public static func makeSignUpWithCodeActionRequiredResponse(actionRequired: SignUpWithCodeActionRequired) -> SignUpWithCode {
        return SignUpWithCode(unsafeResultMap: ["__typename": "SignUpWithCodeActionRequiredResponse", "actionRequired": actionRequired])
      }

      public var __typename: String {
        get {
          return resultMap["__typename"]! as! String
        }
        set {
          resultMap.updateValue(newValue, forKey: "__typename")
        }
      }

      public var asSignUpWithCodeLoggedInResponse: AsSignUpWithCodeLoggedInResponse? {
        get {
          if !AsSignUpWithCodeLoggedInResponse.possibleTypes.contains(__typename) { return nil }
          return AsSignUpWithCodeLoggedInResponse(unsafeResultMap: resultMap)
        }
        set {
          guard let newValue = newValue else { return }
          resultMap = newValue.resultMap
        }
      }

      public struct AsSignUpWithCodeLoggedInResponse: GraphQLSelectionSet {
        public static let possibleTypes = ["SignUpWithCodeLoggedInResponse"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("token", type: .nonNull(.scalar(String.self))),
        ]

        public private(set) var resultMap: ResultMap

        public init(unsafeResultMap: ResultMap) {
          self.resultMap = unsafeResultMap
        }

        public init(token: String) {
          self.init(unsafeResultMap: ["__typename": "SignUpWithCodeLoggedInResponse", "token": token])
        }

        public var __typename: String {
          get {
            return resultMap["__typename"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "__typename")
          }
        }

        public var token: String {
          get {
            return resultMap["token"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "token")
          }
        }
      }

      public var asSignUpWithCodeActionRequiredResponse: AsSignUpWithCodeActionRequiredResponse? {
        get {
          if !AsSignUpWithCodeActionRequiredResponse.possibleTypes.contains(__typename) { return nil }
          return AsSignUpWithCodeActionRequiredResponse(unsafeResultMap: resultMap)
        }
        set {
          guard let newValue = newValue else { return }
          resultMap = newValue.resultMap
        }
      }

      public struct AsSignUpWithCodeActionRequiredResponse: GraphQLSelectionSet {
        public static let possibleTypes = ["SignUpWithCodeActionRequiredResponse"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("actionRequired", type: .nonNull(.scalar(SignUpWithCodeActionRequired.self))),
        ]

        public private(set) var resultMap: ResultMap

        public init(unsafeResultMap: ResultMap) {
          self.resultMap = unsafeResultMap
        }

        public init(actionRequired: SignUpWithCodeActionRequired) {
          self.init(unsafeResultMap: ["__typename": "SignUpWithCodeActionRequiredResponse", "actionRequired": actionRequired])
        }

        public var __typename: String {
          get {
            return resultMap["__typename"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "__typename")
          }
        }

        public var actionRequired: SignUpWithCodeActionRequired {
          get {
            return resultMap["actionRequired"]! as! SignUpWithCodeActionRequired
          }
          set {
            resultMap.updateValue(newValue, forKey: "actionRequired")
          }
        }
      }
    }
  }
}

public final class ContentItemAudioSectionsQuery: GraphQLQuery {
  public let operationDefinition =
    "query contentItemAudioSections($contentItemId: ID!, $pageSize: Int!, $oneBasedPageNumber: Int!) {\n  node(id: $contentItemId) {\n    __typename\n    id\n    ... on Content {\n      totalBytes(format: MP3_HIGH_QUALITY) {\n        __typename\n        total\n      }\n      audioSectionsHash\n      audioSections(pageSize: $pageSize, pageNumber: $oneBasedPageNumber) {\n        __typename\n        items {\n          __typename\n          title\n          narrationUri(format: MP3_HIGH_QUALITY) {\n            __typename\n            uri\n          }\n          soundtrackUri(format: MP3_HIGH_QUALITY) {\n            __typename\n            uri\n          }\n        }\n        totalCount\n      }\n    }\n  }\n}"

  public var contentItemId: GraphQLID
  public var pageSize: Int
  public var oneBasedPageNumber: Int

  public init(contentItemId: GraphQLID, pageSize: Int, oneBasedPageNumber: Int) {
    self.contentItemId = contentItemId
    self.pageSize = pageSize
    self.oneBasedPageNumber = oneBasedPageNumber
  }

  public var variables: GraphQLMap? {
    return ["contentItemId": contentItemId, "pageSize": pageSize, "oneBasedPageNumber": oneBasedPageNumber]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Query"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("node", arguments: ["id": GraphQLVariable("contentItemId")], type: .object(Node.selections)),
    ]

    public private(set) var resultMap: ResultMap

    public init(unsafeResultMap: ResultMap) {
      self.resultMap = unsafeResultMap
    }

    public init(node: Node? = nil) {
      self.init(unsafeResultMap: ["__typename": "Query", "node": node.flatMap { (value: Node) -> ResultMap in value.resultMap }])
    }

    public var node: Node? {
      get {
        return (resultMap["node"] as? ResultMap).flatMap { Node(unsafeResultMap: $0) }
      }
      set {
        resultMap.updateValue(newValue?.resultMap, forKey: "node")
      }
    }

    public struct Node: GraphQLSelectionSet {
      public static let possibleTypes = ["User", "Organisation", "Content", "UserGroup", "ContentCollection"]

      public static let selections: [GraphQLSelection] = [
        GraphQLTypeCase(
          variants: ["Content": AsContent.selections],
          default: [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          ]
        )
      ]

      public private(set) var resultMap: ResultMap

      public init(unsafeResultMap: ResultMap) {
        self.resultMap = unsafeResultMap
      }

      public static func makeUser(id: GraphQLID) -> Node {
        return Node(unsafeResultMap: ["__typename": "User", "id": id])
      }

      public static func makeOrganisation(id: GraphQLID) -> Node {
        return Node(unsafeResultMap: ["__typename": "Organisation", "id": id])
      }

      public static func makeUserGroup(id: GraphQLID) -> Node {
        return Node(unsafeResultMap: ["__typename": "UserGroup", "id": id])
      }

      public static func makeContentCollection(id: GraphQLID) -> Node {
        return Node(unsafeResultMap: ["__typename": "ContentCollection", "id": id])
      }

      public static func makeContent(id: GraphQLID, totalBytes: AsContent.TotalByte, audioSectionsHash: GraphQLID, audioSections: AsContent.AudioSection) -> Node {
        return Node(unsafeResultMap: ["__typename": "Content", "id": id, "totalBytes": totalBytes.resultMap, "audioSectionsHash": audioSectionsHash, "audioSections": audioSections.resultMap])
      }

      public var __typename: String {
        get {
          return resultMap["__typename"]! as! String
        }
        set {
          resultMap.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return resultMap["id"]! as! GraphQLID
        }
        set {
          resultMap.updateValue(newValue, forKey: "id")
        }
      }

      public var asContent: AsContent? {
        get {
          if !AsContent.possibleTypes.contains(__typename) { return nil }
          return AsContent(unsafeResultMap: resultMap)
        }
        set {
          guard let newValue = newValue else { return }
          resultMap = newValue.resultMap
        }
      }

      public struct AsContent: GraphQLSelectionSet {
        public static let possibleTypes = ["Content"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("totalBytes", arguments: ["format": "MP3_HIGH_QUALITY"], type: .nonNull(.object(TotalByte.selections))),
          GraphQLField("audioSectionsHash", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("audioSections", arguments: ["pageSize": GraphQLVariable("pageSize"), "pageNumber": GraphQLVariable("oneBasedPageNumber")], type: .nonNull(.object(AudioSection.selections))),
        ]

        public private(set) var resultMap: ResultMap

        public init(unsafeResultMap: ResultMap) {
          self.resultMap = unsafeResultMap
        }

        public init(id: GraphQLID, totalBytes: TotalByte, audioSectionsHash: GraphQLID, audioSections: AudioSection) {
          self.init(unsafeResultMap: ["__typename": "Content", "id": id, "totalBytes": totalBytes.resultMap, "audioSectionsHash": audioSectionsHash, "audioSections": audioSections.resultMap])
        }

        public var __typename: String {
          get {
            return resultMap["__typename"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return resultMap["id"]! as! GraphQLID
          }
          set {
            resultMap.updateValue(newValue, forKey: "id")
          }
        }

        /// The sum of the number of bytes for all audio files
        public var totalBytes: TotalByte {
          get {
            return TotalByte(unsafeResultMap: resultMap["totalBytes"]! as! ResultMap)
          }
          set {
            resultMap.updateValue(newValue.resultMap, forKey: "totalBytes")
          }
        }

        public var audioSectionsHash: GraphQLID {
          get {
            return resultMap["audioSectionsHash"]! as! GraphQLID
          }
          set {
            resultMap.updateValue(newValue, forKey: "audioSectionsHash")
          }
        }

        public var audioSections: AudioSection {
          get {
            return AudioSection(unsafeResultMap: resultMap["audioSections"]! as! ResultMap)
          }
          set {
            resultMap.updateValue(newValue.resultMap, forKey: "audioSections")
          }
        }

        public struct TotalByte: GraphQLSelectionSet {
          public static let possibleTypes = ["ContentAudioBytesSummary"]

          public static let selections: [GraphQLSelection] = [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("total", type: .nonNull(.scalar(Long.self))),
          ]

          public private(set) var resultMap: ResultMap

          public init(unsafeResultMap: ResultMap) {
            self.resultMap = unsafeResultMap
          }

          public init(total: Long) {
            self.init(unsafeResultMap: ["__typename": "ContentAudioBytesSummary", "total": total])
          }

          public var __typename: String {
            get {
              return resultMap["__typename"]! as! String
            }
            set {
              resultMap.updateValue(newValue, forKey: "__typename")
            }
          }

          /// The total number of bytes of all narration and soundtrack files
          public var total: Long {
            get {
              return resultMap["total"]! as! Long
            }
            set {
              resultMap.updateValue(newValue, forKey: "total")
            }
          }
        }

        public struct AudioSection: GraphQLSelectionSet {
          public static let possibleTypes = ["ContentAudioSections"]

          public static let selections: [GraphQLSelection] = [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("items", type: .nonNull(.list(.nonNull(.object(Item.selections))))),
            GraphQLField("totalCount", type: .nonNull(.scalar(Int.self))),
          ]

          public private(set) var resultMap: ResultMap

          public init(unsafeResultMap: ResultMap) {
            self.resultMap = unsafeResultMap
          }

          public init(items: [Item], totalCount: Int) {
            self.init(unsafeResultMap: ["__typename": "ContentAudioSections", "items": items.map { (value: Item) -> ResultMap in value.resultMap }, "totalCount": totalCount])
          }

          public var __typename: String {
            get {
              return resultMap["__typename"]! as! String
            }
            set {
              resultMap.updateValue(newValue, forKey: "__typename")
            }
          }

          public var items: [Item] {
            get {
              return (resultMap["items"] as! [ResultMap]).map { (value: ResultMap) -> Item in Item(unsafeResultMap: value) }
            }
            set {
              resultMap.updateValue(newValue.map { (value: Item) -> ResultMap in value.resultMap }, forKey: "items")
            }
          }

          public var totalCount: Int {
            get {
              return resultMap["totalCount"]! as! Int
            }
            set {
              resultMap.updateValue(newValue, forKey: "totalCount")
            }
          }

          public struct Item: GraphQLSelectionSet {
            public static let possibleTypes = ["AudioSection"]

            public static let selections: [GraphQLSelection] = [
              GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
              GraphQLField("title", type: .nonNull(.scalar(String.self))),
              GraphQLField("narrationUri", arguments: ["format": "MP3_HIGH_QUALITY"], type: .nonNull(.object(NarrationUri.selections))),
              GraphQLField("soundtrackUri", arguments: ["format": "MP3_HIGH_QUALITY"], type: .object(SoundtrackUri.selections)),
            ]

            public private(set) var resultMap: ResultMap

            public init(unsafeResultMap: ResultMap) {
              self.resultMap = unsafeResultMap
            }

            public init(title: String, narrationUri: NarrationUri, soundtrackUri: SoundtrackUri? = nil) {
              self.init(unsafeResultMap: ["__typename": "AudioSection", "title": title, "narrationUri": narrationUri.resultMap, "soundtrackUri": soundtrackUri.flatMap { (value: SoundtrackUri) -> ResultMap in value.resultMap }])
            }

            public var __typename: String {
              get {
                return resultMap["__typename"]! as! String
              }
              set {
                resultMap.updateValue(newValue, forKey: "__typename")
              }
            }

            public var title: String {
              get {
                return resultMap["title"]! as! String
              }
              set {
                resultMap.updateValue(newValue, forKey: "title")
              }
            }

            public var narrationUri: NarrationUri {
              get {
                return NarrationUri(unsafeResultMap: resultMap["narrationUri"]! as! ResultMap)
              }
              set {
                resultMap.updateValue(newValue.resultMap, forKey: "narrationUri")
              }
            }

            public var soundtrackUri: SoundtrackUri? {
              get {
                return (resultMap["soundtrackUri"] as? ResultMap).flatMap { SoundtrackUri(unsafeResultMap: $0) }
              }
              set {
                resultMap.updateValue(newValue?.resultMap, forKey: "soundtrackUri")
              }
            }

            public struct NarrationUri: GraphQLSelectionSet {
              public static let possibleTypes = ["AudioUri"]

              public static let selections: [GraphQLSelection] = [
                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                GraphQLField("uri", type: .nonNull(.scalar(String.self))),
              ]

              public private(set) var resultMap: ResultMap

              public init(unsafeResultMap: ResultMap) {
                self.resultMap = unsafeResultMap
              }

              public init(uri: String) {
                self.init(unsafeResultMap: ["__typename": "AudioUri", "uri": uri])
              }

              public var __typename: String {
                get {
                  return resultMap["__typename"]! as! String
                }
                set {
                  resultMap.updateValue(newValue, forKey: "__typename")
                }
              }

              public var uri: String {
                get {
                  return resultMap["uri"]! as! String
                }
                set {
                  resultMap.updateValue(newValue, forKey: "uri")
                }
              }
            }

            public struct SoundtrackUri: GraphQLSelectionSet {
              public static let possibleTypes = ["AudioUri"]

              public static let selections: [GraphQLSelection] = [
                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                GraphQLField("uri", type: .nonNull(.scalar(String.self))),
              ]

              public private(set) var resultMap: ResultMap

              public init(unsafeResultMap: ResultMap) {
                self.resultMap = unsafeResultMap
              }

              public init(uri: String) {
                self.init(unsafeResultMap: ["__typename": "AudioUri", "uri": uri])
              }

              public var __typename: String {
                get {
                  return resultMap["__typename"]! as! String
                }
                set {
                  resultMap.updateValue(newValue, forKey: "__typename")
                }
              }

              public var uri: String {
                get {
                  return resultMap["uri"]! as! String
                }
                set {
                  resultMap.updateValue(newValue, forKey: "uri")
                }
              }
            }
          }
        }
      }
    }
  }
}

public final class ContentItemsQuery: GraphQLQuery {
  public let operationDefinition =
    "query contentItems($pageSize: Int!, $oneBasedPageNumber: Int!, $coverImageSizes: [ImageSizeInput!]!) {\n  searchContent(pageSize: $pageSize, pageNumber: $oneBasedPageNumber) {\n    __typename\n    items {\n      __typename\n      id\n      organisation {\n        __typename\n        name\n      }\n      type\n      title\n      subtitle\n      description\n      author\n      narrator\n      publisher\n      releaseDate\n      totalDuration\n      hasSoundtrack\n      coverImageUris(sizes: $coverImageSizes)\n      language {\n        __typename\n        name\n      }\n      genre {\n        __typename\n        name\n      }\n      secondGenre {\n        __typename\n        name\n      }\n      audioSectionsHash\n    }\n    totalCount\n  }\n}"

  public var pageSize: Int
  public var oneBasedPageNumber: Int
  public var coverImageSizes: [ImageSizeInput]

  public init(pageSize: Int, oneBasedPageNumber: Int, coverImageSizes: [ImageSizeInput]) {
    self.pageSize = pageSize
    self.oneBasedPageNumber = oneBasedPageNumber
    self.coverImageSizes = coverImageSizes
  }

  public var variables: GraphQLMap? {
    return ["pageSize": pageSize, "oneBasedPageNumber": oneBasedPageNumber, "coverImageSizes": coverImageSizes]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Query"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("searchContent", arguments: ["pageSize": GraphQLVariable("pageSize"), "pageNumber": GraphQLVariable("oneBasedPageNumber")], type: .nonNull(.object(SearchContent.selections))),
    ]

    public private(set) var resultMap: ResultMap

    public init(unsafeResultMap: ResultMap) {
      self.resultMap = unsafeResultMap
    }

    public init(searchContent: SearchContent) {
      self.init(unsafeResultMap: ["__typename": "Query", "searchContent": searchContent.resultMap])
    }

    /// For use by any user to fetch all content assigned to them.
    public var searchContent: SearchContent {
      get {
        return SearchContent(unsafeResultMap: resultMap["searchContent"]! as! ResultMap)
      }
      set {
        resultMap.updateValue(newValue.resultMap, forKey: "searchContent")
      }
    }

    public struct SearchContent: GraphQLSelectionSet {
      public static let possibleTypes = ["ContentSearchResponse"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("items", type: .nonNull(.list(.nonNull(.object(Item.selections))))),
        GraphQLField("totalCount", type: .nonNull(.scalar(Int.self))),
      ]

      public private(set) var resultMap: ResultMap

      public init(unsafeResultMap: ResultMap) {
        self.resultMap = unsafeResultMap
      }

      public init(items: [Item], totalCount: Int) {
        self.init(unsafeResultMap: ["__typename": "ContentSearchResponse", "items": items.map { (value: Item) -> ResultMap in value.resultMap }, "totalCount": totalCount])
      }

      public var __typename: String {
        get {
          return resultMap["__typename"]! as! String
        }
        set {
          resultMap.updateValue(newValue, forKey: "__typename")
        }
      }

      public var items: [Item] {
        get {
          return (resultMap["items"] as! [ResultMap]).map { (value: ResultMap) -> Item in Item(unsafeResultMap: value) }
        }
        set {
          resultMap.updateValue(newValue.map { (value: Item) -> ResultMap in value.resultMap }, forKey: "items")
        }
      }

      public var totalCount: Int {
        get {
          return resultMap["totalCount"]! as! Int
        }
        set {
          resultMap.updateValue(newValue, forKey: "totalCount")
        }
      }

      public struct Item: GraphQLSelectionSet {
        public static let possibleTypes = ["Content"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("organisation", type: .nonNull(.object(Organisation.selections))),
          GraphQLField("type", type: .nonNull(.scalar(ContentType.self))),
          GraphQLField("title", type: .nonNull(.scalar(String.self))),
          GraphQLField("subtitle", type: .nonNull(.scalar(String.self))),
          GraphQLField("description", type: .nonNull(.scalar(String.self))),
          GraphQLField("author", type: .nonNull(.scalar(String.self))),
          GraphQLField("narrator", type: .nonNull(.scalar(String.self))),
          GraphQLField("publisher", type: .nonNull(.scalar(String.self))),
          GraphQLField("releaseDate", type: .scalar(Date.self)),
          GraphQLField("totalDuration", type: .nonNull(.scalar(Int.self))),
          GraphQLField("hasSoundtrack", type: .nonNull(.scalar(Bool.self))),
          GraphQLField("coverImageUris", arguments: ["sizes": GraphQLVariable("coverImageSizes")], type: .nonNull(.list(.nonNull(.scalar(String.self))))),
          GraphQLField("language", type: .nonNull(.object(Language.selections))),
          GraphQLField("genre", type: .nonNull(.object(Genre.selections))),
          GraphQLField("secondGenre", type: .object(SecondGenre.selections)),
          GraphQLField("audioSectionsHash", type: .nonNull(.scalar(GraphQLID.self))),
        ]

        public private(set) var resultMap: ResultMap

        public init(unsafeResultMap: ResultMap) {
          self.resultMap = unsafeResultMap
        }

        public init(id: GraphQLID, organisation: Organisation, type: ContentType, title: String, subtitle: String, description: String, author: String, narrator: String, publisher: String, releaseDate: Date? = nil, totalDuration: Int, hasSoundtrack: Bool, coverImageUris: [String], language: Language, genre: Genre, secondGenre: SecondGenre? = nil, audioSectionsHash: GraphQLID) {
          self.init(unsafeResultMap: ["__typename": "Content", "id": id, "organisation": organisation.resultMap, "type": type, "title": title, "subtitle": subtitle, "description": description, "author": author, "narrator": narrator, "publisher": publisher, "releaseDate": releaseDate, "totalDuration": totalDuration, "hasSoundtrack": hasSoundtrack, "coverImageUris": coverImageUris, "language": language.resultMap, "genre": genre.resultMap, "secondGenre": secondGenre.flatMap { (value: SecondGenre) -> ResultMap in value.resultMap }, "audioSectionsHash": audioSectionsHash])
        }

        public var __typename: String {
          get {
            return resultMap["__typename"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return resultMap["id"]! as! GraphQLID
          }
          set {
            resultMap.updateValue(newValue, forKey: "id")
          }
        }

        public var organisation: Organisation {
          get {
            return Organisation(unsafeResultMap: resultMap["organisation"]! as! ResultMap)
          }
          set {
            resultMap.updateValue(newValue.resultMap, forKey: "organisation")
          }
        }

        public var type: ContentType {
          get {
            return resultMap["type"]! as! ContentType
          }
          set {
            resultMap.updateValue(newValue, forKey: "type")
          }
        }

        public var title: String {
          get {
            return resultMap["title"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "title")
          }
        }

        public var subtitle: String {
          get {
            return resultMap["subtitle"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "subtitle")
          }
        }

        public var description: String {
          get {
            return resultMap["description"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "description")
          }
        }

        public var author: String {
          get {
            return resultMap["author"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "author")
          }
        }

        public var narrator: String {
          get {
            return resultMap["narrator"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "narrator")
          }
        }

        public var publisher: String {
          get {
            return resultMap["publisher"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "publisher")
          }
        }

        public var releaseDate: Date? {
          get {
            return resultMap["releaseDate"] as? Date
          }
          set {
            resultMap.updateValue(newValue, forKey: "releaseDate")
          }
        }

        /// The duration of all audio files in seconds.
        public var totalDuration: Int {
          get {
            return resultMap["totalDuration"]! as! Int
          }
          set {
            resultMap.updateValue(newValue, forKey: "totalDuration")
          }
        }

        public var hasSoundtrack: Bool {
          get {
            return resultMap["hasSoundtrack"]! as! Bool
          }
          set {
            resultMap.updateValue(newValue, forKey: "hasSoundtrack")
          }
        }

        public var coverImageUris: [String] {
          get {
            return resultMap["coverImageUris"]! as! [String]
          }
          set {
            resultMap.updateValue(newValue, forKey: "coverImageUris")
          }
        }

        public var language: Language {
          get {
            return Language(unsafeResultMap: resultMap["language"]! as! ResultMap)
          }
          set {
            resultMap.updateValue(newValue.resultMap, forKey: "language")
          }
        }

        public var genre: Genre {
          get {
            return Genre(unsafeResultMap: resultMap["genre"]! as! ResultMap)
          }
          set {
            resultMap.updateValue(newValue.resultMap, forKey: "genre")
          }
        }

        public var secondGenre: SecondGenre? {
          get {
            return (resultMap["secondGenre"] as? ResultMap).flatMap { SecondGenre(unsafeResultMap: $0) }
          }
          set {
            resultMap.updateValue(newValue?.resultMap, forKey: "secondGenre")
          }
        }

        public var audioSectionsHash: GraphQLID {
          get {
            return resultMap["audioSectionsHash"]! as! GraphQLID
          }
          set {
            resultMap.updateValue(newValue, forKey: "audioSectionsHash")
          }
        }

        public struct Organisation: GraphQLSelectionSet {
          public static let possibleTypes = ["Organisation"]

          public static let selections: [GraphQLSelection] = [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("name", type: .nonNull(.scalar(String.self))),
          ]

          public private(set) var resultMap: ResultMap

          public init(unsafeResultMap: ResultMap) {
            self.resultMap = unsafeResultMap
          }

          public init(name: String) {
            self.init(unsafeResultMap: ["__typename": "Organisation", "name": name])
          }

          public var __typename: String {
            get {
              return resultMap["__typename"]! as! String
            }
            set {
              resultMap.updateValue(newValue, forKey: "__typename")
            }
          }

          public var name: String {
            get {
              return resultMap["name"]! as! String
            }
            set {
              resultMap.updateValue(newValue, forKey: "name")
            }
          }
        }

        public struct Language: GraphQLSelectionSet {
          public static let possibleTypes = ["Language"]

          public static let selections: [GraphQLSelection] = [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("name", type: .nonNull(.scalar(String.self))),
          ]

          public private(set) var resultMap: ResultMap

          public init(unsafeResultMap: ResultMap) {
            self.resultMap = unsafeResultMap
          }

          public init(name: String) {
            self.init(unsafeResultMap: ["__typename": "Language", "name": name])
          }

          public var __typename: String {
            get {
              return resultMap["__typename"]! as! String
            }
            set {
              resultMap.updateValue(newValue, forKey: "__typename")
            }
          }

          public var name: String {
            get {
              return resultMap["name"]! as! String
            }
            set {
              resultMap.updateValue(newValue, forKey: "name")
            }
          }
        }

        public struct Genre: GraphQLSelectionSet {
          public static let possibleTypes = ["Genre"]

          public static let selections: [GraphQLSelection] = [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("name", type: .nonNull(.scalar(String.self))),
          ]

          public private(set) var resultMap: ResultMap

          public init(unsafeResultMap: ResultMap) {
            self.resultMap = unsafeResultMap
          }

          public init(name: String) {
            self.init(unsafeResultMap: ["__typename": "Genre", "name": name])
          }

          public var __typename: String {
            get {
              return resultMap["__typename"]! as! String
            }
            set {
              resultMap.updateValue(newValue, forKey: "__typename")
            }
          }

          public var name: String {
            get {
              return resultMap["name"]! as! String
            }
            set {
              resultMap.updateValue(newValue, forKey: "name")
            }
          }
        }

        public struct SecondGenre: GraphQLSelectionSet {
          public static let possibleTypes = ["Genre"]

          public static let selections: [GraphQLSelection] = [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("name", type: .nonNull(.scalar(String.self))),
          ]

          public private(set) var resultMap: ResultMap

          public init(unsafeResultMap: ResultMap) {
            self.resultMap = unsafeResultMap
          }

          public init(name: String) {
            self.init(unsafeResultMap: ["__typename": "Genre", "name": name])
          }

          public var __typename: String {
            get {
              return resultMap["__typename"]! as! String
            }
            set {
              resultMap.updateValue(newValue, forKey: "__typename")
            }
          }

          public var name: String {
            get {
              return resultMap["name"]! as! String
            }
            set {
              resultMap.updateValue(newValue, forKey: "name")
            }
          }
        }
      }
    }
  }
}

public final class MyBookmarkQuery: GraphQLQuery {
  public let operationDefinition =
    "query myBookmark($contentId: ID!) {\n  node(id: $contentId) {\n    __typename\n    ... on Content {\n      myBookmark {\n        __typename\n        audioSectionIndex\n        time\n      }\n    }\n  }\n}"

  public var contentId: GraphQLID

  public init(contentId: GraphQLID) {
    self.contentId = contentId
  }

  public var variables: GraphQLMap? {
    return ["contentId": contentId]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Query"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("node", arguments: ["id": GraphQLVariable("contentId")], type: .object(Node.selections)),
    ]

    public private(set) var resultMap: ResultMap

    public init(unsafeResultMap: ResultMap) {
      self.resultMap = unsafeResultMap
    }

    public init(node: Node? = nil) {
      self.init(unsafeResultMap: ["__typename": "Query", "node": node.flatMap { (value: Node) -> ResultMap in value.resultMap }])
    }

    public var node: Node? {
      get {
        return (resultMap["node"] as? ResultMap).flatMap { Node(unsafeResultMap: $0) }
      }
      set {
        resultMap.updateValue(newValue?.resultMap, forKey: "node")
      }
    }

    public struct Node: GraphQLSelectionSet {
      public static let possibleTypes = ["User", "Organisation", "Content", "UserGroup", "ContentCollection"]

      public static let selections: [GraphQLSelection] = [
        GraphQLTypeCase(
          variants: ["Content": AsContent.selections],
          default: [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          ]
        )
      ]

      public private(set) var resultMap: ResultMap

      public init(unsafeResultMap: ResultMap) {
        self.resultMap = unsafeResultMap
      }

      public static func makeUser() -> Node {
        return Node(unsafeResultMap: ["__typename": "User"])
      }

      public static func makeOrganisation() -> Node {
        return Node(unsafeResultMap: ["__typename": "Organisation"])
      }

      public static func makeUserGroup() -> Node {
        return Node(unsafeResultMap: ["__typename": "UserGroup"])
      }

      public static func makeContentCollection() -> Node {
        return Node(unsafeResultMap: ["__typename": "ContentCollection"])
      }

      public static func makeContent(myBookmark: AsContent.MyBookmark? = nil) -> Node {
        return Node(unsafeResultMap: ["__typename": "Content", "myBookmark": myBookmark.flatMap { (value: AsContent.MyBookmark) -> ResultMap in value.resultMap }])
      }

      public var __typename: String {
        get {
          return resultMap["__typename"]! as! String
        }
        set {
          resultMap.updateValue(newValue, forKey: "__typename")
        }
      }

      public var asContent: AsContent? {
        get {
          if !AsContent.possibleTypes.contains(__typename) { return nil }
          return AsContent(unsafeResultMap: resultMap)
        }
        set {
          guard let newValue = newValue else { return }
          resultMap = newValue.resultMap
        }
      }

      public struct AsContent: GraphQLSelectionSet {
        public static let possibleTypes = ["Content"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("myBookmark", type: .object(MyBookmark.selections)),
        ]

        public private(set) var resultMap: ResultMap

        public init(unsafeResultMap: ResultMap) {
          self.resultMap = unsafeResultMap
        }

        public init(myBookmark: MyBookmark? = nil) {
          self.init(unsafeResultMap: ["__typename": "Content", "myBookmark": myBookmark.flatMap { (value: MyBookmark) -> ResultMap in value.resultMap }])
        }

        public var __typename: String {
          get {
            return resultMap["__typename"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "__typename")
          }
        }

        /// The bookmarked listening position of the logged in user
        public var myBookmark: MyBookmark? {
          get {
            return (resultMap["myBookmark"] as? ResultMap).flatMap { MyBookmark(unsafeResultMap: $0) }
          }
          set {
            resultMap.updateValue(newValue?.resultMap, forKey: "myBookmark")
          }
        }

        public struct MyBookmark: GraphQLSelectionSet {
          public static let possibleTypes = ["UserContentBookmark"]

          public static let selections: [GraphQLSelection] = [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("audioSectionIndex", type: .nonNull(.scalar(Int.self))),
            GraphQLField("time", type: .nonNull(.scalar(Double.self))),
          ]

          public private(set) var resultMap: ResultMap

          public init(unsafeResultMap: ResultMap) {
            self.resultMap = unsafeResultMap
          }

          public init(audioSectionIndex: Int, time: Double) {
            self.init(unsafeResultMap: ["__typename": "UserContentBookmark", "audioSectionIndex": audioSectionIndex, "time": time])
          }

          public var __typename: String {
            get {
              return resultMap["__typename"]! as! String
            }
            set {
              resultMap.updateValue(newValue, forKey: "__typename")
            }
          }

          /// The zero based index of the audio section
          public var audioSectionIndex: Int {
            get {
              return resultMap["audioSectionIndex"]! as! Int
            }
            set {
              resultMap.updateValue(newValue, forKey: "audioSectionIndex")
            }
          }

          /// Time in seconds within the audio section
          public var time: Double {
            get {
              return resultMap["time"]! as! Double
            }
            set {
              resultMap.updateValue(newValue, forKey: "time")
            }
          }
        }
      }
    }
  }
}

public final class LogPlaybackMutation: GraphQLMutation {
  public let operationDefinition =
    "mutation logPlayback($contentId: ID!, $playbackRegions: [PlaybackRegion!]!) {\n  logPlayback(input: {contentId: $contentId, playbackRegions: $playbackRegions}) {\n    __typename\n    content {\n      __typename\n      id\n    }\n  }\n}"

  public var contentId: GraphQLID
  public var playbackRegions: [PlaybackRegion]

  public init(contentId: GraphQLID, playbackRegions: [PlaybackRegion]) {
    self.contentId = contentId
    self.playbackRegions = playbackRegions
  }

  public var variables: GraphQLMap? {
    return ["contentId": contentId, "playbackRegions": playbackRegions]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("logPlayback", arguments: ["input": ["contentId": GraphQLVariable("contentId"), "playbackRegions": GraphQLVariable("playbackRegions")]], type: .nonNull(.object(LogPlayback.selections))),
    ]

    public private(set) var resultMap: ResultMap

    public init(unsafeResultMap: ResultMap) {
      self.resultMap = unsafeResultMap
    }

    public init(logPlayback: LogPlayback) {
      self.init(unsafeResultMap: ["__typename": "Mutation", "logPlayback": logPlayback.resultMap])
    }

    /// Logs the regions of the book the user has played. The most recent playback region is used as the user's bookmark.
    public var logPlayback: LogPlayback {
      get {
        return LogPlayback(unsafeResultMap: resultMap["logPlayback"]! as! ResultMap)
      }
      set {
        resultMap.updateValue(newValue.resultMap, forKey: "logPlayback")
      }
    }

    public struct LogPlayback: GraphQLSelectionSet {
      public static let possibleTypes = ["LogPlaybackResponse"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("content", type: .nonNull(.object(Content.selections))),
      ]

      public private(set) var resultMap: ResultMap

      public init(unsafeResultMap: ResultMap) {
        self.resultMap = unsafeResultMap
      }

      public init(content: Content) {
        self.init(unsafeResultMap: ["__typename": "LogPlaybackResponse", "content": content.resultMap])
      }

      public var __typename: String {
        get {
          return resultMap["__typename"]! as! String
        }
        set {
          resultMap.updateValue(newValue, forKey: "__typename")
        }
      }

      public var content: Content {
        get {
          return Content(unsafeResultMap: resultMap["content"]! as! ResultMap)
        }
        set {
          resultMap.updateValue(newValue.resultMap, forKey: "content")
        }
      }

      public struct Content: GraphQLSelectionSet {
        public static let possibleTypes = ["Content"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        ]

        public private(set) var resultMap: ResultMap

        public init(unsafeResultMap: ResultMap) {
          self.resultMap = unsafeResultMap
        }

        public init(id: GraphQLID) {
          self.init(unsafeResultMap: ["__typename": "Content", "id": id])
        }

        public var __typename: String {
          get {
            return resultMap["__typename"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return resultMap["id"]! as! GraphQLID
          }
          set {
            resultMap.updateValue(newValue, forKey: "id")
          }
        }
      }
    }
  }
}

public struct UserDetails: GraphQLFragment {
  public static let fragmentDefinition =
    "fragment UserDetails on User {\n  __typename\n  id\n  firstName\n  lastName\n  email\n  roles {\n    __typename\n    type\n    organisation {\n      __typename\n      id\n    }\n  }\n}"

  public static let possibleTypes = ["User"]

  public static let selections: [GraphQLSelection] = [
    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
    GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
    GraphQLField("firstName", type: .nonNull(.scalar(String.self))),
    GraphQLField("lastName", type: .nonNull(.scalar(String.self))),
    GraphQLField("email", type: .nonNull(.scalar(String.self))),
    GraphQLField("roles", type: .nonNull(.list(.nonNull(.object(Role.selections))))),
  ]

  public private(set) var resultMap: ResultMap

  public init(unsafeResultMap: ResultMap) {
    self.resultMap = unsafeResultMap
  }

  public init(id: GraphQLID, firstName: String, lastName: String, email: String, roles: [Role]) {
    self.init(unsafeResultMap: ["__typename": "User", "id": id, "firstName": firstName, "lastName": lastName, "email": email, "roles": roles.map { (value: Role) -> ResultMap in value.resultMap }])
  }

  public var __typename: String {
    get {
      return resultMap["__typename"]! as! String
    }
    set {
      resultMap.updateValue(newValue, forKey: "__typename")
    }
  }

  public var id: GraphQLID {
    get {
      return resultMap["id"]! as! GraphQLID
    }
    set {
      resultMap.updateValue(newValue, forKey: "id")
    }
  }

  public var firstName: String {
    get {
      return resultMap["firstName"]! as! String
    }
    set {
      resultMap.updateValue(newValue, forKey: "firstName")
    }
  }

  public var lastName: String {
    get {
      return resultMap["lastName"]! as! String
    }
    set {
      resultMap.updateValue(newValue, forKey: "lastName")
    }
  }

  public var email: String {
    get {
      return resultMap["email"]! as! String
    }
    set {
      resultMap.updateValue(newValue, forKey: "email")
    }
  }

  public var roles: [Role] {
    get {
      return (resultMap["roles"] as! [ResultMap]).map { (value: ResultMap) -> Role in Role(unsafeResultMap: value) }
    }
    set {
      resultMap.updateValue(newValue.map { (value: Role) -> ResultMap in value.resultMap }, forKey: "roles")
    }
  }

  public struct Role: GraphQLSelectionSet {
    public static let possibleTypes = ["UserRole"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
      GraphQLField("type", type: .nonNull(.scalar(RoleType.self))),
      GraphQLField("organisation", type: .object(Organisation.selections)),
    ]

    public private(set) var resultMap: ResultMap

    public init(unsafeResultMap: ResultMap) {
      self.resultMap = unsafeResultMap
    }

    public init(type: RoleType, organisation: Organisation? = nil) {
      self.init(unsafeResultMap: ["__typename": "UserRole", "type": type, "organisation": organisation.flatMap { (value: Organisation) -> ResultMap in value.resultMap }])
    }

    public var __typename: String {
      get {
        return resultMap["__typename"]! as! String
      }
      set {
        resultMap.updateValue(newValue, forKey: "__typename")
      }
    }

    public var type: RoleType {
      get {
        return resultMap["type"]! as! RoleType
      }
      set {
        resultMap.updateValue(newValue, forKey: "type")
      }
    }

    public var organisation: Organisation? {
      get {
        return (resultMap["organisation"] as? ResultMap).flatMap { Organisation(unsafeResultMap: $0) }
      }
      set {
        resultMap.updateValue(newValue?.resultMap, forKey: "organisation")
      }
    }

    public struct Organisation: GraphQLSelectionSet {
      public static let possibleTypes = ["Organisation"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
      ]

      public private(set) var resultMap: ResultMap

      public init(unsafeResultMap: ResultMap) {
        self.resultMap = unsafeResultMap
      }

      public init(id: GraphQLID) {
        self.init(unsafeResultMap: ["__typename": "Organisation", "id": id])
      }

      public var __typename: String {
        get {
          return resultMap["__typename"]! as! String
        }
        set {
          resultMap.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return resultMap["id"]! as! GraphQLID
        }
        set {
          resultMap.updateValue(newValue, forKey: "id")
        }
      }
    }
  }
}