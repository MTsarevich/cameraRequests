import SwiftUI

struct LeadsListView: View {
    @State private var vm = LeadsListViewModel()
    @State private var presentedLead: Lead?
    @EnvironmentObject private var router: DeepLinkRouter

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    statusPicker
                    listContent
                }
            }
            .navigationTitle("Заявки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(Theme.brand)
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
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var listContent: some View {
        let leads = vm.filteredLeads()
        if leads.isEmpty {
            emptyState
        } else {
            List(leads) { lead in
                LeadRow(lead: lead)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                    .contentShape(Rectangle())
                    .onTapGesture { presentedLead = lead }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: "tray")
                .font(.system(size: 44))
                .foregroundStyle(Theme.textSecondary.opacity(0.5))
            Text(vm.searchText.isEmpty ? "Нет заявок" : "Ничего не найдено")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func startListening() {
        LeadsRepository.shared.startListening { leads in
            vm.ingest(leads)
            // Keep the home-screen badge in sync with unhandled (new) leads.
            let newCount = leads.filter { $0.status == .new }.count
            PushService.shared.setBadge(newCount)
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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                StatusBadge(status: lead.status)
                Spacer()
                if let createdAt = lead.createdAt {
                    Text(relative(createdAt))
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
            }

            Text(lead.name.isEmpty ? "Без имени" : lead.name)
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)

            if !lead.phone.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "phone.fill")
                        .font(.caption2)
                        .foregroundStyle(Theme.brand)
                    Text(PhoneFormatter.display(lead.phone))
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
            }

            if let message = lead.message, !message.isEmpty {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }

    private func relative(_ date: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.unitsStyle = .short
        return f.localizedString(for: date, relativeTo: Date())
    }
}
