import SwiftUI

public struct LoginView: View {
    @ObservedObject var appState: AppState

    @State private var appId: String = ""
    @State private var appSecret: String = ""
    @State private var emailOrUsername: String = ""
    @State private var password: String = ""
    @State private var showSecret: Bool = false

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.orange.opacity(0.8), Color.yellow],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)
                        .shadow(color: Color.orange.opacity(0.3), radius: 8, x: 0, y: 4)

                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.white)
                }

                Text("Deye Cloud Girişi")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Deye solar inverter verilerine erişmek için geliştirici ve hesap bilgilerinizi girin.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }

            // Input Fields Form
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("App ID")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    TextField("Deye Developer App ID", text: $appId)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("App Secret")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button(showSecret ? "Gizle" : "Göster") {
                            showSecret.toggle()
                        }
                        .buttonStyle(.link)
                        .font(.caption2)
                    }

                    if showSecret {
                        TextField("Deye Developer App Secret", text: $appSecret)
                            .textFieldStyle(.roundedBorder)
                    } else {
                        SecureField("Deye Developer App Secret", text: $appSecret)
                            .textFieldStyle(.roundedBorder)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("E-posta veya Kullanıcı Adı")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    TextField("Deye Cloud hesap e-postası", text: $emailOrUsername)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Şifre")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    SecureField("Deye Cloud hesap şifresi", text: $password)
                        .textFieldStyle(.roundedBorder)
                }
            }
            .frame(maxWidth: 380)

            if let error = appState.errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                .padding(10)
                .frame(maxWidth: 380, alignment: .leading)
                .background(Color.red.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Action Button
            Button {
                let creds = Credentials(
                    appId: appId,
                    appSecret: appSecret,
                    emailOrUsername: emailOrUsername,
                    password: password
                )
                appState.credentials = creds
                Task {
                    await appState.login()
                }
            } label: {
                HStack {
                    if appState.isLoading {
                        ProgressView()
                            .controlSize(.small)
                            .padding(.trailing, 4)
                    }
                    Text(appState.isLoading ? "Bağlanıyor..." : "Bağlan ve Giriş Yap")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: 380)
                .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!isFormValid || appState.isLoading)

            // Security Note
            HStack(spacing: 6) {
                Image(systemName: "lock.shield.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Kimlik bilgileriniz cihazınızda uygulamanın korumalı yerel alanında (App Sandbox) saklanır.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(32)
        .frame(minWidth: 460, minHeight: 520)
        .onAppear {
            appId = appState.credentials.appId
            appSecret = appState.credentials.appSecret
            emailOrUsername = appState.credentials.emailOrUsername
            password = appState.credentials.password
        }
    }

    private var isFormValid: Bool {
        !appId.trimmingCharacters(in: .whitespaces).isEmpty &&
        !appSecret.trimmingCharacters(in: .whitespaces).isEmpty &&
        !emailOrUsername.trimmingCharacters(in: .whitespaces).isEmpty &&
        !password.isEmpty
    }
}
