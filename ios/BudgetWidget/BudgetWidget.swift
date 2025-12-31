import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> BudgetEntry {
        BudgetEntry(
            date: Date(),
            spent: 450.00,
            limit: 800.00,
            month: "Dicembre 2024",
            currency: "€",
            isDarkMode: false,
            lastUpdated: Date(),
            groupName: nil
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (BudgetEntry) -> ()) {
        let entry = loadWidgetData() ?? placeholder(in: context)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let currentDate = Date()
        let entry = loadWidgetData() ?? placeholder(in: context)

        // Update every 30 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))

        completion(timeline)
    }

    private func loadWidgetData() -> BudgetEntry? {
        // Load data from App Group UserDefaults
        guard let userDefaults = UserDefaults(suiteName: "group.com.family.financetracker") else {
            return nil
        }

        let spent = userDefaults.double(forKey: "flutter.spent")
        let limit = userDefaults.double(forKey: "flutter.limit")
        let month = userDefaults.string(forKey: "flutter.month") ?? ""
        let currency = userDefaults.string(forKey: "flutter.currency") ?? "€"
        let isDarkMode = userDefaults.bool(forKey: "flutter.isDarkMode")
        let lastUpdatedTimestamp = userDefaults.double(forKey: "flutter.lastUpdated")
        let groupName = userDefaults.string(forKey: "flutter.groupName")

        let lastUpdated = lastUpdatedTimestamp > 0
            ? Date(timeIntervalSince1970: lastUpdatedTimestamp / 1000.0)
            : Date()

        return BudgetEntry(
            date: Date(),
            spent: spent,
            limit: limit,
            month: month,
            currency: currency,
            isDarkMode: isDarkMode,
            lastUpdated: lastUpdated,
            groupName: groupName?.isEmpty == false ? groupName : nil
        )
    }
}

struct BudgetEntry: TimelineEntry {
    let date: Date
    let spent: Double
    let limit: Double
    let month: String
    let currency: String
    let isDarkMode: Bool
    let lastUpdated: Date
    let groupName: String?

    var percentage: Double {
        guard limit > 0 else { return 0 }
        return (spent / limit) * 100
    }

    var spentFormatted: String {
        return "\(currency)\(String(format: "%.2f", spent))"
    }

    var limitFormatted: String {
        return "\(currency)\(String(format: "%.0f", limit))"
    }

    var isWarning: Bool {
        return percentage >= 80 && percentage < 100
    }

    var isCritical: Bool {
        return percentage >= 100
    }

    var progressColor: Color {
        if isCritical {
            return Color(red: 0.96, green: 0.26, blue: 0.21) // Red
        } else if isWarning {
            return Color(red: 1.0, green: 0.76, blue: 0.03) // Amber
        } else {
            return Color(red: 0.30, green: 0.69, blue: 0.31) // Green
        }
    }
}

struct BudgetWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry, colorScheme: colorScheme)
        case .systemMedium:
            MediumWidgetView(entry: entry, colorScheme: colorScheme)
        case .systemLarge:
            LargeWidgetView(entry: entry, colorScheme: colorScheme)
        @unknown default:
            MediumWidgetView(entry: entry, colorScheme: colorScheme)
        }
    }
}

struct SmallWidgetView: View {
    let entry: BudgetEntry
    let colorScheme: ColorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.month)
                .font(.caption)
                .foregroundColor(.secondary)

            Text("\(entry.spentFormatted) / \(entry.limitFormatted)")
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Text("\(Int(entry.percentage))%")
                .font(.subheadline)
                .foregroundColor(.secondary)

            ProgressView(value: entry.percentage, total: 100)
                .tint(entry.progressColor)
                .frame(height: 6)

            HStack(spacing: 8) {
                Link(destination: URL(string: "finapp://scan-receipt")!) {
                    Image(systemName: "doc.text.viewfinder")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.blue)
                        .cornerRadius(8)
                }

                Link(destination: URL(string: "finapp://add-expense")!) {
                    Image(systemName: "plus")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .containerBackground(for: .widget) {
            Color(colorScheme == .dark ? .systemBackground : .white)
        }
    }
}

