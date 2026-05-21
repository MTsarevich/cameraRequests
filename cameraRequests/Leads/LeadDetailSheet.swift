import SwiftUI

struct LeadDetailSheet: View {
    let lead: Lead

    @Environment(\.dismiss) private var dismiss
    @State private var pendingAction: PendingAction?
    @State private var errorMessage: String?
    @State private var isWorking = false

    private enum PendingAction: Identifiable {
        case close, reopen
        var id: String {
            switch self {
            case .close: return "close"
            case .reopen: return "reopen"
            }
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if !lead.name.isEmpty {
                        infoRow("Имя", lead.name)
                    }
                    if !lead.phone.isEmpty {
                        infoRow("Телефон", PhoneFormatter.display(lead.phone))
                    }
                    if let email = lead.email, !email.isEmpty {
                        infoRow("Email", email)
                    }
                    if let message = lead.message, !message.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Комментарий").font(.caption).foregroundStyle(.secondary)
                            Text(message)
                        }
                    }
                    infoRow("Источник", lead.source)
                    if let createdAt = lead.createdAt {
                        infoRow("Создана", formatted(createdAt))
                    }
                    HStack {
                        Text("Статус").foregroundStyle(.secondary)
                        Spacer()
                        StatusBadge(status: lead.status)
                    }
                }

                if hasContact {
                    Section("Контакт") {
                        if !lead.phone.isEmpty {
                            Button {
                                ContactActions.call(phone: lead.phone)
                            } label: {
                                Label("Позвонить", systemImage: "phone.fill")
                            }
                            Button {
                                ContactActions.openTelegram(phone: lead.phone)
                            } label: {
                                Label("Telegram", systemImage: "paperplane.fill")
                            }
                            Button {
                                ContactActions.copy(lead.phone)
                            } label: {
                                Label("Скопировать телефон", systemImage: "doc.on.doc")
                            }
                        }
                        if let email = lead.email, !email.isEmpty {
                            Button {
                                ContactActions.openEmail(email)
                            } label: {
                                Label("Написать на email", systemImage: "envelope.fill")
                            }
                            Button {
                                ContactActions.copy(email)
                            } label: {
                                Label("Скопировать email", systemImage: "doc.on.doc")
                            }
                        }
                    }
                }

                Section("Действия") {
                    if lead.status == .new {
                        Button {
                            perform(.inProgress)
                        } label: {
                            Label("В работу", systemImage: "play.fill")
                        }
                    }
                    if lead.status != .new {
                        Button {
                            pendingAction = .reopen
                        } label: {
                            Label("Вернуть в Новые", systemImage: "arrow.uturn.backward")
                        }
                    }
                    if lead.status != .closed {
                        Button(role: .destructive) {
                            pendingAction = .close
                        } label: {
                            Label("Закрыть заявку", systemImage: "checkmark.circle.fill")
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("Заявка")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") { dismiss() }
                }
            }
            .overlay { if isWorking { ProgressView().controlSize(.large) } }
            .confirmationDialog(
                confirmationTitle,
                isPresented: dialogBinding,
                titleVisibility: .visible,
                actions: {
                    Button(confirmationActionTitle, role: pendingAction == .close ? .destructive : nil) {
                        if let a = pendingAction {
                            perform(a == .close ? .closed : .new)
                        }
                    }
                    Button("Отмена", role: .cancel) { pendingAction = nil }
                },
                message: {
                    Text(confirmationMessage)
                },
            )
            .alert("Не удалось обновить", isPresented: errorBinding) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    // MARK: - Subviews

    private var hasContact: Bool {
        !lead.phone.isEmpty || (lead.email?.isEmpty == false)
    }

    private func infoRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(title).foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
        }
    }

    // MARK: - Confirmation strings

    private var confirmationTitle: String {
        switch pendingAction {
        case .close: return "Закрыть заявку?"
        case .reopen: return "Вернуть заявку в Новые?"
        case .none: return ""
        }
    }

    private var confirmationMessage: String {
        switch pendingAction {
        case .close: return "Заявка переедет в раздел «Закрытые». Это можно отменить вручную."
        case .reopen: return "Заявка снова окажется в разделе «Новые» и начнёт получать напоминания."
        case .none: return ""
        }
    }

    private var confirmationActionTitle: String {
        switch pendingAction {
        case .close: return "Закрыть"
        case .reopen: return "Вернуть"
        case .none: return ""
        }
    }

    private var dialogBinding: Binding<Bool> {
        Binding(get: { pendingAction != nil }, set: { if !$0 { pendingAction = nil } })
    }

    private var errorBinding: Binding<Bool> {
        Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
    }

    // MARK: - Mutation

    private func perform(_ status: LeadStatus) {
        guard let id = lead.id else { return }
        pendingAction = nil
        isWorking = true
        Task {
            do {
                try await LeadsRepository.shared.updateStatus(leadId: id, status: status)
                isWorking = false
                dismiss()
            } catch {
                isWorking = false
                errorMessage = error.localizedDescription
            }
        }
    }

    private func formatted(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.dateStyle = .short
        f.timeStyle = .short
        return f.string(from: date)
    }
}
