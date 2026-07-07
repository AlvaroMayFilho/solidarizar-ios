import SwiftUI

struct SolicitarSaqueView: View {
    var saldoDisponivel: Double
    var onVoltar: () -> Void
    var onConfirmarSaque: (Double) -> Void
    
    // Estados do Formulário
    @State private var valorSaque: String = ""
    @State private var mostrarModalAviso = false
    
    // Estados de Erro
    @State private var mostrarErro = false
    @State private var mensagemErro = ""
    
    // Cores da Paleta Android
    let pageBackground = Color(red: 0.06, green: 0.09, blue: 0.16) // #0F172A
    let cardBg = Color(red: 0.12, green: 0.16, blue: 0.23) // #1E293B
    let textGreen = Color(red: 0.06, green: 0.73, blue: 0.51) // #10B981
    let statusRed = Color(red: 0.94, green: 0.27, blue: 0.27) // #EF4444
    let buttonBlue = Color(red: 0.23, green: 0.51, blue: 0.96) // #3B82F6
    
    // Variável calculada em tempo real
    var valorNumerico: Double {
        Double(valorSaque.replacingOccurrences(of: ",", with: ".")) ?? 0.0
    }
    
    // LÓGICA DE UX: Verifica se o saque é permitido para habilitar o botão
    var saqueValido: Bool {
        valorNumerico >= 50.0 && valorNumerico <= saldoDisponivel
    }
    
    var body: some View {
        ZStack {
            pageBackground.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 24) {
                // --- TOP BAR ---
                HStack {
                    Button(action: onVoltar) {
                        Image(systemName: "arrow.left")
                            .foregroundColor(.white)
                            .font(.system(size: 20, weight: .bold))
                    }
                    Text("Solicitar Saque")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.leading, 8)
                    Spacer()
                }
                .padding(.top, 10)
                
                // --- CARD DE SALDO ---
                VStack(alignment: .leading, spacing: 8) {
                    Text("Seu Saldo Disponível")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    
                    Text("R$ \(String(format: "%.2f", saldoDisponivel))")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(textGreen)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(cardBg)
                .cornerRadius(16)
                
                // --- CAMPO DE VALOR ---
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quanto deseja sacar?")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    HStack {
                        Text("R$")
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                        
                        TextField("0,00", text: $valorSaque)
                            .keyboardType(.decimalPad)
                            .foregroundColor(.white)
                            .font(.system(size: 18))
                    }
                    .padding()
                    .background(cardBg)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(valorSaque.isEmpty ? Color.clear : (saqueValido ? buttonBlue : statusRed), lineWidth: 1)
                    )
                    
                    // --- MENSAGENS DE VALIDAÇÃO EM TEMPO REAL (NOVA UX) ---
                    if !valorSaque.isEmpty {
                        if valorNumerico < 50.0 {
                            Text("⚠️ O valor mínimo para saque é R$ 50,00")
                                .font(.system(size: 13))
                                .foregroundColor(statusRed)
                        } else if valorNumerico > saldoDisponivel {
                            Text("❌ Saldo insuficiente")
                                .font(.system(size: 13))
                                .foregroundColor(statusRed)
                        }
                    }
                }
                
                // --- FEEDBACK DINÂMICO DE TAXA ---
                if valorNumerico >= 100.0 && valorNumerico <= saldoDisponivel {
                    Text("Taxa de transferência: Grátis!")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(textGreen)
                } else if valorNumerico >= 50.0 && valorNumerico <= saldoDisponivel {
                    Text("Taxa de transferência: R$ 1,99 (PIX)")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // --- BOTÃO CONFIRMAR ---
                Button(action: validarSaque) {
                    Text("SOLICITAR SAQUE")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(saqueValido ? .white : .white.opacity(0.3))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(saqueValido ? buttonBlue : cardBg)
                        .cornerRadius(12)
                }
                .disabled(!saqueValido)
                .padding(.bottom, 16)
            }
            .padding(.horizontal, 24)
        }
        // MODAL DE AVISO DA TAXA
        .alert("Aviso de Taxa", isPresented: $mostrarModalAviso) {
            Button("SACAR COM TAXA", role: .destructive) {
                onConfirmarSaque(valorNumerico)
            }
            Button("VOLTAR E ACUMULAR", role: .cancel) { }
        } message: {
            Text("Seu saque terá um desconto de R$ 1,99 referente à taxa bancária de transferência.\n\nSabia que saques a partir de R$ 100,00 são totalmente isentos?\n\nDeseja sacar agora mesmo pagando a taxa ou voltar e acumular?")
        }
        // ALERTA DE ERRO
        .alert("Ops!", isPresented: $mostrarErro) {
            Button("Entendi", role: .cancel) { }
        } message: {
            Text(mensagemErro)
        }
    }
    
    // --- LÓGICA DE VALIDAÇÃO ---
    func validarSaque() {
        if valorNumerico > saldoDisponivel {
            mensagemErro = "Saldo insuficiente para este valor."
            mostrarErro = true
        } else if valorNumerico < 50.0 {
            mensagemErro = "O valor mínimo para saque é de R$ 50,00."
            mostrarErro = true
        } else if valorNumerico < 100.0 {
            mostrarModalAviso = true
        } else {
            onConfirmarSaque(valorNumerico)
        }
    }
}
