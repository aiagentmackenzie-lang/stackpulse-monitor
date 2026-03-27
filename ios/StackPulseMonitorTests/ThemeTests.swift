//
//  ThemeTests.swift
//  StackPulseMonitorTests
//
//  Tests for Theme colors and styling
//

import SwiftUI
import Testing
@testable import StackPulseMonitor

struct ThemeTests {
    
    // MARK: - Color Tests
    
    @Test func backgroundColorExists() {
        let _ = Theme.background
    }
    
    @Test func cardBackgroundExists() {
        let _ = Theme.cardBackground
    }
    
    @Test func accentColorExists() {
        let _ = Theme.accent
    }
    
    @Test func textPrimaryExists() {
        let _ = Theme.textPrimary
    }
    
    @Test func textSecondaryExists() {
        let _ = Theme.textSecondary
    }
    
    @Test func borderColorExists() {
        let _ = Theme.border
    }
}
