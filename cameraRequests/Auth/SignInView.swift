import SwiftUI

struct SignInView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                brandMark

                card

                Spacer()
                Spacer()
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Brand mark

    private var brandMark: some View {
        VStack(spacing: 14) {
            Image(systemName: "video.fill")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 68, height: 68)
                .background(Theme.brand, in: RoundedRectangle(cornerRadius: 18))
                .shadow(color: Theme.brand.opacity(0.35), radius: 12, y: 6)

            VStack(spacing: 2) {
                Text("LinkUP")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Text("Заявки с сайта")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    // MARK: - Card

    private var card: some View {
        VStack(spacing: 14) {
            field {
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textContentType(.emailAddress)
            }

            field {
                SecureField("Пароль", text: $password)
                    .textContentType(.password)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button(action: submit) {
                HStack {
                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Войти").fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(canSubmit ? Theme.brand : Theme.brand.opacity(0.4),
                            in: RoundedRectangle(cornerRadius: Theme.controlRadius))
                .foregroundStyle(.white)
            }
            .disabled(!canSubmit)
            .padding(.top, 4)
        }
        .padding(20)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.06), radius: 18, y: 8)
    }

    private func field<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .font(.body)
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(Theme.background, in: RoundedRectangle(cornerRadius: Theme.controlRadius))
    }

    // MARK: - Logic

    private var canSubmit: Bool {
        !email.isEmpty && !password.isEmpty && !isLoading
    }

    private func submit() {
        errorMessage = nil
        isLoading = true
        Task {
            do {
                try await AuthService.shared.signIn(email: email, password: password)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
