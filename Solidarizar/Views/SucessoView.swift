import SwiftUI

struct SucessoView: View {
    let valor: String
    let ongNome: String
    let isRecorrente: Bool
    let onVoltarInicio: () -> Void
    
    @State private var animarCheck = false
    @State private var animarTexto = false
    
    // Paleta de Cores Oficial
    let pageBackground = Color(red: 0.07, green: 0.10, blue: 0.17) // #121A2C
    let greenMoney = Color(red: 0.06, green: 0.73, blue: 0.51)    // #10B981
    let brandViolet = Color(red: 0.55, green: 0.36, blue: 0.96)
    let brandMagenta = Color(red: 0.85, green: 0.27, blue: 0.94)

    var body: some View {
        ZStack {
            pageBackground.ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // --- ÍCONE DE SUCESSO ANIMADO ---
                ZStack {
                    Circle()
                        .fill(greenMoney.opacity(0.15))
                        .frame(width: 140, height: 140)
                        .scaleEffect(animarCheck ? 1.1 : 0.8)
                    
                    Circle()
                        .fill(greenMoney.opacity(0.2))
                        .frame(width: 110, height: 110)
                    
                    Circle()
                        .fill(greenMoney)
                        .frame(width: 80, height: 80)
                        .shadow(color: greenMoney.opacity(0.4), radius: 15)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(animarCheck ? 1 : 0.5)
                        .opacity(animarCheck ? 1 : 0)
                }
                
                // --- TEXTOS DE CONFIRMAÇÃO ---
                VStack(spacing: 12) {
                    Text("Doação Concluída!")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Obrigado! Seu apoio à **\(ongNome)** faz toda a diferença.")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .opacity(animarTexto ? 1 : 0)
                .offset(y: animarTexto ? 0 : 20)
                
                // --- CARD DO VALOR ---
                VStack(spacing: 4) {
                    Text("VALOR DOADO")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.gray)
                        .tracking(1)
                    
                    Text("R$ \(valor)")
                        .font(.system(size: 40, weight: .black))
                        .foregroundColor(greenMoney)
                }
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.03))
                .cornerRadius(16)
                .padding(.horizontal, 40)
                .opacity(animarTexto ? 1 : 0)
                
                if isRecorrente {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar.badge.clock")
                        Text("Doação Mensal Ativada")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(brandViolet)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(brandViolet.opacity(0.1))
                    .cornerRadius(20)
                }
                
                Spacer()
                
                // --- BOTÃO DE VOLTAR ---
                Button(action: onVoltarInicio) {
                    Text("VOLTAR PARA O INÍCIO")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(colors: [brandViolet, brandMagenta], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(28)
                        .shadow(color: brandViolet.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            // Sequência de animação
            withAnimation(.spring(response: 0.6, dampingFraction: 0.5, blendDuration: 0)) {
                animarCheck = true
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                animarTexto = true
            }
        }
    }
}
