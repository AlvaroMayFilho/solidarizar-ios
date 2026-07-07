import SwiftUI
import FirebaseAuth

struct LoginView: View {
    // ==========================================
    // CORES OFICIAIS DO APP
    // ==========================================
    let deepCharcoalBackground = Color(red: 0.05, green: 0.05, blue: 0.06)
    let deepVioletBackgroundTop = Color(red: 0.09, green: 0.05, blue: 0.15)
    let appMagenta = Color(red: 0.88, green: 0.10, blue: 0.61)
    let appPurple = Color(red: 0.63, green: 0.08, blue: 0.86)
    let secondaryTextGray = Color(red: 0.68, green: 0.68, blue: 0.72)
    let brandOrange = Color(red: 0.96, green: 0.62, blue: 0.04)
    
    @State private var email = ""
    @State private var senha = ""
    @State private var loading = false
    @State private var alertMessage = ""
    @State private var showAlert = false
    @State private var animateUI = false
    
    var onLoginSuccess: () -> Void
    var onVoltar: () -> Void
    var onIrParaCadastro: () -> Void
    
    var body: some View {
        ZStack {
            // 1. FUNDO E AMBIENT GLOW
            LinearGradient(colors: [deepVioletBackgroundTop, deepCharcoalBackground], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            Circle()
                .fill(appPurple.opacity(0.12))
                .blur(radius: 80)
                .frame(width: 300, height: 300)
                .offset(x: 150, y: -200)
            
            VStack(spacing: 0) {
                // ==========================================
                // 2. HEADER (Botão Voltar)
                // ==========================================
                HStack {
                    Button(action: {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        onVoltar()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.05))
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 10)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        
                        // ==========================================
                        // 3. LOGO E TÍTULOS
                        // ==========================================
                        Image("logo_oficial")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .shadow(color: Color.black.opacity(0.5), radius: 10, x: 0, y: 5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                            .padding(.top, 20)
                        
                        VStack(spacing: 8) {
                            Text("Bem-vindo de volta")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Acesso Administrativo")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(secondaryTextGray)
                        }
                        
                        // ==========================================
                        // 4. FORMULÁRIO (Glassmorphism)
                        // ==========================================
                        VStack(spacing: 20) {
                            CustomLoginTextField(text: $email, label: "E-mail", icon: "envelope.fill", keyboardType: .emailAddress)
                            
                            CustomLoginTextField(text: $senha, label: "Senha", icon: "lock.fill", isSecure: true)
                            
                            // Botão Acessar
                            Button(action: realizarLogin) {
                                ZStack {
                                    LinearGradient(colors: [appMagenta, appPurple], startPoint: .leading, endPoint: .trailing)
                                    
                                    if loading {
                                        ProgressView().tint(.white)
                                    } else {
                                        Text("Acessar sistema")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .shadow(color: appPurple.opacity(0.3), radius: 10, x: 0, y: 5)
                            }
                            .disabled(loading)
                            .padding(.top, 10)
                            // Omitir o .buttonStyle se você já colocou ele globalmente no app, senão use o que deixei no final do arquivo
                            .buttonStyle(LoginScaleButtonStyle())
                        }
                        .padding(24)
                        .background(Color.white.opacity(0.03))
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                    .offset(y: animateUI ? 0 : 20)
                    .opacity(animateUI ? 1.0 : 0.0)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                animateUI = true
            }
        }
        .alert("Login", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // --- LÓGICA ATUALIZADA PARA CUSTOM TOKEN ---
    func realizarLogin() {
        if email.isEmpty || senha.isEmpty {
            alertMessage = "Preencha todos os campos!"
            showAlert = true
            return
        }
        
        loading = true
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        Task {
            do {
                let request = LoginApiRequest(email: email.trimmingCharacters(in: .whitespaces), senha: senha)
                let resposta = try await ApiService.shared.loginApp(request: request)
                
                await MainActor.run {
                    if resposta.sucesso, let rawToken = resposta.token {
                        
                        // 1. LIMPEZA BRUTAL DA STRING
                        let tokenLimpo = rawToken
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                            .replacingOccurrences(of: "\"", with: "")
                        
                        // 2. IMPRIME O TOKEN NO XCODE PARA INSPECIONAR
                        print("\n🔑 === TOKEN RECEBIDO DO PYTHON === 🔑")
                        print(tokenLimpo)
                        print("======================================\n")
                        
                        // 3. TENTA LOGAR COM O TOKEN ESTERILIZADO
                        Auth.auth().signIn(withCustomToken: tokenLimpo) { result, error in
                            self.loading = false
                            if let error = error {
                                self.alertMessage = "Erro no Firebase: \(error.localizedDescription)"
                                self.showAlert = true
                            } else {
                                self.onLoginSuccess()
                            }
                        }
                    } else {
                        self.loading = false
                        self.alertMessage = resposta.mensagem ?? "Credenciais inválidas."
                        self.showAlert = true
                    }
                }
            } catch {
                await MainActor.run {
                    self.loading = false
                    self.alertMessage = "Erro ao conectar: \(error.localizedDescription)"
                    self.showAlert = true
                }
            }
        }
    }
}

// ==========================================
// COMPONENTE DE CAMPO DE TEXTO APRIMORADO
// ==========================================
struct CustomLoginTextField: View {
    @Binding var text: String
    let label: String
    let icon: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(red: 0.68, green: 0.68, blue: 0.72))
            
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(Color.white.opacity(0.5))
                    .frame(width: 20)
                
                if isSecure {
                    SecureField("", text: $text)
                        .foregroundColor(.white)
                        .accentColor(Color(red: 0.88, green: 0.10, blue: 0.61)) // Cursor cor do app
                } else {
                    TextField("", text: $text)
                        .foregroundColor(.white)
                        .keyboardType(keyboardType)
                        .autocapitalization(.none)
                        .accentColor(Color(red: 0.88, green: 0.10, blue: 0.61)) // Cursor cor do app
                }
            }
            .padding()
            // Fundo escuro sutil para o input dentro do card
            .background(Color.black.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
}

// Nota: Se você já tiver o ScaleButtonStyle do arquivo anterior,
// pode apagar este para não dar erro de duplicidade.
struct LoginScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}
