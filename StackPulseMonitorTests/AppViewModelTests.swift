//
//  AppViewModelTests.swift
//  StackPulseMonitorTests
//
//  Tests for AppViewModel business logic
//

import Foundation
import Testing
@testable import StackPulseMonitor

@MainActor
struct AppViewModelTests {
    
    // MARK: - Initialization
    
    @Test func initialState() {
        let viewModel = AppViewModel()
        
        #expect(viewModel.projects.isEmpty)
        #expect(viewModel.stackItems.isEmpty)
        #expect(viewModel.alerts.isEmpty)
        #expect(viewModel.isSyncing == false)
        #expect(viewModel.hasOnboarded == false)
        #expect(viewModel.hasCompletedSetup == false)
    }
    
    // MARK: - Computed Properties
    
    @Test func totalDependencies() {
        let viewModel = AppViewModel()
        viewModel.projects = [
            Project(name: "Project1", source: .manual, dependencies: [
                Dependency(name: "react", type: .npm, category: .frontend, currentVersion: "18.2.0"),
                Dependency(name: "vue", type: .npm, category: .frontend, currentVersion: "3.4.0")
            ]),
            Project(name: "Project2", source: .manual, dependencies: [
                Dependency(name: "express", type: .npm, category: .backend, currentVersion: "4.18.0")
            ])
        ]
        
        #expect(viewModel.totalDependencies == 3)
    }
    
    @Test func totalOutdated() {
        let viewModel = AppViewModel()
        viewModel.projects = [
            Project(name: "Project1", source: .manual, dependencies: [
                Dependency(name: "react", type: .npm, category: .frontend, 
                          currentVersion: "18.2.0", latestVersion: "18.2.0", isOutdated: false),
                Dependency(name: "vue", type: .npm, category: .frontend,
                          currentVersion: "3.3.0", latestVersion: "3.4.0", isOutdated: true)
            ]),
            Project(name: "Project2", source: .manual, dependencies: [
                Dependency(name: "express", type: .npm, category: .backend,
                          currentVersion: "4.17.0", latestVersion: "4.18.0", isOutdated: true)
            ])
        ]
        
        #expect(viewModel.totalOutdated == 2)
    }
    
    @Test func healthScore100Percent() {
        let viewModel = AppViewModel()
        viewModel.projects = [
            Project(name: "Project1", source: .manual, dependencies: [
                Dependency(name: "react", type: .npm, category: .frontend, 
                          currentVersion: "18.2.0", latestVersion: "18.2.0", isOutdated: false)
            ])
        ]
        
        #expect(viewModel.healthScore == 100)
    }
    
    @Test func healthScore0Percent() {
        let viewModel = AppViewModel()
        viewModel.projects = [
            Project(name: "Project1", source: .manual, dependencies: [
                Dependency(name: "react", type: .npm, category: .frontend, 
                          currentVersion: "17.0.0", latestVersion: "18.2.0", isOutdated: true)
            ])
        ]
        
        #expect(viewModel.healthScore == 0)
    }
    
    @Test func healthScore50Percent() {
        let viewModel = AppViewModel()
        viewModel.projects = [
            Project(name: "Project1", source: .manual, dependencies: [
                Dependency(name: "react", type: .npm, category: .frontend, 
                          currentVersion: "18.2.0", latestVersion: "18.2.0", isOutdated: false),
                Dependency(name: "vue", type: .npm, category: .frontend,
                          currentVersion: "3.3.0", latestVersion: "3.4.0", isOutdated: true)
            ])
        ]
        
        #expect(viewModel.healthScore == 50)
    }
    
    // MARK: - Project Management
    
    @Test func addProject() {
        let viewModel = AppViewModel()
        let project = Project(name: "TestProject", source: .manual, dependencies: [])
        
        viewModel.addProject(project)
        
        #expect(viewModel.projects.count == 1)
        #expect(viewModel.projects.first?.name == "TestProject")
    }
    
