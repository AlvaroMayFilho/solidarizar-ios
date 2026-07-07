import SwiftUI

struct NovaArrecadacaoView: View {
    let usuario: Usuario
    var onVoltar: () -> Void
    var onAvancarParaPix: (_ valor: Double, _ nome: String, _ cpf: String, _ renuncia: Bool) -> Void
    
    // Estados do Formulário
    @State private var valorDigitado: String = ""
    @State private var precisaRecibo: Bool = false
    @State private var nomeDoador: String = ""
    @State private var cpfDoador: String = ""
    @State private var renunciaComissao: Bool = false
    
    // Alertas
    @State private var mostrarAlerta = false
    @State private var mensagemAlerta = ""
    
    // Cores da paleta
    let darkBackground = Color(red: 0.05, green: 0.05, blue: 0.05)
    let cardBackground = Color(red: 0.11, green: 0.11, blue: 0.12)
    let purpleAction = Color(red: 0.55, green: 0.36, blue: 0.96)
    let orangeAction = Color(red: 0.96, green: 0.62, blue: 0.04)
    let textGray = Color.gray
    let textWhite = Color.white
    
    var body: some View {
        ZStack {
            darkBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // --- TOP BAR ---
                HStack {
                    Button(action: onVoltar) {
                        Image(systemName: "arrow.left")
                            .foregroundColor(textWhite)
                            .font(.system(size: 20, weight: .bold))
                            .padding()
                    }
                    VStack(alignment: .leading) {
                        Text("Nova Arrecadação")
                            .font(.headline)
                            .foregroundColor(textWhite)
                        Text("Captador: \(usuario.nome)")
                            .font(.caption)
                            .foregroundColor(textWhite.opacity(0.7))
                    }
                    Spacer()
                }
                .padding(.top, 10)
                .background(darkBackground)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // --- 1. VALOR DA DOAÇÃO ---
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Valor da Doação")
                                .font(.system(size: 14))
                                .foregroundColor(textGray)
                            
                            HStack {
                                Text("R$")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(textWhite)
                                
                                TextField("0,00", text: $valorDigitado)
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(textWhite)
                                    .keyboardType(.decimalPad)
                            }
                            .padding()
                            .background(cardBackground)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(purpleAction, lineWidth: 1))
                        }
                        
                        // --- 2. MÉTODO DE PAGAMENTO ---
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Forma de Pagamento")
                                .font(.system(size: 14))
                                .foregroundColor(textGray)
                            
                            HStack(spacing: 16) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(purpleAction.opacity(0.2))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: "qrcode")
                                        .foregroundColor(purpleAction)
                                }
                                
                                VStack(alignment: .leading) {
                                    Text("PIX (Instantâneo)")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(textWhite)
                                    Text("QR Code Dinâmico Asaas")
                                        .font(.system(size: 12))
                                        .foregroundColor(textGray)
                                }
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(purpleAction)
                            }
                            .padding(20)
                            .background(cardBackground)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(purpleAction.opacity(0.5), lineWidth: 1))
                        }
                        
                        // --- 3. RENÚNCIA DE COMISSÃO (Só Líder Primário) ---
                        if usuario.tipo == "PRIMARIO" {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Renúncia de Comissão")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(orangeAction)
                                    Text("Repassar 100% à causa.")
                                        .font(.system(size: 12))
                                        .foregroundColor(textGray)
                                }
                                Spacer()
                                Toggle("", isOn: $renunciaComissao)
                                    .labelsHidden()
                                    .tint(orangeAction)
                            }
                            .padding()
                            .background(cardBackground)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(orangeAction.opacity(0.5), lineWidth: 1))
                        }
                        
                        // --- 4. IDENTIFICAR DOADOR ---
                        VStack(alignment: .leading, spacing: 0) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Identificar Doador?")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(textWhite)
                                    Text("Para emissão de recibo")
                                        .font(.system(size: 12))
                                        .foregroundColor(textGray)
                                }
                                Spacer()
                                Toggle("", isOn: $precisaRecibo.animation())
                                    .labelsHidden()
                                    .tint(purpleAction)
                            }
                            .padding()
                            
                            if precisaRecibo {
                                Divider().background(textGray.opacity(0.2)).padding(.horizontal)
                                
                                VStack(spacing: 12) {
                                    CustomInput(placeholder: "Nome Completo", text: $nomeDoador)
                                    
                                    // AQUI: Aplicação da máscara de CPF (Ajustado para iOS 16)
                                    CustomInput(placeholder: "CPF (000.000.000-00)", text: $cpfDoador, keyboardType: .numberPad)
                                        .onChange(of: cpfDoador) { newValue in
                                            cpfDoador = formatCPF(newValue)
                                        }
                                }
                                .padding()
                            }
                        }
                        .background(cardBackground)
                        .cornerRadius(12)
                        
                        Spacer().frame(height: 20)
                        
                        // --- 5. BOTÃO AVANÇAR ---
                        Button(action: validarEAvancar) {
                            Text("AVANÇAR PARA PIX")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(LinearGradient(colors: [Color(red: 0.3, green: 0.11, blue: 0.58), Color(red: 0.85, green: 0.27, blue: 0.94)], startPoint: .leading, endPoint: .trailing))
                                .cornerRadius(28)
                        }
                        .padding(.bottom, 32)
                    }
                    .padding(24)
                }
            }
        }
        .alert("Aviso", isPresented: $mostrarAlerta) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(mensagemAlerta)
        }
    }
    
    // MARK: - FUNÇÕES DE TRATAMENTO
    
    func validarEAvancar() {
        // Trata o valor para aceitar tanto ponto quanto vírgula
        let valorLimpo = valorDigitado.replacingOccurrences(of: ",", with: ".")
        guard let valorDouble = Double(valorLimpo), valorDouble >= 20.0 else {
            mensagemAlerta = "O valor mínimo de doação é de R$ 20,00."
            mostrarAlerta = true
            return
        }
        
        var cpfParaEnvio = ""
        var nomeParaEnvio = "Doador Anônimo"
        
        if precisaRecibo {
            // Limpeza do CPF para enviar apenas números à API
            let cleanCPF = cpfDoador.filter { $0.isNumber }
            
            if nomeDoador.isEmpty || cleanCPF.count < 11 {
                mensagemAlerta = "Para recibo, preencha Nome e CPF válidos."
                mostrarAlerta = true
                return
            }
            
            cpfParaEnvio = cleanCPF
            nomeParaEnvio = nomeDoador
        }
        
        // Passa os dados tratados para a função de pagamento do SolidarizarApp
        onAvancarParaPix(valorDouble, nomeParaEnvio, cpfParaEnvio, renunciaComissao)
    }
    
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
}

// Componente auxiliar para os TextFields do recibo
struct CustomInput: View {
    var placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        TextField(placeholder, text: $text)
            .padding()
            .background(Color.black.opacity(0.3))
            .cornerRadius(8)
            .foregroundColor(.white)
            .keyboardType(keyboardType)
            .autocapitalization(.none)
            .disableAutocorrection(true)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.5), lineWidth: 1))
    }
}
