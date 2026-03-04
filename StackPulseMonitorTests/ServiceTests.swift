//
//  ServiceTests.swift
//  StackPulseMonitorTests
//
//  Tests for Services - NetworkService, VersionCheckService
//

import Foundation
import Testing
@testable import StackPulseMonitor

// MARK: - NetworkService Tests

struct NetworkServiceTests {
    
    @Test func sharedInstanceExists() {
        let _ = NetworkService.shared
    }
    
    @Test func npmPackageURL() {
        let url = URL(string: "https://registry.npmjs.org/react/latest")
        #expect(url != nil)
    }
    
    @Test func githubReleaseURL() {
        let url = URL(string: "https://api.github.com/repos/facebook/react/releases/latest")
        #expect(url != nil)
    }
    
    @Test func osvURL() {
        let url = URL(string: "https://api.osv.dev/v1/query")
        #expect(url != nil)
    }
    
    @Test func eolURL() {
        let url = URL(string: "https://endoflife.date/api/react.json")
        #expect(url != nil)
    }
}

// MARK: - VersionCheckService Tests

struct VersionCheckServiceTests {
    
    @Test func sharedInstanceExists() {
        let _ = VersionCheckService.shared
    }
    
    @Test func npmVersionCheck() async throws {
        let service = VersionCheckService.shared
        
        // Test checking a real npm package
        let latestVersion = await service.checkVersion(
            Dependency(name: "react", type: .npm, category: .frontend, currentVersion: "18.0.0")
        )
        
        // Should get a version string (or nil if fails)
        #expect(latestVersion != nil)
    }
    
    @Test func pypiVersionCheck() async throws {
        let service = VersionCheckService.shared
        
        let latestVersion = await service.checkVersion(
            Dependency(name: "requests", type: .pypi, category: .backend, currentVersion: "2.0.0")
        )
        
        #expect(latestVersion != nil)
    }
    
    @Test func unknownPackageReturnsNil() async throws {
        let service = VersionCheckService.shared
        
        let latestVersion = await service.checkVersion(
            Dependency(name: "nonexistent-package-xyz-123", type: .npm, category: .frontend, currentVersion: "1.0.0")
        )
        
        // Unknown packages should return nil
        #expect(latestVersion == nil)
    }
}

// MARK: - Technology Model Tests

struct TechnologyTests {
    
    @Test func basicTechnology() {
        let tech = Technology(name: "React", type: .npm, category: .frontend)
        
        #expect(tech.name == "React")
        #expect(tech.type == .npm)
        #expect(tech.category == .frontend)
    }
    
    @Test func technologyStatusUpdate() {
        let outdatedTech = Technology(
            name: "React",
            type: .npm,
            category: .frontend,
            currentVersion: "17.0.0",
            latestVersion: "18.2.0"
        )
        
        #expect(outdatedTech.status == .update)
    }
    
    @Test func technologyStatusOK() {
        let okTech = Technology(
            name: "React",
            type: .npm,
            category: .frontend,
            currentVersion: "18.2.0",
            latestVersion: "18.2.0"
        )
        
        #expect(okTech.status == .ok)
    }
}

// MARK: - TechAlert Tests

struct TechAlertTests {
    
    @Test func basicAlert() {
        let alert = TechAlert(
            techId: UUID(),
            techName: "React",
            type: .update,
            title: "Update Available",
            message: "React 18 is available"
        )
        
        #expect(alert.techName == "React")
        #expect(alert.type == .update)
        #expect(alert.isDismissed == false)
        #expect(alert.snoozedUntil == nil)
    }
    
    @Test func dismissedAlert() {
        let alert = TechAlert(
            techId: UUID(),
            techName: "React",
            type: .update,
            title: "Update Available",
            message: "React 18 is available",
            isDismissed: true
        )
        
        #expect(alert.isDismissed == true)
    }
    
    @Test func snoozedAlert() {
        let futureDate = Date().addingTimeInterval(86400 * 7)
        let alert = TechAlert(
            techId: UUID(),
            techName: "React",
            type: .update,
            title: "Update Available",
            message: "React 18 is available",
            snoozedUntil: futureDate
        )
        
        #expect(alert.snoozedUntil != nil)
    }
}
