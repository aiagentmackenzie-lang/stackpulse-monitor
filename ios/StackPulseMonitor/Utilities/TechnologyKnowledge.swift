import Foundation

/// Knowledge base for technology classification
/// Maps package names to their proper categories and provides pattern matching
nonisolated struct TechnologyKnowledge {
    
    // MARK: - Known Package Database
    
    /// Top packages with their categories
    /// Format: [ecosystem: [packageName: category]]
    static let knownPackages: [TechType: [String: TechCategory]] = [
        .npm: [
            // Frontend Frameworks & Libraries
            "react": .frontend,
            "react-dom": .frontend,
            "vue": .frontend,
            "vue-router": .frontend,
            "vuex": .frontend,
            "@vue/core": .frontend,
            "angular": .frontend,
            "@angular/core": .frontend,
            "svelte": .frontend,
            "next": .frontend,
            "nuxt": .frontend,
            "gatsby": .frontend,
            "remix": .frontend,
            "solid-js": .frontend,
            "preact": .frontend,
            "alpinejs": .frontend,
            "lit": .frontend,
            "stencil": .frontend,
            
            // UI Component Libraries
            "@mui/material": .frontend,
            "@material-ui/core": .frontend,
            "antd": .frontend,
            "chakra-ui": .frontend,
            "@chakra-ui/react": .frontend,
            "bootstrap": .frontend,
            "tailwindcss": .frontend,
            "@tailwindcss/postcss": .frontend,
            "bulma": .frontend,
            "semantic-ui-react": .frontend,
            "primereact": .frontend,
            "vuetify": .frontend,
            "quasar": .frontend,
            "element-plus": .frontend,
            "shadcn-ui": .frontend,
            "radix-ui": .frontend,
            "headlessui": .frontend,
            "framer-motion": .frontend,
            
            // State Management
            "redux": .frontend,
            "mobx": .frontend,
            "zustand": .frontend,
            "recoil": .frontend,
            "jotai": .frontend,
            "valtio": .frontend,
            "effector": .frontend,
            
            // Backend Frameworks
            "express": .backend,
            "fastify": .backend,
            "koa": .backend,
            "hapi": .backend,
            "nestjs": .backend,
            "@nestjs/core": .backend,
            "sails": .backend,
            "feathers": .backend,
            "loopback": .backend,
            "adonisjs": .backend,
            "egg": .backend,
            "midway": .backend,
            
            // Database & ORM
            "mongoose": .database,
            "sequelize": .database,
            "prisma": .database,
            "@prisma/client": .database,
            "typeorm": .database,
            "knex": .database,
            "waterline": .database,
            "bookshelf": .database,
            "objection": .database,
            " mikro-orm": .database,
            
            // Database Drivers
            "mongodb": .database,
            "pg": .database,
            "mysql2": .database,
            "sqlite3": .database,
            "redis": .database,
            "ioredis": .database,
            "cassandra-driver": .database,
            "neo4j-driver": .database,
            
            // Testing
            "jest": .devops,
            "vitest": .devops,
            "mocha": .devops,
            "chai": .devops,
            "cypress": .devops,
            "playwright": .devops,
            "@playwright/test": .devops,
            "puppeteer": .devops,
            "selenium-webdriver": .devops,
            "ava": .devops,
            "tap": .devops,
            "jasmine": .devops,
            "karma": .devops,
            
            // Build Tools
            "webpack": .devops,
            "vite": .devops,
            "esbuild": .devops,
            "rollup": .devops,
            "parcel": .devops,
            "turbopack": .devops,
            "swc": .devops,
            "babel": .devops,
            "@babel/core": .devops,
            "typescript": .devops,
            "ts-node": .devops,
            
            // DevOps & Deployment
            "dockerode": .devops,
            "pm2": .devops,
            "nodemon": .devops,
            "concurrently": .devops,
            "husky": .devops,
            "lint-staged": .devops,
            "@changesets/cli": .devops,
            "semantic-release": .devops,
            
            // API & Communication
            "axios": .backend,
            "node-fetch": .backend,
            "cross-fetch": .backend,
            "graphql": .backend,
            "apollo-server": .backend,
            "@apollo/server": .backend,
            "urql": .frontend,
            "@apollo/client": .frontend,
            "socket.io": .backend,
            "ws": .backend,
            "jsonwebtoken": .backend,
            "passport": .backend,
            "cors": .backend,
            "helmet": .backend,
            "bcrypt": .backend,
            "argon2": .backend,
            "validator": .backend,
            
            // Utilities
            "lodash": .backend,
            "underscore": .backend,
            "ramda": .backend,
            "moment": .backend,
            "date-fns": .backend,
            "dayjs": .backend,
            "uuid": .backend,
            "nanoid": .backend,
            "zod": .backend,
            "yup": .backend,
            "joi": .backend,
            "class-validator": .backend,
            "class-transformer": .backend,
            "dotenv": .backend,
            "commander": .backend,
            "inquirer": .backend,
            "chalk": .backend,
            "ora": .backend,
            "winston": .backend,
            "pino": .backend,
            "debug": .backend,
            
            // AI/ML
            "tensorflow": .other,
            "@tensorflow/tfjs": .other,
            "onnxruntime": .other,
            "openai": .other,
            "@anthropic-ai/sdk": .other,
            "langchain": .other,
            "@langchain/core": .other,
            "replicate": .other,
            "huggingface": .other,
            "transformers": .other,
            "sharp": .other,
        ],
        
        .pypi: [
            // Web Frameworks
            "django": .backend,
            "flask": .backend,
            "fastapi": .backend,
            "tornado": .backend,
            "bottle": .backend,
            "pyramid": .backend,
            "sanic": .backend,
            "quart": .backend,
            "starlette": .backend,
            "falcon": .backend,
            "hug": .backend,
            "aiohttp": .backend,
            "tornadoweb": .backend,
            
            // Database & ORM
            "sqlalchemy": .database,
            "django-orm": .database,
            "peewee": .database,
            "tortoise-orm": .database,
            "ormar": .database,
            "pony": .database,
            "pymongo": .database,
            "motor": .database,
            "mongoengine": .database,
            "psycopg2": .database,
            "psycopg": .database,
            "asyncpg": .database,
            "pymysql": .database,
            "aiomysql": .database,
            "sqlite3": .database,
            "aiosqlite": .database,
            "redis": .database,
            "aioredis": .database,
            "celery": .backend,
            "celery[redis]": .backend,
            
            // Data Science & ML
            "numpy": .other,
            "pandas": .other,
            "scipy": .other,
            "scikit-learn": .other,
            "sklearn": .other,
            "tensorflow": .other,
            "torch": .other,
            "pytorch": .other,
            "keras": .other,
            "transformers": .other,
            "huggingface-hub": .other,
            "datasets": .other,
            "tokenizers": .other,
            "accelerate": .other,
            "diffusers": .other,
            "peft": .other,
            "trl": .other,
            "openai": .other,
            "anthropic": .other,
            "langchain": .other,
            "langchain-core": .other,
            "llama-index": .other,
            "pinecone-client": .other,
            "chromadb": .other,
            "weaviate-client": .other,
            "qdrant-client": .other,
            
            // Scientific
            "matplotlib": .other,
            "seaborn": .other,
            "plotly": .other,
            "bokeh": .other,
            "altair": .other,
            "jupyter": .other,
            "ipython": .other,
            "sympy": .other,
            
            // Utilities
            "requests": .backend,
            "httpx": .backend,
            "urllib3": .backend,
            "pydantic": .backend,
            "pydantic-core": .backend,
            "python-dotenv": .backend,
            "click": .backend,
            "typer": .backend,
            "rich": .backend,
            "typer-cli": .backend,
            "pytest": .devops,
            "unittest": .devops,
            "mock": .devops,
            "factory-boy": .devops,
            "faker": .devops,
            "fakeredis": .devops,
            "pytest-asyncio": .devops,
            "pytest-cov": .devops,
            "coverage": .devops,
            "mypy": .devops,
            "flake8": .devops,
            "black": .devops,
            "isort": .devops,
            "pylint": .devops,
            "bandit": .devops,
            "safety": .devops,
            "pre-commit": .devops,
            
            // Other
            "pillow": .other,
            "opencv-python": .other,
            "cryptography": .backend,
            "bcrypt": .backend,
            "pyjwt": .backend,
            "itsdangerous": .backend,
            "passlib": .backend,
        ],
        
        .cargo: [
            // Web Frameworks
            "actix-web": .backend,
            "axum": .backend,
            "rocket": .backend,
            "tide": .backend,
            "warp": .backend,
            "salvo": .backend,
            "poem": .backend,
            "ntex": .backend,
            "viz": .backend,
            "thruster": .backend,
            "gotham": .backend,
            
            // Database & ORM
            "diesel": .database,
            "sea-orm": .database,
            "sqlx": .database,
            "tokio-postgres": .database,
            "rust-postgres": .database,
            "mysql": .database,
            "mysql_async": .database,
            "mongodb": .database,
            "redis": .database,
            "redis-rs": .database,
            "surrealdb": .database,
            "scylla": .database,
            
            // Async Runtime
            "tokio": .backend,
            "async-std": .backend,
            "smol": .backend,
            
            // Serialization
            "serde": .backend,
            "serde_json": .backend,
            "toml": .backend,
            
            // HTTP Clients
            "reqwest": .backend,
            "hyper": .backend,
            
            // CLI & Tools
            "clap": .devops,
            "structopt": .devops,
            "crossterm": .devops,
            "ratatui": .devops,
            "dialoguer": .devops,
            "indicatif": .devops,
            "console": .devops,
            "owo-colors": .devops,
            
            // Testing
            "tokio-test": .devops,
            "criterion": .devops,
            "mockall": .devops,
            
            // WASM
            "wasm-bindgen": .other,
            "wasm-bindgen-futures": .other,
            "yew": .frontend,
            "leptos": .frontend,
            "dioxus": .frontend,
            "sycamore": .frontend,
            
            // Other
            "rand": .backend,
            "uuid": .backend,
            "chrono": .backend,
            "time": .backend,
            "regex": .backend,
            "lazy_static": .backend,
            "once_cell": .backend,
            "thiserror": .backend,
            "anyhow": .backend,
            "tracing": .backend,
            "log": .backend,
            "env_logger": .devops,
        ],
        
        .gomod: [
            // Web Frameworks
            "gin": .backend,
            "github.com/gin-gonic/gin": .backend,
            "echo": .backend,
            "github.com/labstack/echo": .backend,
            "chi": .backend,
            "github.com/go-chi/chi": .backend,
            "mux": .backend,
            "github.com/gorilla/mux": .backend,
            "fiber": .backend,
            "github.com/gofiber/fiber": .backend,
            "beego": .backend,
            "github.com/beego/beego": .backend,
            "kratos": .backend,
            "github.com/go-kratos/kratos": .backend,
            "go-zero": .backend,
            "github.com/zeromicro/go-zero": .backend,
            
            // Database & ORM
            "gorm": .database,
            "gorm.io/gorm": .database,
            "gorm.io/driver/postgres": .database,
            "gorm.io/driver/mysql": .database,
            "sqlx": .database,
            "github.com/jmoiron/sqlx": .database,
            "pgx": .database,
            "github.com/jackc/pgx": .database,
            "mongo-driver": .database,
            "go.mongodb.org/mongo-driver": .database,
            "redis": .database,
            "github.com/redis/go-redis": .database,
            "goredis": .database,
            "github.com/go-redis/redis": .database,
            "ent": .database,
            "entgo.io/ent": .database,
            
            // HTTP Clients
            "resty": .backend,
            "github.com/go-resty/resty": .backend,
            
            // Microservices
            "grpc": .backend,
            "google.golang.org/grpc": .backend,
            "protobuf": .backend,
            "google.golang.org/protobuf": .backend,
            "nats": .backend,
            "github.com/nats-io/nats.go": .backend,
            
            // Utilities
            "cobra": .devops,
            "github.com/spf13/cobra": .devops,
            "viper": .backend,
            "github.com/spf13/viper": .backend,
            "logrus": .backend,
            "github.com/sirupsen/logrus": .backend,
            "zap": .backend,
            "go.uber.org/zap": .backend,
            "slog": .backend,
            "log/slog": .backend,
            "testify": .devops,
            "github.com/stretchr/testify": .devops,
        ],
        
        .maven: [
            "spring-boot": .backend,
            "spring-web": .backend,
            "spring-data-jpa": .database,
            "spring-data-mongodb": .database,
            "spring-security": .backend,
            "hibernate-core": .database,
            "junit": .devops,
            "mockito": .devops,
            "lombok": .devops,
            "jackson-databind": .backend,
            "gson": .backend,
        ],
        
        .gradle: [
            "spring-boot": .backend,
            "spring-web": .backend,
            "kotlin-gradle-plugin": .devops,
            "android-gradle-plugin": .devops,
        ],
        
        .gem: [
            "rails": .backend,
            "sinatra": .backend,
            "hanami": .backend,
            "roda": .backend,
            "cuba": .backend,
            "padrino": .backend,
            "activerecord": .database,
            "mongoid": .database,
            "sequel": .database,
            "sidekiq": .backend,
            "rspec": .devops,
            "factory_bot": .devops,
            "cucumber": .devops,
            "capistrano": .devops,
            "devise": .backend,
            "omniauth": .backend,
            "pundit": .backend,
            "cancancan": .backend,
            "stripe": .backend,
            "aws-sdk": .backend,
            "httparty": .backend,
            "faraday": .backend,
        ],
        
        .composer: [
            "laravel": .backend,
            "symfony": .backend,
            "zendframework": .backend,
            "laminas": .backend,
            "cakephp": .backend,
            "codeigniter": .backend,
            "slim": .backend,
            "silex": .backend,
            "doctrine": .database,
            "eloquent": .database,
            "phpunit": .devops,
            "behat": .devops,
            "guzzle": .backend,
        ]
    ]
    
    // MARK: - Pattern Matching Rules
    
    /// Patterns that indicate frontend packages
    static let frontendPatterns: [String] = [
        "react", "vue", "angular", "svelte", "solid", "preact",
        "next", "nuxt", "gatsby", "remix", "astro",
        "tailwind", "bootstrap", "mui", "chakra", "antd",
        "framer", "gsap", "three", "d3", "chart",
        "css", "sass", "scss", "less", "stylus",
        "webpack", "vite", "parcel", "rollup", "esbuild",
        "babel", "typescript", "ts-node", "swc",
        "jquery", "ember", "backbone", "knockout",
        "htmx", "alpine", "lit", "stencil", "lit-element"
    ]
    
    /// Patterns that indicate backend packages
    static let backendPatterns: [String] = [
        "express", "fastify", "koa", "hapi", "nest", "adonis",
        "django", "flask", "fastapi", "tornado", "bottle", "pyramid",
        "spring", "spring-boot", "spring-web",
        "rails", "sinatra", "hanami",
        "laravel", "symfony",
        "actix", "axum", "rocket", "warp", "tide",
        "gin", "echo", "chi", "fiber", "beego", "kratos",
        "graphql", "rest", "api", "server",
        "socket", "ws", "websocket",
        "auth", "jwt", "passport", "oauth", "session",
        "http", "request", "fetch", "axios", "reqwest", "guzzle",
        "grpc", "protobuf", "thrift",
        "celery", "sidekiq", "bull", "kue"
    ]
    
    /// Patterns that indicate database packages
    static let databasePatterns: [String] = [
        "mongo", "mongoose", "mongodb",
        "postgres", "pg", "psycopg", "asyncpg",
        "mysql", "mariadb", "sqlite", "sqlite3",
        "redis", "ioredis", "aioredis",
        "prisma", "sequelize", "typeorm", "sqlalchemy",
        "diesel", "sea-orm", "sqlx", "gorm", "activerecord",
        "orm", "driver", "client", "database", "db",
        "firebase", "supabase", "fauna", "dynamodb",
        "cassandra", "neo4j", "arangodb", "couchdb",
        "elasticsearch", "meilisearch", "algolia",
        "clickhouse", "timescaledb", "influxdb",
        "cockroach", "yugabyte", "planetscale",
        "snowflake", "bigquery", "redshift"
    ]
    
    /// Patterns that indicate DevOps/testing packages
    static let devopsPatterns: [String] = [
        "jest", "vitest", "mocha", "chai", "cypress", "playwright",
        "puppeteer", "selenium", "test", "testing",
        "webpack", "vite", "rollup", "esbuild", "parcel", "turbopack",
        "babel", "swc", "typescript", "ts-node", "tsx",
        "docker", "kubernetes", "k8s", "helm",
        "terraform", "pulumi", "ansible", "chef", "puppet",
        "ci", "cd", "deploy", "pipeline", "action",
        "lint", "eslint", "prettier", "format",
        "husky", "commitlint", "semantic-release", "changeset",
        "nodemon", "pm2", "forever", "ts-node-dev",
        "pytest", "unittest", "mock", "factory", "faker",
        "rspec", "cucumber", "behat", "phpunit",
        "criterion", "mockall", "tokio-test",
        "clap", "structopt", "typer", "click"
    ]
    
    // MARK: - Classification Functions
    
    /// Determines the proper TechType from an EcosystemType
    static func techType(from ecosystem: EcosystemType) -> TechType {
        switch ecosystem {
        case .npm: return .npm
        case .pypi: return .pypi
        case .cargo: return .cargo
        case .gomod: return .gomod
        case .maven: return .maven
        case .gradle: return .gradle
        case .gem: return .gem
        case .composer: return .composer
        }
    }
    
    /// Classifies a package into a TechCategory based on name and ecosystem
    static func classify(
        name: String,
        ecosystem: TechType
    ) -> TechCategory {
        let lowercased = name.lowercased()
        
        // 1. Check known packages database
        if let known = knownPackages[ecosystem],
           let category = known[name] {
            return category
        }
        
        // 2. Apply pattern matching for unknown packages
        return inferCategory(from: lowercased)
    }
    
    /// Infers category from package name using pattern matching
    static func inferCategory(from name: String) -> TechCategory {
        let lower = name.lowercased()
        
        // Check DevOps patterns first (most specific)
        if matchesAny(lower, patterns: devopsPatterns) {
            return .devops
        }
        
        // Check database patterns
        if matchesAny(lower, patterns: databasePatterns) {
            return .database
        }
        
        // Check frontend patterns
        if matchesAny(lower, patterns: frontendPatterns) {
            return .frontend
        }
        
        // Check backend patterns
        if matchesAny(lower, patterns: backendPatterns) {
            return .backend
        }
        
        // Default
        return .other
    }
    
    /// Checks if string matches any of the given patterns
    private static func matchesAny(_ string: String, patterns: [String]) -> Bool {
        patterns.contains { pattern in
            string.contains(pattern)
        }
    }
    
    // MARK: - Helper Functions
    
    /// Get a user-friendly description of a technology
    static func description(for name: String, type: TechType) -> String {
        switch type {
        case .npm: return "\(name) — NPM Package"
        case .pypi: return "\(name) — Python Package"
        case .cargo: return "\(name) — Rust Crate"
        case .gomod: return "\(name) — Go Module"
        case .maven: return "\(name) — Maven Package"
        case .gradle: return "\(name) — Gradle Package"
        case .gem: return "\(name) — Ruby Gem"
        case .composer: return "\(name) — PHP Package"
        case .github: return "\(name) — GitHub Repository"
        case .language: return "\(name) — Programming Language"
        case .platform: return "\(name) — Platform/Service"
        }
    }
}
