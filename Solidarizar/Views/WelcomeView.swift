import SwiftUI

struct WelcomeView: View {
    var onAvancarParaLogin: () -> Void
    
    // ==========================================
    // CORES OFICIAIS DO APP
    // ==========================================
    let deepCharcoalBackground = Color(red: 0.05, green: 0.05, blue: 0.06)
    let appMagenta = Color(red: 0.88, green: 0.10, blue: 0.61)
    let appPurple = Color(red: 0.63, green: 0.08, blue: 0.86)
    let secondaryTextGray = Color(red: 0.68, green: 0.68, blue: 0.72)
    
    // Estado para animação de entrada (Toque sênior)
    @State private var animateUI: Bool = false

    var body: some View {
        ZStack {
            // 1. FUNDO E AMBIENT GLOW (Profundidade)
            deepCharcoalBackground
                .ignoresSafeArea()
            
            // Luzes difusas no fundo para não deixar a tela "chapada"
            Circle()
                .fill(appMagenta.opacity(0.15))
                .blur(radius: 90)
                .frame(width: 300, height: 300)
                .offset(x: -100, y: -250)
            
            Circle()
                .fill(appPurple.opacity(0.15))
                .blur(radius: 90)
                .frame(width: 300, height: 300)
                .offset(x: 150, y: 150)
            
            VStack(spacing: 0) {
                
                // ==========================================
                // 2. LOGO (Tratada como App Icon)
                // ==========================================
                Spacer().frame(height: 20)
                
                Image("logo_oficial")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 85, height: 85)
                    // Solução elegante para o fundo quadrado da sua logo
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .shadow(color: Color.black.opacity(0.5), radius: 15, x: 0, y: 8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .padding(.top, 40)
                    .scaleEffect(animateUI ? 1.0 : 0.8)
                    .opacity(animateUI ? 1.0 : 0.0)
                
                Spacer()
                
                // ==========================================
                // 3. TYPOGRAPHY (Hierarquia e Impacto)
                // ==========================================
                VStack(spacing: 12) {
                    Text("Sua jornada para")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("transformar o mundo")
                        .font(.system(size: 32, weight: .heavy))
                        // Metódo atualizado e limpo para gradiente em texto (iOS 15+)
                        .foregroundStyle(
                            LinearGradient(colors: [appMagenta, appPurple], startPoint: .leading, endPoint: .trailing)
                        )
                }
                .multilineTextAlignment(.center)
                .padding(.bottom, 20)
                .offset(y: animateUI ? 0 : 20)
                .opacity(animateUI ? 1.0 : 0.0)
                
                Text("Descubra, conecte-se e doe. O valor via PIX cai direto na conta oficial da instituição.")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(secondaryTextGray)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
                    .offset(y: animateUI ? 0 : 20)
                    .opacity(animateUI ? 1.0 : 0.0)
                
                // ==========================================
                // 4. TRUST BADGES (Características Visuais)
                // ==========================================
                HStack(spacing: 30) {
                    FeatureIconView(icon: "bolt.fill", title: "Rápido")
                    FeatureIconView(icon: "lock.shield.fill", title: "Seguro")
                    FeatureIconView(icon: "heart.fill", title: "Transparente")
                }
                .padding(.bottom, 50)
                .offset(y: animateUI ? 0 : 20)
                .opacity(animateUI ? 1.0 : 0.0)
                
                Spacer()
                
                // ==========================================
                // 5. BOTÃO PRINCIPAL E FOOTER
                // ==========================================
                VStack(spacing: 24) {
                    Button(action: {
                        // Feedback tátil sênior ao clicar
                        let impactMed = UIImpactFeedbackGenerator(style: .medium)
                        impactMed.impactOccurred()
                        onAvancarParaLogin()
                    }) {
                        HStack {
                            Text("Começar agora")
                                .font(.system(size: 18, weight: .bold))
                            Spacer()
                            Image(systemName: "arrow.right")
                                .font(.system(size: 18, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 20)
                        .padding(.horizontal, 28)
                        .background(
                            LinearGradient(colors: [appMagenta, appPurple], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .shadow(color: appPurple.opacity(0.4), radius: 15, x: 0, y: 8)
                    }
                    .buttonStyle(ScaleButtonStyle()) // Efeito de clique premium (definido abaixo)
                    
                    if let url = URL(string: "https://solidarizar.com.br/privacidade") {
                        Link(destination: url) {
                            Text("Política de privacidade")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(secondaryTextGray.opacity(0.8))
                                .padding(.bottom, 10)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
                .offset(y: animateUI ? 0 : 20)
                .opacity(animateUI ? 1.0 : 0.0)
            }
        }
        .onAppear {
            // Animação em cascata suave quando a tela abre
            withAnimation(.easeOut(duration: 0.8)) {
                animateUI = true
            }
        }
    }
}

// ==========================================
// COMPONENTES AUXILIARES
// ==========================================

// Componente para os ícones de confiança (Trust Badges)
struct FeatureIconView: View {
    var icon: String
    var title: String
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 54, height: 54)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(colors: [Color(red: 0.88, green: 0.10, blue: 0.61), Color(red: 0.63, green: 0.08, blue: 0.86)], startPoint: .top, endPoint: .bottom)
                    )
            }
            
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(red: 0.68, green: 0.68, blue: 0.72))
        }
    }
}

// Estilo de botão customizado que encolhe levemente ao ser pressionado
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}