struct MediumWidgetView: View {
    let entry: BudgetEntry
    let colorScheme: ColorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Budget display
            Link(destination: URL(string: "finapp://dashboard")!) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(entry.month)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(entry.spentFormatted)
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("/")
                            .foregroundColor(.secondary)

                        Text(entry.limitFormatted)
                            .foregroundColor(.secondary)

                        Spacer()

                        Text("\(Int(entry.percentage))%")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }

                    ProgressView(value: entry.percentage, total: 100)
                        .tint(entry.progressColor)
                        .frame(height: 8)
                }
            }

            // Quick actions
            HStack(spacing: 12) {
                Link(destination: URL(string: "finapp://scan-receipt")!) {
                    HStack {
                        Image(systemName: "doc.text.viewfinder")
                        Text("Scansiona")
                            .fontWeight(.medium)
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .cornerRadius(8)
                }

                Link(destination: URL(string: "finapp://add-expense")!) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Manuale")
                            .fontWeight(.medium)
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .cornerRadius(8)
                }
            }

            // Last updated
            HStack {
                Spacer()
                Text(formatLastUpdated(entry.lastUpdated))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .containerBackground(for: .widget) {
            Color(colorScheme == .dark ? .systemBackground : .white)
        }
    }
}

struct LargeWidgetView: View {
    let entry: BudgetEntry
    let colorScheme: ColorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Budget display
            Link(destination: URL(string: "finapp://dashboard")!) {
                VStack(alignment: .leading, spacing: 8) {
                    if let groupName = entry.groupName {
                        Text(groupName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text(entry.month)
                        .font(.headline)
                        .foregroundColor(.secondary)

                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(entry.spentFormatted)
                            .font(.largeTitle)
                            .fontWeight(.semibold)

                        Text("/")
                            .font(.title)
                            .foregroundColor(.secondary)

                        Text(entry.limitFormatted)
                            .font(.title)
                            .foregroundColor(.secondary)
                    }

                    Text("\(Int(entry.percentage))% utilizzato")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)

                    ProgressView(value: entry.percentage, total: 100)
                        .tint(entry.progressColor)
                        .frame(height: 10)
                        .padding(.top, 4)
                }
            }

            // Quick actions
            HStack(spacing: 12) {
                Link(destination: URL(string: "finapp://scan-receipt")!) {
                    HStack {
                        Image(systemName: "doc.text.viewfinder")
                        Text("Scansiona Scontrino")
                            .fontWeight(.medium)
                    }
                    .font(.body)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.blue)
                    .cornerRadius(10)
                }

                Link(destination: URL(string: "finapp://add-expense")!) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Aggiungi Manuale")
                            .fontWeight(.medium)
                    }
                    .font(.body)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.blue)
                    .cornerRadius(10)
                }
            }

            // Last updated
            HStack {
                Spacer()
                Text(formatLastUpdated(entry.lastUpdated))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .containerBackground(for: .widget) {
            Color(colorScheme == .dark ? .systemBackground : .white)
        }
    }
}

private func formatLastUpdated(_ date: Date) -> String {
    let now = Date()
    let diff = now.timeIntervalSince(date)
    let minutes = Int(diff / 60)
    let hours = minutes / 60

    if minutes < 1 {
        return "Aggiornato ora"
    } else if minutes < 60 {
        return "Aggiornato \(minutes) min fa"
    } else if hours < 24 {
        return "Aggiornato \(hours) ore fa"
    } else {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM HH:mm"
        formatter.locale = Locale(identifier: "it_IT")
        return "Agg. \(formatter.string(from: date))"
    }
}

@main
struct BudgetWidget: Widget {
    let kind: String = "BudgetWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            BudgetWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Budget Mensile")
        .description("Visualizza il budget mensile e aggiungi spese rapidamente")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

#Preview(as: .systemMedium) {
    BudgetWidget()
} timeline: {
    BudgetEntry(
        date: Date(),
        spent: 450.00,
        limit: 800.00,
        month: "Dicembre 2024",
        currency: "€",
        isDarkMode: false,
        lastUpdated: Date(),
        groupName: "Famiglia"
    )
}
