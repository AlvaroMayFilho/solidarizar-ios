import SwiftUI

// 1. Criamos a animação do brilho passando na tela
struct ShimmerEffect: ViewModifier {
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        content
            .overlay(
                // O feixe de luz branca transparente
                LinearGradient(
                    gradient: Gradient(colors: [.clear, .white.opacity(0.6), .clear]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .rotationEffect(.degrees(20)) // Leve inclinação na luz
                .offset(x: isAnimating ? UIScreen.main.bounds.width : -UIScreen.main.bounds.width)
            )
            // A máscara garante que o brilho só apareça em cima dos textos e imagens, não no fundo vazio
            .mask(content)
            .onAppear {
                // Inicia a animação em loop infinito
                withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
    }
}

// 2. Criamos o atalho para você usar em qualquer lugar do app
extension View {
    @ViewBuilder
    func shimmer(isActive: Bool) -> some View {
        if isActive {
            // Se estiver carregando, aplica o visual de "esqueleto" nativo da Apple + nosso brilho
            self
                .redacted(reason: .placeholder)
                .modifier(ShimmerEffect())
        } else {
            // Se já carregou, mostra a tela normal
            self
        }
    }
}
