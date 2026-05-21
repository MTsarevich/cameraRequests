import SwiftUI

struct StatsView: View {
    let leads: [Lead]

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                periodCard(title: "Сегодня", count: createdSince(startOfToday))
                periodCard(title: "За 7 дней", count: createdSince(weekAgo))
                statusCard
            }
            .padding(16)
        }
        .background(Theme.background)
        .navigationTitle("Статистика")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Cards

    private func periodCard(title: String, count: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
            Text("\(count)")
                .font(.system(size: 42, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.brand)
            Text("заявок поступило")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Сейчас в работе")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
            ForEach(LeadStatus.allCases) { status in
                HStack {
                    StatusBadge(status: status)
                    Spacer()
                    Text("\(count(of: status))")
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }

    // MARK: - Computations

    private var startOfToday: Date {
        Calendar.current.startOfDay(for: Date())
    }

    private var weekAgo: Date {
        Date().addingTimeInterval(-7 * 24 * 3600)
    }

    private func createdSince(_ date: Date) -> Int {
        leads.filter { ($0.createdAt ?? .distantPast) >= date }.count
    }

    private func count(of status: LeadStatus) -> Int {
        leads.filter { $0.status == status }.count
    }
}
