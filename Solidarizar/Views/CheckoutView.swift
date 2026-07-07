import SwiftUI

struct CheckoutView: View {
    let ong: Ong
    let onVoltar: () -> Void
    let onConfirmarPagamento: (_ tipo: String, _ valor: String, _ recorrente: Bool, _ email: String, _ cpf: String) -> Void
    
    // --- ESTADOS ---
    @State private var valorSelecionado: String = "50"
    @State private var valorCustomizado: String = ""
    
    @State private var emailDoador: String = ""
    @State private var cpfDoador: String = ""
    
    @State private var metodoPagamento: String = "pix"
    
    // Dados Cartão
    @State private var numCartao: String = ""
    @State private var nomeTitular: String = ""
    @State private var validade: String = ""
    @State private var cvv: String = ""
    
    @State private var isRecorrente: Bool = false
    let diaCobranca = "10"
    
    // --- LÓGICA DE VALIDAÇÃO ---
    var valorFinal: String {
        return valorSelecionado == "custom" ? (valorCustomizado.isEmpty ? "0" : valorCustomizado) : valorSelecionado
    }
    
    var valorNumerico: Double {
        Double(valorFinal.replacingOccurrences(of: ",", with: ".")) ?? 0.0
    }
    
    var doacaoValida: Bool {
        // Valida se e-mail e CPF estão preenchidos e se o valor é >= R$ 20,00
        !emailDoador.isEmpty && !cpfDoador.isEmpty && valorNumerico >= 20.0
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.darkBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // --- TOP BAR ---
                HStack {
                    Button(action: onVoltar) {
                        Image(systemName: "arrow.left")
                            .foregroundColor(.white)
                            .font(.system(size: 20, weight: .bold))
                    }
                    Spacer()
                    Text("Finalizar Doação")
                        .foregroundColor(.white)
                        .font(.system(size: 18, weight: .bold))
                    Spacer()
                    Color.clear.frame(width: 24, height: 24)
                }
                .padding()
                .background(Color.darkBackground)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // 0. SEUS DADOS
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Seus Dados (Para o recibo)")
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .bold))
                            
                            InputCheckout(texto: $emailDoador, label: "Seu E-mail", icone: "envelope.fill", teclado: .emailAddress)
                            
                            // AQUI: Adicionado tratamento de máscara de CPF (Ajustado para iOS 16)
                            InputCheckout(texto: $cpfDoador, label: "Seu CPF (000.000.000-00)", icone: "person.text.rectangle", teclado: .numberPad)
                                .onChange(of: cpfDoador) { newValue in
                                    cpfDoador = formatCPF(newValue)
                                }
                        }
                        
                        // 1. QUANTO VOCÊ QUER DOAR?
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Qual valor você quer doar?")
                                .foregroundColor(.gray)
                                .font(.system(size: 14))
                            
                            HStack(spacing: 12) {
                                ForEach(["20", "50", "100"], id: \.self) { valor in
                                    ChipValor(texto: "R$ \(valor)", selecionado: valorSelecionado == valor) {
                                        valorSelecionado = valor
                                    }
                                }
                                ChipValor(texto: "Outro", selecionado: valorSelecionado == "custom") {
                                    valorSelecionado = "custom"
                                }
                            }
                            
                            if valorSelecionado == "custom" {
                                VStack(alignment: .leading, spacing: 6) {
                                    InputCheckout(texto: $valorCustomizado, label: "Digite o valor (R$)", icone: "dollarsign.circle", teclado: .decimalPad)
                                    
                                    // AVISO DE VALOR MÍNIMO (UX)
                                    if !valorCustomizado.isEmpty && valorNumerico < 20.0 {
                                        Text("⚠️ O valor mínimo para doação é R$ 20,00")
                                            .font(.system(size: 12))
                                            .foregroundColor(.red)
                                            .padding(.leading, 4)
                                    }
                                }
                                .padding(.top, 8)
                            }
                        }
                        
                        // 2. FORMA DE PAGAMENTO
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Como deseja pagar?")
                                .foregroundColor(.gray)
                                .font(.system(size: 14))
                            
                            HStack(spacing: 0) {
                                Button(action: {
                                    metodoPagamento = "pix"
                                    isRecorrente = false
                                }) {
                                    HStack {
                                        Image(systemName: "qrcode")
                                        Text("PIX")
                                    }
                                    .font(.system(size: 14, weight: .bold))
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .foregroundColor(metodoPagamento == "pix" ? .greenMoney : .gray)
                                    .background(metodoPagamento == "pix" ? Color.greenMoney.opacity(0.2) : Color.clear)
                                }
                                
                                Divider().background(Color.gray.opacity(0.3))
                                
                                Button(action: { metodoPagamento = "cartao" }) {
                                    HStack {
                                        Image(systemName: "creditcard.fill")
                                        Text("Cartão")
                                    }
                                    .font(.system(size: 14, weight: .bold))
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .foregroundColor(metodoPagamento == "cartao" ? Color(red: 0.23, green: 0.51, blue: 0.96) : .gray)
                                    .background(metodoPagamento == "cartao" ? Color(red: 0.23, green: 0.51, blue: 0.96).opacity(0.2) : Color.clear)
                                }
                            }
                            .frame(height: 50)
                            .background(Color.cardBackground)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                        }
                        
                        // 3. CONTEÚDO DINÂMICO
                        if metodoPagamento == "pix" {
                            VStack(spacing: 8) {
                                Text("Pagamento Instantâneo")
                                    .foregroundColor(.greenMoney)
                                    .font(.system(size: 16, weight: .bold))
                                Text("Geraremos um código Copia e Cola. O comprovante será enviado para seu e-mail (\(emailDoador.isEmpty ? "..." : emailDoador)).")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 13))
                                    .multilineTextAlignment(.center)
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity)
                            .background(Color.cardBackground)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.greenMoney.opacity(0.5), lineWidth: 1))
                            
                        } else {
                            VStack(alignment: .leading, spacing: 16) {
                                Toggle(isOn: $isRecorrente) {
                                    VStack(alignment: .leading) {
                                        Text("Doação Mensal (Recorrente)")
                                            .foregroundColor(.white)
                                            .font(.system(size: 14, weight: .bold))
                                        Text("Cobrar todo mês automaticamente")
                                            .foregroundColor(.gray)
                                            .font(.system(size: 12))
                                    }
                                }
                                .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.23, green: 0.51, blue: 0.96)))
                                .padding()
                                .background(Color.cardBackground)
                                .cornerRadius(12)
                                
                                if isRecorrente {
                                    Text("Dia da cobrança: Dia \(diaCobranca)")
                                        .foregroundColor(Color(red: 0.23, green: 0.51, blue: 0.96))
                                        .font(.system(size: 14))
                                }
                                
                                Text("Dados do Cartão")
                                    .foregroundColor(.white)
                                    .font(.system(size: 16, weight: .bold))
                                    .padding(.top, 8)
                                
                                InputCheckout(texto: $numCartao, label: "Número do Cartão", icone: "creditcard", teclado: .numberPad)
                                InputCheckout(texto: $nomeTitular, label: "Nome no Cartão", icone: "person", teclado: .default)
                                
                                HStack(spacing: 12) {
                                    InputCheckout(texto: $validade, label: "Validade", icone: "calendar", teclado: .numberPad)
                                    InputCheckout(texto: $cvv, label: "CVV", icone: "lock.fill", teclado: .numberPad)
                                }
                            }
                        }
                        
                        Spacer().frame(height: 120)
                    }
                    .padding(24)
                }
            }
            
            // --- BOTÃO CONFIRMAR ---
            VStack {
                Button(action: {
                    if doacaoValida {
                        // Limpa o CPF enviando apenas números para a função de pagamento
                        let cleanCPF = cpfDoador.filter { $0.isNumber }
                        onConfirmarPagamento(metodoPagamento, valorFinal, isRecorrente, emailDoador, cleanCPF)
                    }
                }) {
                    HStack {
                        Image(systemName: doacaoValida ? "lock.fill" : "exclamationmark.circle.fill")
                        Text("CONFIRMAR R$ \(valorFinal)")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor(doacaoValida ? .white : .white.opacity(0.3))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(doacaoValida ? Color.greenMoney : Color.gray.opacity(0.2))
                    .cornerRadius(12)
                }
                .disabled(!doacaoValida)
                .padding(16)
            }
            .background(Color.cardBackground.shadow(radius: 10))
        }
    }
    
    // MARK: - FUNÇÃO DE MÁSCARA CPF
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

// Subcomponente ChipValor
struct ChipValor: View {
    let texto: String
    let selecionado: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(texto)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(selecionado ? .black : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(selecionado ? Color.white : Color.cardBackground)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3), lineWidth: selecionado ? 0 : 1))
        }
    }
}

// Subcomponente Input
struct InputCheckout: View {
    @Binding var texto: String
    let label: String
    let icone: String
    let teclado: UIKeyboardType
    
    var body: some View {
        HStack {
            Image(systemName: icone)
                .foregroundColor(.gray)
                .frame(width: 20)
            
            TextField("", text: $texto, prompt: Text(label).foregroundColor(.gray))
                .foregroundColor(.white)
                .keyboardType(teclado)
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.3), lineWidth: 1))
    }
}
