import SwiftUI

// MARK: - Timeline Sidebar Content

struct TimelineSidebarContent: View {
    let filterText: String
    let entries: [HistoryEntry]
    @Binding var selectedDay: String?
    var onSelect: ((HistoryEntry) -> Void)?

    private var filteredEntries: [HistoryEntry] {
        if filterText.isEmpty { return entries }
        return entries.filter { entry in
            entry.display.localizedCaseInsensitiveContains(filterText) ||
            (entry.project?.localizedCaseInsensitiveContains(filterText) ?? false) ||
            (entry.sessionId?.localizedCaseInsensitiveContains(filterText) ?? false)
        }
    }

    private var groupedByDay: [(key: String, entries: [HistoryEntry])] {
        let calendar = Calendar.current

        let grouped = Dictionary(grouping: filteredEntries) { entry -> String in
            if calendar.isDateInToday(entry.timestamp) {
                return "Today"
            } else if calendar.isDateInYesterday(entry.timestamp) {
                return "Yesterday"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "EEE, MMM d"
                return formatter.string(from: entry.timestamp)
            }
        }

        // Sort groups by the newest entry in each group
        return grouped
            .map { (key: $0.key, entries: $0.value.sorted { $0.timestamp > $1.timestamp }) }
            .sorted { groupA, groupB in
                let dateA = groupA.entries.first?.timestamp ?? .distantPast
                let dateB = groupB.entries.first?.timestamp ?? .distantPast
                return dateA > dateB
            }
    }

    var body: some View {
        if filteredEntries.isEmpty {
            VStack(spacing: 8) {
                Spacer()
                Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                    .font(.system(size: 24))
                    .foregroundStyle(.quaternary)
                Text("No history found")
                    .font(Typography.body)
                    .foregroundStyle(.tertiary)
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 40)
        } else {
            LazyVStack(alignment: .leading, spacing: 2) {
                ForEach(groupedByDay, id: \.key) { group in
                    daySection(group.key, entries: group.entries)
                }
            }
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private func daySection(_ dayLabel: String, entries: [HistoryEntry]) -> some View {
        Button {
            selectedDay = (selectedDay == dayLabel) ? nil : dayLabel
        } label: {
            HStack(spacing: 6) {
                Text(dayLabel)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(selectedDay == dayLabel ? .white : .secondary)

                Text("\(entries.count)")
                    .font(Typography.caption)
                    .foregroundStyle(selectedDay == dayLabel ? AnyShapeStyle(.white.opacity(0.7)) : AnyShapeStyle(.tertiary))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(selectedDay == dayLabel ? AnyShapeStyle(.white.opacity(0.2)) : AnyShapeStyle(.quaternary))
                    .clipShape(Capsule())

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 4)
            .background(selectedDay == dayLabel ? Color.accentColor : .clear)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .padding(.horizontal, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)

        ForEach(entries) { entry in
            TimelineSidebarRow(entry: entry) {
                onSelect?(entry)
            }
        }
    }
}

// MARK: - Timeline Sidebar Row

private struct TimelineSidebarRow: View {
    let entry: HistoryEntry
    let onSelect: () -> Void

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: entry.timestamp)
    }

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: 6) {
                Text(timeString)
                    .font(Typography.code)
                    .foregroundStyle(.tertiary)
                    .frame(width: 36, alignment: .leading)

                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.display)
                        .font(Typography.body)
                        .lineLimit(2)
                        .foregroundStyle(.primary)

