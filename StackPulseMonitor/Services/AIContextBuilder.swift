import Foundation

/// Builds system prompts with project context for AI chat
struct AIContextBuilder {
    
    // MARK: - System Prompt
    
    static func buildSystemPrompt(for project: Project) -> String {
        var context = """
        You are an AI assistant for StackPulse Monitor, helping with dependency analysis and management.
        
        Current Project: \(project.name)
        Total Dependencies: \(project.dependencyCount)
        Outdated Dependencies: \(project.outdatedCount)
        
        """
        
        // Add dependency breakdown
        if !project.dependencies.isEmpty {
            context += "\nDependencies:\n"
            
            let outdated = project.dependencies.filter { $0.isOutdated }
            if !outdated.isEmpty {
                context += "\nOutdated (need updates):\n"
                for dep in outdated.prefix(10) {
                    if let latest = dep.latestVersion {
                        context += "• \(dep.name): \(dep.currentVersion) → \(latest)\n"
                    } else {
                        context += "• \(dep.name): \(dep.currentVersion) (unknown latest)\n"
                    }
                }
                if outdated.count > 10 {
                    context += "... and \(outdated.count - 10) more\n"
                }
            }
            
            let upToDate = project.dependencies.filter { !$0.isOutdated }
            if !upToDate.isEmpty {
                context += "\nUp-to-date:\n"
                for dep in upToDate.prefix(5) {
                    context += "• \(dep.name): \(dep.currentVersion)\n"
                }
                if upToDate.count > 5 {
                    context += "... and \(upToDate.count - 5) more\n"
                }
            }
        }
        
        // Add latest analysis if available
        if let latestReport = project.aiReports.last {
            let timeAgo = formatDate(latestReport.generatedAt)
            context += """
            
            Latest Analysis (\(timeAgo)):
            • Risk Score: \(latestReport.overallRiskScore)/100
            • Summary: \(latestReport.summary)
            • Critical: \(latestReport.criticalUpdates.count) | Safe: \(latestReport.safeUpdates.count) | Review: \(latestReport.reviewRecommended.count)
            
            """
        }
        
        // Add instructions
        context += """
        
        You can help with:
        • Analyzing which dependencies need updating
        • Explaining breaking changes (if known)
        • Recommending update priorities
        • Comparing dependency health across projects
        • Answering questions about specific packages
        
        Be concise, helpful, and specific to this project's dependencies.
        """
        
        return context
    }
    
    // MARK: - Message Context
    
    static func buildMessageContext(
        project: Project,
        userMessage: String
    ) -> String {
        // Detect what user is asking about
        let lowerMessage = userMessage.lowercased()
        
        if lowerMessage.contains("update") || lowerMessage.contains("outdated") {
            return buildUpdateContext(project: project)
        } else if lowerMessage.contains("safe") {
            return buildSafeUpdateContext(project: project)
        } else if lowerMessage.contains("compare") || lowerMessage.contains("health") {
            return buildHealthContext(project: project)
        }
        
        return ""
    }
    
    // MARK: - Context Types
    
    private static func buildUpdateContext(project: Project) -> String {
        let outdated = project.dependencies.filter { $0.isOutdated }
        
        if outdated.isEmpty {
            return "All \(project.dependencyCount) dependencies are up to date!"
        }
        
        var context = "\(outdated.count) of \(project.dependencyCount) dependencies need updates:\n\n"
        
        for dep in outdated.prefix(10) {
            if let latest = dep.latestVersion {
                context += "• \(dep.name): \(dep.currentVersion) → \(latest)\n"
            }
        }
        
        if outdated.count > 10 {
            context += "... and \(outdated.count - 10) more\n"
        }
        
        return context
    }
    
    private static func buildSafeUpdateContext(project: Project) -> String {
        let upToDate = project.dependencies.filter { !$0.isOutdated }
        
        if upToDate.isEmpty {
            return "No 'safe' dependencies found."
        }
        
        var context = "✅ Currently up to date (\(upToDate.count)):\n\n"
        for dep in upToDate.prefix(10) {
            context += "• \(dep.name): \(dep.currentVersion)\n"
        }
        if upToDate.count > 10 {
            context += "... and \(upToDate.count - 10) more\n"
        }
        return context
    }
    
    private static func buildHealthContext(project: Project) -> String {
        let outdatedCount = project.dependencies.filter { $0.isOutdated }.count
        let total = project.dependencyCount
        let healthScore = total > 0 ? Int(Double(total - outdatedCount) / Double(total) * 100) : 100
        let lastAnalysis = project.aiReports.last?.generatedAt
        let lastAnalysisText = lastAnalysis.map { formatDate($0) } ?? "Never"
        
        return """
        Project Stats for \(project.name):
        • Total Dependencies: \(total)
        • Outdated: \(outdatedCount)
        • Health Score: \(healthScore)%
        • Last Analysis: \(lastAnalysisText)
        """
    }
    
    // MARK: - Helpers
    
    private static func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
