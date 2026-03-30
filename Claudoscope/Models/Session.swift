import Foundation

// MARK: - Parsed Session (full detail)

struct ParsedSession: Sendable {
    let id: String
    let projectId: String
    let slug: String?
    let records: [ParsedRecordRaw]
    let toolResultMap: [String: ToolResultEntry]
    let metadata: SessionMetadata
    let parentSessionId: String?
    let isSubagent: Bool

    init(id: String, projectId: String, slug: String?, records: [ParsedRecordRaw], toolResultMap: [String: ToolResultEntry], metadata: SessionMetadata, parentSessionId: String?, isSubagent: Bool = false) {
        self.id = id
        self.projectId = projectId
        self.slug = slug
        self.records = records
        self.toolResultMap = toolResultMap
        self.metadata = metadata
        self.parentSessionId = parentSessionId
        self.isSubagent = isSubagent
    }
}

struct ToolResultEntry: Sendable {
    let content: String
    let isError: Bool
    let timestamp: String?
}

// MARK: - Session Metadata

struct SessionMetadata: Sendable {
    let firstTimestamp: String
    let lastTimestamp: String
    let messageCount: Int
    let userMessageCount: Int
    let assistantMessageCount: Int
    let totalInputTokens: Int
    let totalOutputTokens: Int
    let totalCacheReadTokens: Int
    let totalCacheCreationTokens: Int
    let models: [String]
    let compactionCount: Int
    let turnDurations: [TurnDuration]
    let effortDistribution: EffortDistribution
    let maxIdleGapSeconds: Double
    let idleGapAfterTimestamp: String?
    let compactionEvents: [CompactionEvent]
    let parallelToolGroups: [ParallelToolGroup]
    let errorDetails: [SessionErrorDetail]
}

// MARK: - Session Summary (lightweight for sidebar)

struct SessionSummary: Identifiable, Sendable {
    let id: String
    let projectId: String
    let slug: String?
    let title: String
    let firstTimestamp: String
    let lastTimestamp: String
    let messageCount: Int
    let primaryModel: String?
    let totalInputTokens: Int
    let totalOutputTokens: Int
    let totalCacheReadTokens: Int
    let totalCacheCreationTokens: Int
    let totalCacheCreation5mTokens: Int
    let totalCacheCreation1hTokens: Int
    let compactionCount: Int
    let estimatedCost: Double
    let hasError: Bool
    let modelBreakdown: [ModelTokenBreakdown]
    let toolCallCount: Int
    let observability: SessionObservability
    let parentSessionId: String?

    init(
        id: String,
        projectId: String,
        slug: String?,
        title: String,
        firstTimestamp: String,
        lastTimestamp: String,
        messageCount: Int,
        primaryModel: String?,
        totalInputTokens: Int,
        totalOutputTokens: Int,
        totalCacheReadTokens: Int,
        totalCacheCreationTokens: Int,
        totalCacheCreation5mTokens: Int,
        totalCacheCreation1hTokens: Int,
        compactionCount: Int,
        estimatedCost: Double,
        hasError: Bool,
        modelBreakdown: [ModelTokenBreakdown],
        toolCallCount: Int,
        observability: SessionObservability,
        parentSessionId: String? = nil
    ) {
        self.id = id
        self.projectId = projectId
        self.slug = slug
        self.title = title
        self.firstTimestamp = firstTimestamp
        self.lastTimestamp = lastTimestamp
        self.messageCount = messageCount
        self.primaryModel = primaryModel
        self.totalInputTokens = totalInputTokens
        self.totalOutputTokens = totalOutputTokens
        self.totalCacheReadTokens = totalCacheReadTokens
        self.totalCacheCreationTokens = totalCacheCreationTokens
        self.totalCacheCreation5mTokens = totalCacheCreation5mTokens
        self.totalCacheCreation1hTokens = totalCacheCreation1hTokens
        self.compactionCount = compactionCount
        self.estimatedCost = estimatedCost
        self.hasError = hasError
        self.modelBreakdown = modelBreakdown
        self.toolCallCount = toolCallCount
        self.observability = observability
        self.parentSessionId = parentSessionId
    }

    func withParentSessionId(_ parentId: String) -> SessionSummary {
        SessionSummary(
            id: id, projectId: projectId, slug: slug, title: title,
            firstTimestamp: firstTimestamp, lastTimestamp: lastTimestamp,
            messageCount: messageCount, primaryModel: primaryModel,
            totalInputTokens: totalInputTokens, totalOutputTokens: totalOutputTokens,
            totalCacheReadTokens: totalCacheReadTokens,
            totalCacheCreationTokens: totalCacheCreationTokens,
            totalCacheCreation5mTokens: totalCacheCreation5mTokens,
            totalCacheCreation1hTokens: totalCacheCreation1hTokens,
            compactionCount: compactionCount, estimatedCost: estimatedCost,
            hasError: hasError, modelBreakdown: modelBreakdown,
            toolCallCount: toolCallCount, observability: observability,
            parentSessionId: parentId
        )
    }
}

struct ModelTokenBreakdown: Sendable {
    let model: String           // model family: "opus", "sonnet", "haiku"
    let inputTokens: Int
    let outputTokens: Int
    let cacheReadTokens: Int
    let estimatedCost: Double
    let turnCount: Int
}
