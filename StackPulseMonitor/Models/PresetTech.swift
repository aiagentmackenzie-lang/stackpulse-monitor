import Foundation

nonisolated struct PresetTech: Sendable {
    let name: String
    let type: TechType
    let identifier: String
    let category: TechCategory
    let eolSlug: String?

    static let all: [PresetTech] = [
        PresetTech(name: "React", type: .npm, identifier: "react", category: .frontend, eolSlug: nil),
        PresetTech(name: "React Native", type: .npm, identifier: "react-native", category: .frontend, eolSlug: nil),
        PresetTech(name: "Next.js", type: .npm, identifier: "next", category: .frontend, eolSlug: nil),
        PresetTech(name: "Vue", type: .npm, identifier: "vue", category: .frontend, eolSlug: nil),
        PresetTech(name: "Expo", type: .npm, identifier: "expo", category: .frontend, eolSlug: nil),
        PresetTech(name: "TypeScript", type: .npm, identifier: "typescript", category: .frontend, eolSlug: nil),

        PresetTech(name: "Node.js", type: .platform, identifier: "node", category: .backend, eolSlug: "nodejs"),
        PresetTech(name: "NestJS", type: .npm, identifier: "@nestjs/core", category: .backend, eolSlug: nil),
        PresetTech(name: "Express", type: .npm, identifier: "express", category: .backend, eolSlug: nil),
        PresetTech(name: "Django", type: .platform, identifier: "django", category: .backend, eolSlug: "django"),
        PresetTech(name: "FastAPI", type: .platform, identifier: "fastapi", category: .backend, eolSlug: nil),
        PresetTech(name: "Laravel", type: .platform, identifier: "laravel", category: .backend, eolSlug: "laravel"),

        PresetTech(name: "PostgreSQL", type: .platform, identifier: "postgresql", category: .database, eolSlug: "postgresql"),
        PresetTech(name: "MongoDB", type: .platform, identifier: "mongodb", category: .database, eolSlug: "mongodb"),
        PresetTech(name: "Redis", type: .platform, identifier: "redis", category: .database, eolSlug: "redis"),
        PresetTech(name: "MySQL", type: .platform, identifier: "mysql", category: .database, eolSlug: "mysql"),
        PresetTech(name: "Prisma", type: .npm, identifier: "prisma", category: .database, eolSlug: nil),
        PresetTech(name: "Supabase", type: .npm, identifier: "@supabase/supabase-js", category: .database, eolSlug: nil),

        PresetTech(name: "Docker", type: .platform, identifier: "docker", category: .devops, eolSlug: nil),
        PresetTech(name: "Kubernetes", type: .platform, identifier: "kubernetes", category: .devops, eolSlug: "kubernetes"),
        PresetTech(name: "GitHub Actions", type: .platform, identifier: "github-actions", category: .devops, eolSlug: nil),
        PresetTech(name: "Vercel", type: .platform, identifier: "vercel", category: .devops, eolSlug: nil),
        PresetTech(name: "AWS", type: .platform, identifier: "aws", category: .devops, eolSlug: nil),
        PresetTech(name: "Nginx", type: .platform, identifier: "nginx", category: .devops, eolSlug: "nginx"),

        PresetTech(name: "Python", type: .language, identifier: "python", category: .language, eolSlug: "python"),
        PresetTech(name: "Go", type: .language, identifier: "go", category: .language, eolSlug: "go"),
        PresetTech(name: "Rust", type: .language, identifier: "rust", category: .language, eolSlug: nil),
        PresetTech(name: "Java", type: .language, identifier: "java", category: .language, eolSlug: "java"),
        PresetTech(name: "PHP", type: .language, identifier: "php", category: .language, eolSlug: "php"),
        PresetTech(name: "Ruby", type: .language, identifier: "ruby", category: .language, eolSlug: "ruby"),
    ]

    static func forCategory(_ category: TechCategory) -> [PresetTech] {
        all.filter { $0.category == category }
    }
}
