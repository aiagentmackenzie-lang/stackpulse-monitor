import Foundation

nonisolated struct PresetTech: Sendable {
    let name: String
    let type: TechType
    let identifier: String
    let category: TechCategory
    let eolSlug: String?
    let defaultVersion: String

    static let all: [PresetTech] = [
        PresetTech(name: "React", type: .npm, identifier: "react", category: .frontend, eolSlug: nil, defaultVersion: "18.3.0"),
        PresetTech(name: "React Native", type: .npm, identifier: "react-native", category: .frontend, eolSlug: nil, defaultVersion: "0.74.0"),
        PresetTech(name: "Next.js", type: .npm, identifier: "next", category: .frontend, eolSlug: nil, defaultVersion: "14.2.0"),
        PresetTech(name: "Vue", type: .npm, identifier: "vue", category: .frontend, eolSlug: nil, defaultVersion: "3.4.0"),
        PresetTech(name: "Expo", type: .npm, identifier: "expo", category: .frontend, eolSlug: nil, defaultVersion: "51.0.0"),
        PresetTech(name: "TypeScript", type: .npm, identifier: "typescript", category: .frontend, eolSlug: nil, defaultVersion: "5.4.0"),

        PresetTech(name: "Node.js", type: .platform, identifier: "node", category: .backend, eolSlug: "nodejs", defaultVersion: "20.12.0"),
        PresetTech(name: "NestJS", type: .npm, identifier: "@nestjs/core", category: .backend, eolSlug: nil, defaultVersion: "10.3.0"),
        PresetTech(name: "Express", type: .npm, identifier: "express", category: .backend, eolSlug: nil, defaultVersion: "4.18.0"),
        PresetTech(name: "Django", type: .platform, identifier: "django", category: .backend, eolSlug: "django", defaultVersion: "5.0.0"),
        PresetTech(name: "FastAPI", type: .platform, identifier: "fastapi", category: .backend, eolSlug: nil, defaultVersion: "0.110.0"),
        PresetTech(name: "Laravel", type: .platform, identifier: "laravel", category: .backend, eolSlug: "laravel", defaultVersion: "11.0.0"),

        PresetTech(name: "PostgreSQL", type: .platform, identifier: "postgresql", category: .database, eolSlug: "postgresql", defaultVersion: "16.3.0"),
        PresetTech(name: "MongoDB", type: .platform, identifier: "mongodb", category: .database, eolSlug: "mongodb", defaultVersion: "7.0.0"),
        PresetTech(name: "Redis", type: .platform, identifier: "redis", category: .database, eolSlug: "redis", defaultVersion: "7.2.0"),
        PresetTech(name: "MySQL", type: .platform, identifier: "mysql", category: .database, eolSlug: "mysql", defaultVersion: "8.4.0"),
        PresetTech(name: "Prisma", type: .npm, identifier: "prisma", category: .database, eolSlug: nil, defaultVersion: "5.13.0"),
        PresetTech(name: "Supabase", type: .npm, identifier: "@supabase/supabase-js", category: .database, eolSlug: nil, defaultVersion: "2.43.0"),

        PresetTech(name: "Docker", type: .platform, identifier: "docker", category: .devops, eolSlug: nil, defaultVersion: "26.1.0"),
        PresetTech(name: "Kubernetes", type: .platform, identifier: "kubernetes", category: .devops, eolSlug: "kubernetes", defaultVersion: "1.30.0"),
        PresetTech(name: "GitHub Actions", type: .platform, identifier: "github-actions", category: .devops, eolSlug: nil, defaultVersion: ""),
        PresetTech(name: "Vercel", type: .platform, identifier: "vercel", category: .devops, eolSlug: nil, defaultVersion: ""),
        PresetTech(name: "AWS", type: .platform, identifier: "aws", category: .devops, eolSlug: nil, defaultVersion: ""),
        PresetTech(name: "Nginx", type: .platform, identifier: "nginx", category: .devops, eolSlug: "nginx", defaultVersion: "1.26.0"),

        PresetTech(name: "Python", type: .language, identifier: "python", category: .language, eolSlug: "python", defaultVersion: "3.12.0"),
        PresetTech(name: "Go", type: .language, identifier: "go", category: .language, eolSlug: "go", defaultVersion: "1.22.0"),
        PresetTech(name: "Rust", type: .language, identifier: "rust", category: .language, eolSlug: nil, defaultVersion: "1.78.0"),
        PresetTech(name: "Java", type: .language, identifier: "java", category: .language, eolSlug: "java", defaultVersion: "21.0"),
        PresetTech(name: "PHP", type: .language, identifier: "php", category: .language, eolSlug: "php", defaultVersion: "8.3.0"),
        PresetTech(name: "Ruby", type: .language, identifier: "ruby", category: .language, eolSlug: "ruby", defaultVersion: "3.3.0"),
    ]

    static func forCategory(_ category: TechCategory) -> [PresetTech] {
        all.filter { $0.category == category }
    }
}