                    if let label = projectLabel(entry.project) {
                        Text(label)
                            .font(Typography.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(AnyShapeStyle(.quaternary))
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Timeline Main Panel View

struct TimelineMainPanelView: View {
    let entries: [HistoryEntry]
    let isLoading: Bool

    @SceneStorage("timelineLayout") private var layout = "vertical"

    private var groupedByDay: [(key: String, entries: [HistoryEntry])] {
        let calendar = Calendar.current

        let grouped = Dictionary(grouping: entries) { entry -> String in
            if calendar.isDateInToday(entry.timestamp) {
                return "Today"
            } else if calendar.isDateInYesterday(entry.timestamp) {
                return "Yesterday"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "EEE, MMM d"
                return formatter.string(from: entry.timestamp)
            }
        }

        return grouped
            .map { (key: $0.key, entries: $0.value.sorted { $0.timestamp > $1.timestamp }) }
            .sorted { groupA, groupB in
                let dateA = groupA.entries.first?.timestamp ?? .distantPast
                let dateB = groupB.entries.first?.timestamp ?? .distantPast
                return dateA > dateB
            }
    }

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if entries.isEmpty {
                EmptyStateView(
                    icon: "clock.arrow.trianglehead.counterclockwise.rotate.90",
                    title: "No timeline entries",
                    message: "History entries from your Claude Code sessions will appear here."
                )
            } else {
                VStack(spacing: 0) {
                    layoutPicker
                    if layout == "horizontal" {
                        HorizontalTimelineView(entries: entries)
                    } else {
                        verticalTimelineContent
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var layoutPicker: some View {
        HStack {
            Spacer()
            Picker("Layout", selection: $layout) {
                Image(systemName: "list.bullet")
                    .accessibilityLabel("Vertical")
                    .tag("vertical")
                Image(systemName: "chart.bar.horizontal.page")
                    .accessibilityLabel("Horizontal")
                    .tag("horizontal")
            }
            .pickerStyle(.segmented)
            .frame(width: 80)
            .labelsHidden()
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }

    private var verticalTimelineContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(groupedByDay, id: \.key) { group in
                    dayHeader(group.key, count: group.entries.count)

                    ForEach(group.entries) { entry in
                        timelineRow(entry)
                    }
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
        }
    }

    @ViewBuilder
    private func dayHeader(_ label: String, count: Int) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.primary)

            Text("\(count)")
                .font(Typography.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(AnyShapeStyle(.quaternary))
                .clipShape(Capsule())

            Spacer()
        }
        .padding(.leading, 24)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private func timelineRow(_ entry: HistoryEntry) -> some View {
        let dotColor = projectColor(entry.project)

        HStack(alignment: .top, spacing: 0) {
            // Spine with dot
            ZStack {
                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 1)

                Circle()
                    .fill(dotColor)
                    .frame(width: 7, height: 7)
            }
            .frame(width: 16)

            // Entry content
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(formatTime(entry.timestamp))
                        .font(Typography.code)
                        .foregroundStyle(.tertiary)

                    Text(formatRelativeDate(entry.timestamp))
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }

                Text(entry.display)
                    .font(Typography.body)
                    .foregroundStyle(.primary)
                    .textSelection(.enabled)

                if let label = projectLabel(entry.project) {
                    Text(label)
                        .font(Typography.caption)
                        .foregroundStyle(dotColor)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(dotColor.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
            .padding(.leading, 10)
            .padding(.vertical, 8)
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

}

// MARK: - Horizontal Timeline View

struct HorizontalTimelineView: View {
    let entries: [HistoryEntry]

    @State private var selectedDate = Date()

    private static let hourWidth: CGFloat = 80
    private static let laneHeight: CGFloat = 48
    private static let projectColumnWidth: CGFloat = 150
    private static let pillMaxWidth: CGFloat = 100

    private var dayLabel: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(selectedDate) {
            return "Today"
        } else if calendar.isDateInYesterday(selectedDate) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE, MMM d"
            return formatter.string(from: selectedDate)
        }
    }

    private var entriesForDay: [HistoryEntry] {
        let calendar = Calendar.current
        return entries.filter { calendar.isDate($0.timestamp, inSameDayAs: selectedDate) }
    }

    private var projectLanes: [(name: String, path: String?, entries: [HistoryEntry])] {
        let grouped = Dictionary(grouping: entriesForDay) { $0.project ?? "" }
        return grouped
            .map { key, values in
                let name = projectLabel(key.isEmpty ? nil : key) ?? "Unknown"
                return (name: name, path: key.isEmpty ? nil : key, entries: values.sorted { $0.timestamp < $1.timestamp })
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private var hourRange: (start: Int, end: Int) {
        guard !entriesForDay.isEmpty else { return (9, 18) }
        let calendar = Calendar.current
        let hours = entriesForDay.map { calendar.component(.hour, from: $0.timestamp) }
        let minHour = max(0, (hours.min() ?? 9) - 1)
        let maxHour = min(23, (hours.max() ?? 17) + 1)
        return (minHour, maxHour)
    }

    private var contentWidth: CGFloat {
        let range = hourRange
        return CGFloat(range.end - range.start + 1) * Self.hourWidth
    }

    var body: some View {
        VStack(spacing: 0) {
            dayNavigationBar
            Divider()

            if entriesForDay.isEmpty {
                EmptyStateView(
                    icon: "calendar",
                    title: "No entries",
                    message: "No history entries for \(dayLabel)."
                )
            } else {
                swimlaneGrid
            }
        }
    }

    private var dayNavigationBar: some View {
        HStack(spacing: 12) {
            Button {
                selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
            } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.plain)

            Text(dayLabel)
                .font(Typography.bodyMedium)
                .frame(width: 100)

            Button {
                selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
            } label: {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
    }

    private var swimlaneGrid: some View {
        let range = hourRange

        return HStack(alignment: .top, spacing: 0) {
            // Fixed project name column
            VStack(alignment: .leading, spacing: 0) {
                // Spacer matching the time header height
                Color.clear
                    .frame(height: 24)

                ForEach(Array(projectLanes.enumerated()), id: \.offset) { index, lane in
                    HStack(spacing: 0) {
                        Text(lane.name)
                            .font(Typography.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, Spacing.sm)
                    }
                    .frame(height: Self.laneHeight)
                    .background(index.isMultiple(of: 2) ? Color.primary.opacity(0.02) : Color.primary.opacity(0.04))
                }
            }
            .frame(width: Self.projectColumnWidth)

            Divider()

            // Scrollable time content
            ScrollView(.horizontal) {
                VStack(alignment: .leading, spacing: 0) {
                    timeHeader(range: range)

                    ForEach(Array(projectLanes.enumerated()), id: \.offset) { index, lane in
                        laneRow(lane: lane, range: range, index: index)
                    }
                }
                .frame(width: contentWidth)
            }
        }
    }

    private func timeHeader(range: (start: Int, end: Int)) -> some View {
        ZStack(alignment: .leading) {
            ForEach(range.start...range.end, id: \.self) { hour in
                let x = CGFloat(hour - range.start) * Self.hourWidth

                Text(formatHourLabel(hour))
                    .font(Typography.micro)
                    .foregroundStyle(.tertiary)
                    .position(x: x + Self.hourWidth / 2, y: 12)
            }
        }
        .frame(width: contentWidth, height: 24)
    }

    private func laneRow(
        lane: (name: String, path: String?, entries: [HistoryEntry]),
        range: (start: Int, end: Int),
        index: Int
    ) -> some View {
        let color = projectColor(lane.path)

        return ZStack(alignment: .leading) {
            // Lane background
            Rectangle()
                .fill(index.isMultiple(of: 2) ? Color.primary.opacity(0.02) : Color.primary.opacity(0.04))

            // Hour grid lines
            ForEach(range.start...range.end, id: \.self) { hour in
                let x = CGFloat(hour - range.start) * Self.hourWidth
                Rectangle()
                    .fill(Color.secondary.opacity(0.1))
                    .frame(width: 1)
                    .offset(x: x)
            }

            // Entry pills
            ForEach(lane.entries) { entry in
                entryPill(entry: entry, color: color, rangeStart: range.start)
            }
        }
        .frame(width: contentWidth, height: Self.laneHeight)
    }

    private func entryPill(entry: HistoryEntry, color: Color, rangeStart: Int) -> some View {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: entry.timestamp)
        let minute = calendar.component(.minute, from: entry.timestamp)
        let x = CGFloat(hour - rangeStart) * Self.hourWidth + CGFloat(minute) / 60.0 * Self.hourWidth

        return Text(entry.display)
            .font(Typography.micro)
            .lineLimit(1)
            .foregroundStyle(.primary)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .frame(maxWidth: Self.pillMaxWidth, alignment: .leading)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(color.opacity(0.3), lineWidth: 1))
            .help(entry.display)
            .offset(x: x)
    }

    private func formatHourLabel(_ hour: Int) -> String {
        let period = hour >= 12 ? "PM" : "AM"
        let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        return "\(displayHour)\(period)"
    }
}

// MARK: - Helpers

private let timelineProjectColors: [Color] = [
    .blue.opacity(0.7),
    .green.opacity(0.7),
    .orange.opacity(0.7),
    .pink.opacity(0.7),
    .indigo.opacity(0.7),
    .yellow.opacity(0.7)
]

private func projectColor(_ path: String?) -> Color {
    guard let path else { return timelineProjectColors[0] }
    let hash = abs(path.hashValue)
    let index = hash % timelineProjectColors.count
    return timelineProjectColors[index]
}

private func projectLabel(_ path: String?) -> String? {
    guard let path else { return nil }
    return path.split(separator: "/").last.map(String.init)
}
