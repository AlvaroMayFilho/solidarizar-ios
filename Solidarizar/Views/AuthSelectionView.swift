import SwiftUI

struct AuthSelectionView: View {
    // Ações para o Roteador
    var onVoltar: () -> Void
    var onIrParaLogin: () -> Void
    var onIrParaCadastro: () -> Void
    
    // ==========================================
    // CORES OFICIAIS DO APP
    // ==========================================
    let deepCharcoalBackground = Color(red: 0.05, green: 0.05, blue: 0.06)
    let deepVioletBackgroundTop = Color(red: 0.09, green: 0.05, blue: 0.15)
    let appMagenta = Color(red: 0.88, green: 0.10, blue: 0.61)
    let appPurple = Color(red: 0.63, green: 0.08, blue: 0.86)
    let secondaryTextGray = Color(red: 0.68, green: 0.68, blue: 0.72)
    
    @State private var animateUI: Bool = false

    var body: some View {
        ZStack {
            // Fundo escuro com gradiente
            LinearGradient(colors: [deepVioletBackgroundTop, deepCharcoalBackground], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            // Glow sutil no topo para dar destaque à logo
            Circle()
                .fill(appPurple.opacity(0.12))
                .blur(radius: 80)
                .frame(width: 250, height: 250)
                .offset(y: -300)
            
            VStack(spacing: 0) {
                
                // ==========================================
                // 1. HEADER (Botão Voltar e Logo)
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
                
                Spacer().frame(height: 20)
                
                // Logo igual à Welcome para manter consistência
                Image("logo_oficial")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 75, height: 75)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: Color.black.opacity(0.5), radius: 10, x: 0, y: 5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .offset(y: animateUI ? 0 : 15)
                    .opacity(animateUI ? 1.0 : 0.0)
                
                Spacer().frame(height: 30)
                
                // ==========================================
                // 2. TEXTOS PRINCIPAIS
                // ==========================================
                Text("Acesse sua jornada\nsolidária")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .padding(.bottom, 12)
                    .offset(y: animateUI ? 0 : 15)
                    .opacity(animateUI ? 1.0 : 0.0)
                
                Text("Entre para acompanhar suas ações ou crie\numa conta para começar a doar.")
                    .font(.system(size: 15))
                    .foregroundColor(secondaryTextGray)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 30)
                    .padding(.bottom, 40)
                    .offset(y: animateUI ? 0 : 15)
                    .opacity(animateUI ? 1.0 : 0.0)
                
                // ==========================================
                // 3. CARDS DE OPÇÃO
                // ==========================================
                VStack(spacing: 16) {
                    
                    // CARD 1: Já tenho conta (Vai para o Login)
                    SelectionCard(
                        icon: "arrow.right.to.line",
                        title: "Já tenho conta",
                        subtitle: "Entrar e continuar de onde parei.",
                        action: onIrParaLogin
                    )
                    
                    // CARD 2: Criar conta (Vai para o Cadastro)
                    SelectionCard(
                        icon: "envelope.fill",
                        title: "Criar conta com e-mail",
                        subtitle: "Cadastro rápido para começar agora.",
                        action: onIrParaCadastro
                    )
                }
                .padding(.horizontal, 24)
                .offset(y: animateUI ? 0 : 20)
                .opacity(animateUI ? 1.0 : 0.0)
                
                Spacer()
                
                // ==========================================
                // 4. FOOTER (Termos de Uso)
                // ==========================================
                VStack(spacing: 6) {
                    Text("Ao continuar, você aceita nossos Termos de")
                        .font(.system(size: 13))
                        .foregroundColor(secondaryTextGray)
                    
                    HStack(spacing: 4) {
                        Text("Uso e nossa")
                            .font(.system(size: 13))
                            .foregroundColor(secondaryTextGray)
                        
                        if let url = URL(string: "https://solidarizar.com.br/privacidade") {
                            Link("Política de Privacidade", destination: url)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color(red: 0.53, green: 0.49, blue: 0.64))
                                .underline()
                        }
                    }
                }
                .padding(.bottom, 30)
                .offset(y: animateUI ? 0 : 20)
                .opacity(animateUI ? 1.0 : 0.0)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                animateUI = true
            }
        }
    }
}

// ==========================================
// COMPONENTE: CARD DE SELEÇÃO
// ==========================================
struct SelectionCard: View {
    var icon: String
    var title: String
    var subtitle: String
    var action: () -> Void
    
    let appMagenta = Color(red: 0.88, green: 0.10, blue: 0.61)
    let appPurple = Color(red: 0.63, green: 0.08, blue: 0.86)
    
    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            action()
        }) {
            HStack(spacing: 16) {
                
                // Ícone com gradiente dentro de um box
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.05))
                        .frame(width: 52, height: 52)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(colors: [appMagenta, appPurple], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                }
                
                // Textos
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(Color(red: 0.68, green: 0.68, blue: 0.72))
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Setinha indicativa
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.white.opacity(0.3))
            }
            .padding(16)
            .background(Color.white.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(SelectionScaleButtonStyle())
    }
}

struct SelectionScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}
