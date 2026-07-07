import SwiftUI
import UIKit
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

struct CadastroView: View {
    var onVoltar: () -> Void
    var onCadastroSucesso: () -> Void
    
    // --- CAMPOS DO FORMULÁRIO ---
    @State private var nome = ""
    @State private var email = ""
    @State private var senha = ""
    @State private var confirmarSenha = "" // <-- NOVO: Confirmar senha para doador
    @State private var cpf = ""
    @State private var telefone = ""
    @State private var dataNascimento = ""
    @State private var cep = ""
    @State private var rua = ""
    @State private var numero = ""
    @State private var bairro = ""
    @State private var codigoConvite = ""
    
    // --- CONTROLE DE FLUXO ---
    @State private var isCaptador = false // <-- Controla se é usuário comum ou captador
    @State private var carregando = false
    @State private var mostrarAlerta = false
    @State private var mensagemAlerta = ""
    
    // ==========================================
    // CORES OFICIAIS DO APP (Dark Premium)
    // ==========================================
    let deepCharcoalBackground = Color(red: 0.05, green: 0.05, blue: 0.06)
    let deepVioletBackgroundTop = Color(red: 0.09, green: 0.05, blue: 0.15)
    let appMagenta = Color(red: 0.88, green: 0.10, blue: 0.61)
    let appPurple = Color(red: 0.63, green: 0.08, blue: 0.86)
    let secondaryTextGray = Color(red: 0.68, green: 0.68, blue: 0.72)
    let brandOrange = Color(red: 0.96, green: 0.62, blue: 0.04)

    var body: some View {
        ZStack {
            // Fundo escuro com gradiente
            LinearGradient(colors: [deepVioletBackgroundTop, deepCharcoalBackground], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            // Glow sutil no fundo
            Circle()
                .fill(appPurple.opacity(0.1))
                .blur(radius: 100)
                .frame(width: 300, height: 300)
                .offset(x: -150, y: -200)
            
            VStack(spacing: 0) {
                // ==========================================
                // 1. HEADER (Botão Voltar)
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
                    
                    Text("Criar Conta")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.leading, 8)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 10)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // ==========================================
                        // 2. TEXTO DE BOAS-VINDAS
                        // ==========================================
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Junte-se a nós!")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(
                                    LinearGradient(colors: [appMagenta, appPurple], startPoint: .leading, endPoint: .trailing)
                                )
                            
                            Text("Complete seus dados para acessar a plataforma.")
                                .font(.system(size: 15))
                                .foregroundColor(secondaryTextGray)
                        }
                        .padding(.top, 20)
                        