    @Test func removeProject() {
        let viewModel = AppViewModel()
        let project = Project(name: "TestProject", source: .manual, dependencies: [])
        viewModel.addProject(project)
        
        let projectId = project.id
        viewModel.removeProject(project, deleteDependencies: false)
        
        #expect(viewModel.projects.isEmpty)
    }
    
    @Test func toggleProjectExpansion() {
        let viewModel = AppViewModel()
        let project = Project(name: "TestProject", source: .manual, isExpanded: true, dependencies: [])
        viewModel.addProject(project)
        
        let projectId = project.id
        viewModel.toggleProjectExpansion(project)
        
        #expect(viewModel.projects.first?.isExpanded == false)
    }
    
    // MARK: - Technology Stack
    
    @Test func addTechnology() {
        let viewModel = AppViewModel()
        let tech = Technology(name: "React", type: .npm, category: .frontend)
        
        viewModel.addTechnology(tech)
        
        #expect(viewModel.stackItems.count == 1)
    }
    
    @Test func removeTechnology() {
        let viewModel = AppViewModel()
        let tech = Technology(name: "React", type: .npm, category: .frontend)
        viewModel.addTechnology(tech)
        
        viewModel.removeTechnology(tech)
        
        #expect(viewModel.stackItems.isEmpty)
    }
    
    // MARK: - Alert Management
    
    @Test func dismissAlert() {
        let viewModel = AppViewModel()
        let alert = TechAlert(
            techId: UUID(),
            techName: "React",
            type: .update,
            title: "Update Available",
            message: "React 19 is available"
        )
        viewModel.alerts = [alert]
        
        viewModel.dismissAlert(alert)
        
        #expect(viewModel.alerts.first?.isDismissed == true)
    }
    
    @Test func snoozeAlert() {
        let viewModel = AppViewModel()
        let alert = TechAlert(
            techId: UUID(),
            techName: "React",
            type: .update,
            title: "Update Available",
            message: "React 19 is available"
        )
        viewModel.alerts = [alert]
        
        let beforeSnooze = Date()
        viewModel.snoozeAlert(alert, days: 3)
        
        #expect(viewModel.alerts.first?.snoozedUntil != nil)
    }
    
    @Test func deleteAlert() {
        let viewModel = AppViewModel()
        let alert = TechAlert(
            techId: UUID(),
            techName: "React",
            type: .update,
            title: "Update Available",
            message: "React 19 is available"
        )
        viewModel.alerts = [alert]
        
        viewModel.deleteAlert(alert)
        
        #expect(viewModel.alerts.isEmpty)
    }
    
    @Test func activeAlerts() {
        let viewModel = AppViewModel()
        let alert = TechAlert(
            techId: UUID(),
            techName: "React",
            type: .update,
            title: "Update Available",
            message: "React 19 is available"
        )
        viewModel.alerts = [alert]
        
        #expect(viewModel.activeAlerts.count == 1)
    }
    
    @Test func dismissedAlertsFilteredFromActive() {
        let viewModel = AppViewModel()
        let alert = TechAlert(
            techId: UUID(),
            techName: "React",
            type: .update,
            title: "Update Available",
            message: "React 19 is available",
            isDismissed: true
        )
        viewModel.alerts = [alert]
        
        #expect(viewModel.activeAlerts.isEmpty)
    }
    
    @Test func snoozedAlertsFilteredFromActive() {
        let viewModel = AppViewModel()
        let futureSnooze = Date().addingTimeInterval(86400 * 7) // 7 days from now
        let alert = TechAlert(
            techId: UUID(),
            techName: "React",
            type: .update,
            title: "Update Available",
            message: "React 19 is available",
            snoozedUntil: futureSnooze
        )
        viewModel.alerts = [alert]
        
        #expect(viewModel.activeAlerts.isEmpty)
    }
    
    // MARK: - Onboarding
    
    @Test func completeOnboarding() {
        let viewModel = AppViewModel()
        
        viewModel.completeOnboarding()
        
        #expect(viewModel.hasOnboarded == true)
    }
    
    @Test func completeSetup() {
        let viewModel = AppViewModel()
        
        viewModel.completeSetup()
        
        #expect(viewModel.hasCompletedSetup == true)
    }
}
