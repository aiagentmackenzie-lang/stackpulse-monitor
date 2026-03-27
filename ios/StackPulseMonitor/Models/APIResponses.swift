import Foundation

nonisolated struct NPMPackageResponse: Codable, Sendable {
    let name: String?
    let version: String?
    let description: String?

    nonisolated enum CodingKeys: String, CodingKey {
        case name
        case version
        case description
    }
}

nonisolated struct NPMSearchResponse: Codable, Sendable {
    let objects: [NPMSearchObject]
}

nonisolated struct NPMSearchObject: Codable, Sendable {
    let package: NPMSearchPackage
}

nonisolated struct NPMSearchPackage: Codable, Sendable {
    let name: String
    let version: String
    let description: String?
}

nonisolated struct GitHubRelease: Codable, Sendable {
    let tagName: String
    let name: String?
    let publishedAt: String?
    let body: String?

    nonisolated enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name
        case publishedAt = "published_at"
        case body
    }
}

nonisolated struct OSVQueryRequest: Codable, Sendable {
    let package: OSVPackage

    nonisolated struct OSVPackage: Codable, Sendable {
        let name: String
        let ecosystem: String
    }
}

nonisolated struct OSVResponse: Codable, Sendable {
    let vulns: [OSVVuln]?
}

nonisolated struct OSVVuln: Codable, Sendable {
    let id: String
    let summary: String?
    let severity: [OSVSeverity]?
    let published: String?
    let affected: [OSVAffected]?
}

nonisolated struct OSVSeverity: Codable, Sendable {
    let type: String?
    let score: String?
}

nonisolated struct OSVAffected: Codable, Sendable {
    let ranges: [OSVRange]?
}

nonisolated struct OSVRange: Codable, Sendable {
    let events: [OSVEvent]?
}

nonisolated struct OSVEvent: Codable, Sendable {
    let introduced: String?
    let fixed: String?
}

nonisolated struct EOLResponse: Codable, Sendable {
    let cycle: String?
    let releaseDate: String?
    let eol: EOLValue?
    let latest: String?
    let lts: EOLValue?

    nonisolated enum CodingKeys: String, CodingKey {
        case cycle
        case releaseDate
        case eol
        case latest
        case lts
    }
}

nonisolated enum EOLValue: Codable, Sendable {
    case bool(Bool)
    case string(String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let boolVal = try? container.decode(Bool.self) {
            self = .bool(boolVal)
        } else if let stringVal = try? container.decode(String.self) {
            self = .string(stringVal)
        } else {
            self = .bool(false)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .bool(let val): try container.encode(val)
        case .string(let val): try container.encode(val)
        }
    }
}

nonisolated struct OpenAIChatRequest: Codable, Sendable {
    let model: String
    let messages: [OpenAIMessage]
    let temperature: Double
}

nonisolated struct OpenAIMessage: Codable, Sendable {
    let role: String
    let content: String
}

nonisolated struct OpenAIChatResponse: Codable, Sendable {
    let choices: [OpenAIChoice]?
}

nonisolated struct OpenAIChoice: Codable, Sendable {
    let message: OpenAIMessage?
}

nonisolated struct AISummaryResult: Codable, Sendable {
    let what_changed: String?
    let is_urgent: String?
    let what_to_do: String?
    let breaking_changes: Bool?
    let score_impact: Int?
}
