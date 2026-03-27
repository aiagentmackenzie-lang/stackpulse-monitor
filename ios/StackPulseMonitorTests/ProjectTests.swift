//
//  ProjectTests.swift
//  StackPulseMonitorTests
//
//  Tests for Project and Dependency models
//

import Testing
@testable import StackPulseMonitor

struct ProjectTests {
    
    // MARK: - Dependency Count Tests
    
    @Test func dependencyCount() {
        let project = Project(name: "Test", source: .manual, dependencies: [
            Dependency(name: "react", type: .npm, category: .frontend, currentVersion: "18.2.0"),
            Dependency(name: "vue", type: .npm, category: .frontend, currentVersion: "3.4.0"),
            Dependency(name: "express", type: .npm, category: .backend, currentVersion: "4.18.0")
        ])
        #expect(project.dependencyCount == 3)
    }
    
    @Test func outdatedCount() {
        let project = Project(name: "Test", source: .manual, dependencies: [
            Dependency(name: "react", type: .npm, category: .frontend, 
                      currentVersion: "18.2.0", latestVersion: "18.2.0", isOutdated: false),
            Dependency(name: "vue", type: .npm, category: .frontend,
                      currentVersion: "3.3.0", latestVersion: "3.4.0", isOutdated: true),
            Dependency(name: "express", type: .npm, category: .backend,
                      currentVersion: "4.17.0", latestVersion: "4.18.0", isOutdated: true)
        ])
        #expect(project.outdatedCount == 2)
    }
    
    // MARK: - Source Tests
    
    @Test func isFromGitHubManual() {
        let project = Project(name: "Test", source: .manual, dependencies: [])
        #expect(project.isFromGitHub == false)
    }
    
    @Test func isFromGitHubGitHub() {
        let project = Project(name: "Test", source: .github, githubFullName: "raphael/test", dependencies: [])
        #expect(project.isFromGitHub == true)
    }
    
    // MARK: - GitHub Enrichment Tests
    
    @Test func githubEnrichmentData() {
        var project = Project(name: "Test", source: .github, githubFullName: "raphael/test")
        project.description = "A test project"
        project.starsCount = 100
        project.forksCount = 25
        project.topics = ["swift", "ios"]
        
        #expect(project.description == "A test project")
        #expect(project.starsCount == 100)
        #expect(project.forksCount == 25)
        #expect(project.topics?.count == 2)
    }
    
    // MARK: - Expansion State Tests
    
    @Test func defaultExpansionState() {
        let project = Project(name: "Test", source: .manual, dependencies: [])
        #expect(project.isExpanded == true)
    }
    
    @Test func customExpansionState() {
        let project = Project(name: "Test", source: .manual, isExpanded: false, dependencies: [])
        #expect(project.isExpanded == false)
    }
}

// MARK: - Dependency Tests

struct DependencyTests {
    
    @Test func basicDependency() {
        let dep = Dependency(
            name: "react",
            type: .npm,
            category: .frontend,
            currentVersion: "18.2.0"
        )
        #expect(dep.name == "react")
        #expect(dep.currentVersion == "18.2.0")
        #expect(dep.latestVersion == nil)
    }
    
    @Test func outdatedDependency() {
        let dep = Dependency(
            name: "react",
            type: .npm,
            category: .frontend,
            currentVersion: "17.0.0",
            latestVersion: "18.2.0",
            isOutdated: true
        )
        #expect(dep.isOutdated == true)
    }
    
    @Test func upToDateDependency() {
        let dep = Dependency(
            name: "react",
            type: .npm,
            category: .frontend,
            currentVersion: "18.2.0",
            latestVersion: "18.2.0",
            isOutdated: false
        )
        #expect(dep.isOutdated == false)
    }
    
    // MARK: - Tech Type Tests
    
    @Test func npmType() {
        let dep = Dependency(name: "react", type: .npm, category: .frontend, currentVersion: "18.2.0")
        #expect(dep.type == .npm)
    }
    
    @Test func pypiType() {
        let dep = Dependency(name: "requests", type: .pypi, category: .backend, currentVersion: "2.31.0")
        #expect(dep.type == .pypi)
    }
    
    // MARK: - Category Tests
    
    @Test func frontendCategory() {
        let dep = Dependency(name: "react", type: .npm, category: .frontend, currentVersion: "18.2.0")
        #expect(dep.category == .frontend)
    }
    
    @Test func backendCategory() {
        let dep = Dependency(name: "express", type: .npm, category: .backend, currentVersion: "4.18.0")
        #expect(dep.category == .backend)
    }
    
    @Test func devopsCategory() {
        let dep = Dependency(name: "jest", type: .npm, category: .devops, currentVersion: "29.7.0")
        #expect(dep.category == .devops)
    }
}
