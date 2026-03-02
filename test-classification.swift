import Foundation

// Quick verification test for classification system
// Run: swift test-classification.swift

// Simulate the classification
enum EcosystemType: String {
    case npm = "NPM"
    case pypi = "PyPI"
    case gomod = "Go"
    case cargo = "Cargo"
}

enum TechType: String {
    case npm, pypi, cargo, gomod, maven, gradle, gem, composer, github, language, platform
}

enum TechCategory: String {
    case frontend = "Frontend"
    case backend = "Backend"
    case database = "Database"
    case devops = "DevOps"
    case other = "Other"
}

let knownPackages: [TechType: [String: TechCategory]] = [
    .npm: [
        "react": .frontend,
        "next": .frontend,
        "express": .backend,
        "mongoose": .database,
        "jest": .devops,
    ],
    .pypi: [
        "django": .backend,
        "flask": .backend,
        "fastapi": .backend,
        "sqlalchemy": .database,
    ],
    .gomod: [
        "gin": .backend,
        "gorm": .database,
    ],
    .cargo: [
        "actix-web": .backend,
        "diesel": .database,
    ]
]

let frontendPatterns = ["react", "vue", "angular", "svelte", "frontend", "ui", "css"]
let backendPatterns = ["express", "django", "flask", "fastapi", "gin", "api", "server"]
let databasePatterns = ["mongo", "postgres", "redis", "sql", "db", "database"]

func matchesAny(_ string: String, patterns: [String]) -> Bool {
    patterns.contains { string.contains($0) }
}

func inferCategory(from name: String) -> TechCategory {
    let lower = name.lowercased()
    if matchesAny(lower, patterns: databasePatterns) { return .database }
    if matchesAny(lower, patterns: frontendPatterns) { return .frontend }
    if matchesAny(lower, patterns: backendPatterns) { return .backend }
    return .other
}

func classify(name: String, ecosystem: TechType) -> TechCategory {
    if let known = knownPackages[ecosystem], let category = known[name] {
        return category
    }
    return inferCategory(from: name)
}

// Test cases
print("=== StackPulse Classification Test ===\n")

let tests: [(String, TechType, TechCategory)] = [
    ("react", .npm, .frontend),
    ("express", .npm, .backend),
    ("mongoose", .npm, .database),
    ("jest", .npm, .devops),
    ("next", .npm, .frontend),
    ("django", .pypi, .backend),
    ("flask", .pypi, .backend),
    ("fastapi", .pypi, .backend),
    ("sqlalchemy", .pypi, .database),
    ("gin", .gomod, .backend),
    ("gorm", .gomod, .database),
    ("actix-web", .cargo, .backend),
    ("diesel", .cargo, .database),
    // Pattern matching tests (unknown packages)
    ("react-router", .npm, .frontend),  // contains "react"
    ("express-rate-limit", .npm, .backend),  // contains "express"
    ("mongodb", .npm, .database),  // contains "mongo"
    ("my-cool-ui-lib", .npm, .frontend),  // contains "ui"
]

var passed = 0
var failed = 0

for (name, ecosystem, expected) in tests {
    let result = classify(name: name, ecosystem: ecosystem)
    let status = result == expected ? "✅ PASS" : "❌ FAIL"
    if result == expected {
        passed += 1
        print("\(status): \(name) (\(ecosystem)) -> \(result.rawValue)")
    } else {
        failed += 1
        print("\(status): \(name) (\(ecosystem)) -> \(result.rawValue) [expected: \(expected.rawValue)]")
    }
}

print("\n=== Results ===")
print("Passed: \(passed)/\(tests.count)")
print("Failed: \(failed)/\(tests.count)")
print("\nClassification system: \(failed == 0 ? "✅ WORKING" : "⚠️ NEEDS FIXES")")
