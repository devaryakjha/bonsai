import Foundation

struct GitIgnoreTemplate: Identifiable, Hashable {
  var id: String
  var name: String
  var summary: String
  var patterns: [String]
}

enum GitIgnoreTemplateCatalog {
  static let all: [GitIgnoreTemplate] = [
    GitIgnoreTemplate(
      id: "macos",
      name: "macOS",
      summary: "Finder metadata, Spotlight indexes, and AppleDouble files.",
      patterns: [
        ".DS_Store",
        ".AppleDouble",
        ".LSOverride",
        "._*",
        ".Spotlight-V100",
        ".Trashes"
      ]
    ),
    GitIgnoreTemplate(
      id: "xcode",
      name: "Xcode",
      summary: "Derived data, user schemes, archives, and build products.",
      patterns: [
        "DerivedData/",
        "build/",
        "*.xcuserstate",
        "xcuserdata/",
        "*.xccheckout",
        "*.moved-aside",
        "*.xcscmblueprint"
      ]
    ),
    GitIgnoreTemplate(
      id: "swift",
      name: "Swift",
      summary: "SwiftPM build output and editor state.",
      patterns: [
        ".build/",
        ".swiftpm/",
        "*.xcodeproj/project.xcworkspace/xcuserdata/"
      ]
    ),
    GitIgnoreTemplate(
      id: "node",
      name: "Node",
      summary: "Dependencies, package-manager caches, and local environment files.",
      patterns: [
        "node_modules/",
        ".npm/",
        ".yarn/",
        ".pnp.*",
        "dist/",
        "coverage/",
        ".env",
        ".env.local"
      ]
    ),
    GitIgnoreTemplate(
      id: "python",
      name: "Python",
      summary: "Bytecode, virtual environments, test caches, and build artifacts.",
      patterns: [
        "__pycache__/",
        "*.py[cod]",
        ".Python",
        ".venv/",
        "venv/",
        ".pytest_cache/",
        ".mypy_cache/",
        "dist/",
        "build/",
        "*.egg-info/"
      ]
    ),
    GitIgnoreTemplate(
      id: "go",
      name: "Go",
      summary: "Compiled binaries, test output, and workspace files.",
      patterns: [
        "*.test",
        "*.out",
        "bin/",
        "vendor/"
      ]
    ),
    GitIgnoreTemplate(
      id: "rust",
      name: "Rust",
      summary: "Cargo build output and local lockfile exceptions.",
      patterns: [
        "target/",
        "**/*.rs.bk"
      ]
    ),
    GitIgnoreTemplate(
      id: "java",
      name: "Java",
      summary: "Class files, package artifacts, and common build directories.",
      patterns: [
        "*.class",
        "*.jar",
        "*.war",
        "*.ear",
        "target/",
        "build/",
        ".gradle/"
      ]
    ),
    GitIgnoreTemplate(
      id: "android",
      name: "Android",
      summary: "Gradle output, local SDK config, and generated Android files.",
      patterns: [
        ".gradle/",
        "local.properties",
        ".idea/",
        "build/",
        "captures/",
        "*.apk",
        "*.aab"
      ]
    ),
    GitIgnoreTemplate(
      id: "flutter",
      name: "Flutter",
      summary: "Flutter tool state, packages, and generated plugin registrants.",
      patterns: [
        ".dart_tool/",
        ".flutter-plugins",
        ".flutter-plugins-dependencies",
        ".packages",
        "build/",
        "ios/Flutter/Generated.xcconfig",
        "ios/Flutter/flutter_export_environment.sh",
        "android/app/profile",
        "android/app/release"
      ]
    )
  ]

  static var defaultTemplateID: String {
    all.first?.id ?? ""
  }

  static func template(id: String) -> GitIgnoreTemplate? {
    all.first { $0.id == id }
  }
}
