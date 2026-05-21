import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var vm = SettingsViewModel()

    var body: some View {
        Form {
            if vm.isLoading {
                ProgressView()
            } else {
                notificationsSection
                quietHoursSection
                accountSection
                versionFooter
            }
        }
        .navigationTitle("Настройки")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let uid = AuthService.shared.uid {
                vm.start(uid: uid)
            }
        }
        .onDisappear { vm.stop() }
        .onChange(of: vm.settings) { _, _ in
            if let uid = AuthService.shared.uid {
                vm.scheduleSave(uid: uid)
            }
        }
        .alert("Не удалось сохранить", isPresented: errorBinding) {
            Button("OK") { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(get: { vm.errorMessage != nil }, set: { if !$0 { vm.errorMessage = nil } })
    }

    // MARK: - Sections

    private var notificationsSection: some View {
        Section("Уведомления") {
            Toggle("Новые заявки", isOn: $vm.settings.newLeadEnabled)
            Toggle("Напоминания о необработанных", isOn: $vm.settings.remindersEnabled)
            Toggle("Звук", isOn: $vm.settings.soundEnabled)
        }
    }

    private var quietHoursSection: some View {
        Section("Тихие часы") {
            Toggle("Включены", isOn: $vm.settings.quietHoursEnabled)

            if vm.settings.quietHoursEnabled {
                hourPicker(title: "Начало", hour: $vm.settings.quietStartHour)
                hourPicker(title: "Конец", hour: $vm.settings.quietEndHour)

                Picker("Часовой пояс", selection: $vm.settings.timezone) {
                    ForEach(NotificationSettings.supportedTimezones, id: \.self) { tz in
                        Text(tz).tag(tz)
                    }
                }
            }
        }
    }

    private func hourPicker(title: String, hour: Binding<Int>) -> some View {
        Picker(title, selection: hour) {
            ForEach(0..<24, id: \.self) { h in
                Text(String(format: "%02d:00", h)).tag(h)
            }
        }
    }

    private var accountSection: some View {
        Section("Аккаунт") {
            if let email = AuthService.shared.userEmail {
                HStack {
                    Text("Email")
                    Spacer()
                    Text(email).foregroundStyle(.secondary)
                }
            }
            Button(role: .destructive) {
                signOut()
            } label: {
                Text("Выйти")
            }
        }
    }

    private var versionFooter: some View {
        Section {
            EmptyView()
        } footer: {
            HStack {
                Spacer()
                Text(versionString)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
    }

    private var versionString: String {
        let info = Bundle.main.infoDictionary
        let version = (info?["CFBundleShortVersionString"] as? String) ?? "?"
        let build = (info?["CFBundleVersion"] as? String) ?? "?"
        return "Версия \(version) (\(build))"
    }

    private func signOut() {
        Task {
            await PushService.shared.unregisterCurrentToken()
            do { try AuthService.shared.signOut() } catch {
                vm.errorMessage = error.localizedDescription
            }
        }
    }
}
