import SwiftUI

struct LeadsListView: View {
    @State private var vm = LeadsListViewModel()
    @State private var presentedLead: Lead?
    @EnvironmentObject private var router: DeepLinkRouter

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                statusPicker
                Divider()
                listContent
            }
            .navigationTitle("Заявки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .searchable(text: $vm.searchText, prompt: "Поиск по заявке")
            .onAppear { startListening() }
            .onDisappear { LeadsRepository.shared.stop() }
            .sheet(item: $presentedLead) { lead in
                LeadDetailSheet(lead: lead)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .onChange(of: router.pendingLeadId) { _, newId in
                openIfPending(newId)
            }
            .onChange(of: vm.allLeads) { _, _ in
                // If a push arrived before the snapshot loaded, the lead wasn't in the list yet.
                // Re-attempt the deep link whenever the list updates.
                openIfPending(router.pendingLeadId)
            }
        }
    }

    private var statusPicker: some View {
        Picker("Статус", selection: $vm.selectedStatus) {
            ForEach(LeadStatus.allCases) { status in
                let count = vm.counts[status, default: 0]
                Text(count > 0 ? "\(status.localizedTitle) (\(count))" : status.localizedTitle)
                    .tag(status)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var listContent: some View {
        let leads = vm.filteredLeads()
        if leads.isEmpty {
            emptyState
        } else {
            List(leads) { lead in
                LeadRow(lead: lead)
                    .contentShape(Rectangle())
                    .onTapGesture { presentedLead = lead }
            }
            .listStyle(.plain)
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: "tray")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text(vm.searchText.isEmpty ? "Нет заявок" : "Ничего не найдено")
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func startListening() {
        LeadsRepository.shared.startListening { leads in
            vm.ingest(leads)
        }
    }

    private func openIfPending(_ leadId: String?) {
        guard let leadId else { return }
        if let lead = vm.allLeads.first(where: { $0.id == leadId }) {
            presentedLead = lead
            router.pendingLeadId = nil
        }
    }
}

private struct LeadRow: View {
    let lead: Lead

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 4) {
                Text(lead.name.isEmpty ? "Без имени" : lead.name)
                    .font(.body)
                    .fontWeight(.medium)
                if !lead.phone.isEmpty {
                    Text(PhoneFormatter.display(lead.phone))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if let message = lead.message, !message.isEmpty {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if let createdAt = lead.createdAt {
                Text(relative(createdAt))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }

    private var color: Color {
        switch lead.status {
        case .new: return .red
        case .inProgress: return .orange
        case .closed: return .gray
        }
    }

    private func relative(_ date: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.unitsStyle = .short
        return f.localizedString(for: date, relativeTo: Date())
    }
}
