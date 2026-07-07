import SwiftUI
import SafariServices

// 1. COMPONENTE DO NAVEGADOR
struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        let vc = SFSafariViewController(url: url, configuration: config)
        vc.preferredControlTintColor = .systemPurple // Ou ajuste para usar o themeColor
        return vc
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

// 2. A TELA DE DETALHES DA ONG
struct DetalhesOngView: View {
    let ong: Ong
    let onVoltar: () -> Void
    let onDoarClick: () -> Void // Podemos manter isso caso precise para tracking, mas não será usado para abrir a tela nativa.
    
    // VARIÁVEL DE ESTADO PARA CONTROLAR O NAVEGADOR
    @State private var mostrarNavegador = false
    
    // Resolve a cor vinda do portal
    var themeColor: Color {
        if !ong.cor.isEmpty { return Color(hex: ong.cor) }
        return Color(red: 0.23, green: 0.51, blue: 0.96) // Azul Padrão
    }
    
    // Transforma Base64 em Imagem
    func converterBase64ParaImagem(base64String: String) -> UIImage? {
        let cleanBase64 = base64String.components(separatedBy: ",").last ?? base64String
        guard let data = Data(base64Encoded: cleanBase64) else { return nil }
        return UIImage(data: data)
    }
    
    // Processamento dos Banners
    var bannersExibicao: [UIImage] {
        var imagens: [UIImage] = []
        for banner in ong.banners {
            if let img = converterBase64ParaImagem(base64String: banner) {
                imagens.append(img)
            }
        }
        
        if imagens.isEmpty {
            if let placeholder = UIImage(systemName: "photo.artframe") {
                imagens.append(placeholder)
            }
        }
        return imagens
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.darkBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    
                    // --- CARROSSEL DE IMAGENS ---
                    ZStack(alignment: .topLeading) {
                        TabView {
                            ForEach(0..<bannersExibicao.count, id: \.self) { index in
                                Image(uiImage: bannersExibicao[index])
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 350)
                                    .clipped()
                            }
                        }
                        .tabViewStyle(PageTabViewStyle())
                        .frame(height: 350)
                        
                        // --- BOTÃO DE VOLTAR ---
                        Button(action: onVoltar) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        .padding(.leading, 16)
                        .padding(.top, 50)
                    }
                    
                    // --- CONTEÚDO ---
                    VStack(alignment: .leading, spacing: 0) {
                        
                        // Badge da Causa
                        Text(ong.causa.uppercased())
                            .font(.system(size: 11, weight: .black))
                            .foregroundColor(themeColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(themeColor.opacity(0.15))
                            .cornerRadius(5)
                            .padding(.top, 24)
                        
                        Text(ong.nome)
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.top, 12)
                        
                        // Linha Decorativa
                        Rectangle()
                            .fill(themeColor.opacity(0.3))
                            .frame(width: 60, height: 4)
                            .cornerRadius(2)
                            .padding(.top, 16)
                        
                        // Sobre a Instituição
                        Text("Nossa História & Missão")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.top, 32)
                        
                        let textoApresentacao = !ong.historia.isEmpty ? ong.historia : "Esta instituição dedica-se a transformar vidas através da causa \(ong.causa). Sua doação ajuda a manter projetos vitais e garantir um futuro melhor para quem mais precisa."
                        
                        Text(textoApresentacao)
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                            .lineSpacing(6)
                            .padding(.top, 12)
                        
                        // Detalhes extras (Cidade/UF)
                        HStack {
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundColor(themeColor)
                            Text("Atuante em todo o território nacional")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 24)
                        
                        Spacer().frame(height: 120)
                    }
                    .padding(.horizontal, 24)
                    .background(
                        LinearGradient(gradient: Gradient(colors: [Color.darkBackground.opacity(0), Color.darkBackground]), startPoint: .top, endPoint: .bottom)
                            .offset(y: -40)
                    )
                }
            }
            .ignoresSafeArea(edges: .top)
            
            // --- BOTÃO DE AÇÃO (ABRE O NAVEGADOR) ---
            VStack {
                Button(action: {
                    // DISPARA A VARIÁVEL QUE ABRE A TELA WEB
                    mostrarNavegador = true
                }) {
                    HStack {
                        Image(systemName: "heart.fill")
                        Text("FAZER UMA DOAÇÃO")
                            .font(.system(size: 15, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(themeColor)
                    .cornerRadius(16)
                    .shadow(color: themeColor.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(
                Color.cardBackground
                    .ignoresSafeArea()
                    .shadow(color: Color.black.opacity(0.4), radius: 10, x: 0, y: -5)
            )
            // LIGA O BOTÃO AO SAFARIVIEW
            .sheet(isPresented: $mostrarNavegador) {
                // Passa a URL dinâmica baseada no ID da ONG selecionada
                if let url = URL(string: "https://solidarizar.com.br/doar/ong/\(ong.id)") {
                    SafariView(url: url)
                        .ignoresSafeArea()
                } else {
                    // Fallback caso a URL seja inválida (muito raro)
                    Text("Erro ao carregar link de doação.")
                }
            }
        }
    }
}