                        // ==========================================
                        // 3. TIPO DE CONTA (O CHECKBOX)
                        // ==========================================
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                isCaptador.toggle()
                            }
                            let impact = UISelectionFeedbackGenerator()
                            impact.selectionChanged()
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: isCaptador ? "checkmark.square.fill" : "square")
                                    .font(.system(size: 22))
                                    .foregroundColor(isCaptador ? brandOrange : secondaryTextGray)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Sou um captador parceiro")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.white)
                                    Text("Tenho um código de convite de uma ONG.")
                                        .font(.system(size: 13))
                                        .foregroundColor(secondaryTextGray)
                                        .multilineTextAlignment(.leading)
                                }
                                Spacer()
                            }
                            .padding()
                            .background(isCaptador ? brandOrange.opacity(0.1) : Color.white.opacity(0.03))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(isCaptador ? brandOrange.opacity(0.5) : Color.white.opacity(0.08), lineWidth: 1)
                            )
                        }
                        
                        // ==========================================
                        // CÓDIGO DE CONVITE (Aparece apenas se for captador)
                        // ==========================================
                        if isCaptador {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "ticket.fill")
                                        .foregroundColor(brandOrange)
                                    Text("CÓDIGO DE CONVITE")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(brandOrange)
                                        .tracking(1)
                                }
                                
                                TextField("", text: $codigoConvite, prompt: Text("Ex: AB12C").foregroundColor(secondaryTextGray.opacity(0.5)))
                                    .foregroundColor(.white)
                                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                                    .multilineTextAlignment(.center)
                                    .padding()
                                    // Fundo escuro sutil para manter o padrão glassmorphism
                                    .background(Color.black.opacity(0.2))
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(brandOrange.opacity(0.5), lineWidth: 1))
                                    .onChange(of: codigoConvite) { newValue in
                                        codigoConvite = newValue.uppercased()
                                    }
                            }
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        
                        // ==========================================
                        // 4. DADOS PESSOAIS
                        // ==========================================
                        VStack(alignment: .leading, spacing: 16) {
                            Text("DADOS PESSOAIS")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(secondaryTextGray)
                                .tracking(1)
                            
                            VStack(spacing: 12) {
                                CampoTextoModerno(icon: "person.fill", placeholder: "Nome Completo", text: $nome)
                                
                                if isCaptador {
                                    CampoTextoModerno(icon: "person.text.rectangle.fill", placeholder: "CPF (000.000.000-00)", text: $cpf, keyboardType: .numberPad)
                                        .onChange(of: cpf) { newValue in cpf = formatCPF(newValue) }
                                }
                                
                                CampoTextoModerno(icon: "calendar", placeholder: "Nascimento (AAAA-MM-DD)", text: $dataNascimento, keyboardType: .numberPad)
                                    .onChange(of: dataNascimento) { newValue in dataNascimento = formatData(newValue) }
                                
                                if isCaptador {
                                    CampoTextoModerno(icon: "phone.fill", placeholder: "WhatsApp (00) 00000-0000", text: $telefone, keyboardType: .phonePad)
                                        .onChange(of: telefone) { newValue in telefone = formatTelefone(newValue) }
                                }
                                
                                CampoTextoModerno(icon: "envelope.fill", placeholder: "E-mail", text: $email, keyboardType: .emailAddress)
                                
                                CampoTextoModerno(icon: "lock.fill", placeholder: "Senha", text: $senha, isPassword: true)
                                
                                if !isCaptador {
                                    CampoTextoModerno(icon: "lock.fill", placeholder: "Confirmar Senha", text: $confirmarSenha, isPassword: true)
                                }
                            }
                        }
                        
                        // ==========================================
                        // 5. ENDEREÇO (Aparece apenas se for captador)
                        // ==========================================
                        if isCaptador {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("ENDEREÇO RESIDENCIAL")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(secondaryTextGray)
                                    .tracking(1)
                                
                                VStack(spacing: 12) {
                                    CampoTextoModerno(icon: "map.fill", placeholder: "CEP (00000-000)", text: $cep, keyboardType: .numberPad)
                                        .onChange(of: cep) { newValue in cep = formatCEP(newValue) }
                                    
                                    CampoTextoModerno(icon: "mappin.and.ellipse", placeholder: "Rua / Avenida", text: $rua)
                                    HStack(spacing: 12) {
                                        CampoTextoModerno(icon: "number", placeholder: "Nº", text: $numero)
                                            .frame(width: 100)
                                        CampoTextoModerno(icon: "building.2.fill", placeholder: "Bairro", text: $bairro)
                                    }
                                }
                            }
                        }
                        
                        // ==========================================
                        // 6. BOTÃO FINALIZAR
                        // ==========================================
                        Button(action: realizarCadastro) {
                            ZStack {
                                LinearGradient(colors: [appMagenta, appPurple], startPoint: .leading, endPoint: .trailing)
                                
                                if carregando {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("FINALIZAR CADASTRO")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                        .tracking(1)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .shadow(color: appPurple.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .disabled(carregando)
                        .padding(.top, 10)
                        .padding(.bottom, 40)
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
        .alert("Atenção", isPresented: $mostrarAlerta) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(mensagemAlerta)
        }
    }
    
    // MARK: - LÓGICA DE TRATAMENTO E CADASTRO
    
    func realizarCadastro() {
        // Validações separadas para Captador e Doador
        if isCaptador {
            if nome.isEmpty || email.isEmpty || senha.isEmpty || cpf.isEmpty || dataNascimento.isEmpty || cep.isEmpty {
                mensagemAlerta = "Preencha todos os campos obrigatórios!"
                mostrarAlerta = true
                return
            }
            if codigoConvite.isEmpty {
                mensagemAlerta = "Informe o Código de Convite da ONG para se cadastrar como captador."
                mostrarAlerta = true
                return
            }
        } else {
            if nome.isEmpty || email.isEmpty || senha.isEmpty || confirmarSenha.isEmpty || dataNascimento.isEmpty {
                mensagemAlerta = "Preencha todos os campos obrigatórios!"
                mostrarAlerta = true
                return
            }
            if senha != confirmarSenha {
                mensagemAlerta = "As senhas não coincidem!"
                mostrarAlerta = true
                return
            }
        }
        
        carregando = true
        
        // Payload base que serve para ambos
        var payload: [String: Any] = [
            "nome": nome,
            "email": email.lowercased().trimmingCharacters(in: .whitespaces),
            "senha": senha,
            "data_nascimento": dataNascimento
        ]
        
        // Adiciona campos extra se for captador
        if isCaptador {
            let cleanCPF = cpf.filter { $0.isNumber }
            let cleanCEP = cep.filter { $0.isNumber }
            let cleanTelefone = telefone.filter { $0.isNumber }
            
            payload["cpf"] = cleanCPF
            payload["telefone"] = cleanTelefone
            payload["cep"] = cleanCEP
            payload["rua"] = rua
            payload["numero"] = numero
            payload["bairro"] = bairro
            payload["codigo_convite"] = codigoConvite.uppercased().trimmingCharacters(in: .whitespaces)
        }
        
        Task {
            // --- VALIDAÇÃO: Verifica se o e-mail já existe no Firebase Auth ---
            do {
                let methods = try await Auth.auth().fetchSignInMethods(forEmail: email.trimmingCharacters(in: .whitespaces))
                if !methods.isEmpty {
                    DispatchQueue.main.async {
                        self.carregando = false
                        self.mensagemAlerta = "Este e-mail já está cadastrado em nossa base!"
                        self.mostrarAlerta = true
                    }
                    return
                }
            } catch {
                // Se o Firebase falhar na checagem por algum motivo, ignoramos e deixamos a API decidir
            }
            
            do {
                // ROTEAMENTO DINÂMICO DE API:
                let endpointStr = isCaptador ? "https://www.solidarizar.com.br/api/cadastro_secundario" : "https://www.solidarizar.com.br/api/cadastro_usuario"
                
                guard let url = URL(string: endpointStr) else { return }
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try JSONSerialization.data(withJSONObject: payload)
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 201 || httpResponse.statusCode == 200 {
                        DispatchQueue.main.async {
                            self.carregando = false
                            let impact = UINotificationFeedbackGenerator()
                            impact.notificationOccurred(.success)
                            self.onCadastroSucesso()
                        }
                    } else {
                        let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                        let erroServidor = json?["error"] as? String ?? "Erro \(httpResponse.statusCode)"
                        DispatchQueue.main.async {
                            self.carregando = false
                            self.mensagemAlerta = erroServidor
                            self.mostrarAlerta = true
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.carregando = false
                    self.mensagemAlerta = "Falha de conexão: \(error.localizedDescription)"
                    self.mostrarAlerta = true
                }
            }
        }
    }
    
    // MARK: - FUNÇÕES DE MÁSCARA
    
    private func formatCPF(_ value: String) -> String {
        let clean = value.filter { $0.isNumber }
        var result = ""
        let chars = Array(clean.prefix(11))
        for (i, c) in chars.enumerated() {
            if i == 3 || i == 6 { result.append(".") }
            if i == 9 { result.append("-") }
            result.append(c)
        }
        return result
    }
    
    private func formatTelefone(_ value: String) -> String {
        let clean = value.filter { $0.isNumber }
        var result = ""
        let chars = Array(clean.prefix(11))
        for (i, c) in chars.enumerated() {
            if i == 0 { result.append("(") }
            if i == 2 { result.append(") ") }
            if i == 7 && chars.count == 11 { result.append("-") }
            if i == 6 && chars.count <= 10 { result.append("-") }
            result.append(c)
        }
        return result
    }
    
    private func formatData(_ value: String) -> String {
        let clean = value.filter { $0.isNumber }
        var result = ""
        let chars = Array(clean.prefix(8))
        for (i, c) in chars.enumerated() {
            if i == 4 || i == 6 { result.append("-") }
            result.append(c)
        }
        return result
    }
    
    private func formatCEP(_ value: String) -> String {
        let clean = value.filter { $0.isNumber }
        var result = ""
        let chars = Array(clean.prefix(8))
        for (i, c) in chars.enumerated() {
            if i == 5 { result.append("-") }
            result.append(c)
        }
        return result
    }
}

// --- SUB-COMPONENTE: CAMPO DE TEXTO PREMIUM ---
struct CampoTextoModerno: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var isPassword: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color.white.opacity(0.5))
                .font(.system(size: 16))
                .frame(width: 20)
            
            if isPassword {
                SecureField("", text: $text)
                    .foregroundColor(.white)
                    .accentColor(Color(red: 0.88, green: 0.10, blue: 0.61))
                    .placeholder(when: text.isEmpty) {
                        Text(placeholder).foregroundColor(Color(red: 0.68, green: 0.68, blue: 0.72).opacity(0.7))
                    }
            } else {
                TextField("", text: $text)
                    .foregroundColor(.white)
                    .accentColor(Color(red: 0.88, green: 0.10, blue: 0.61))
                    .placeholder(when: text.isEmpty) {
                        Text(placeholder).foregroundColor(Color(red: 0.68, green: 0.68, blue: 0.72).opacity(0.7))
                    }
                    .keyboardType(keyboardType)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
        }
        .padding()
        // Fundo escuro sutil (Black opacity) para combinar com o novo visual
        .background(Color.black.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// Extensão para ajudar no placeholder do iOS antigo
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {

        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}
