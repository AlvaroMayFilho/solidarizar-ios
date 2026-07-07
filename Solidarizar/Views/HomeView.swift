import SwiftUI
import UIKit
import FirebaseFirestore
import FirebaseAuth
import PhotosUI

struct HomeView: View {
    // --- PROPRIEDADES QUE VEM DO ROTEADOR ---
    let usuario: Usuario
    var onLogout: () -> Void
    var onVoltarParaVitrine: () -> Void
    var onVerDetalhesOng: (Ong) -> Void // Mantido na estrutura, mas não acionado aqui para evitar dados incompletos
    var onSolicitarSaque: (Double) -> Void
    var onNovaDoacaoClick: () -> Void
    var onExtratoClick: () -> Void
    var onEquipeClick: () -> Void
    
    // --- ESTADO DE DADOS ---
    @State private var nomeOng: String = "Carregando..."
    @State private var ongCompleta: Ong? = nil
    
    // --- ESTADOS PARA UPLOAD DE FOTO E UI ---
    @State private var itemSelecionado: PhotosPickerItem? = nil
    @State private var subindoFoto = false
    @State private var mostrarCracha = false

    // Paleta de Cores Oficial
    let violetDark = Color(red: 0.30, green: 0.11, blue: 0.58)
    let localMagenta = Color(red: 0.85, green: 0.27, blue: 0.94)
    let darkBackground = Color(red: 0.05, green: 0.05, blue: 0.05)
    let cardBg = Color(red: 0.11, green: 0.11, blue: 0.12)
    
    var body: some View {
        ZStack {
            darkBackground.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    headerSection
                    
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // 1. CRACHÁ DE IDENTIFICAÇÃO (Clique no card abre o Crachá Digital)
                        Button(action: { mostrarCracha = true }) {
                            credentialCard
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // 2. CARD DE CONFIANÇA
                        trustCard
                        
                        // 3. SEÇÃO DE OPERAÇÃO
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Operação Administrativa")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.gray)
                                .padding(.leading, 4)
                            
                            // Botão de Foto (Aparece se o captador não tiver foto)
                            if usuario.foto_url.isEmpty {
                                photoUploadButton
                            }
                            
                            botaoNovaDoacao
                            
                            HStack(spacing: 16) {
                                MenuButton(icon: "list.bullet.rectangle.portrait", label: "Meu Extrato", color: .orange, action: onExtratoClick)
                                MenuButton(icon: "person.2.badge.key", label: "Minha Equipe", color: .blue, action: onEquipeClick)
                            }
                        }
                    }
                    .padding(24)
                }
            }
            
            if subindoFoto {
                LoadingOverlay()
            }
        }
        .onAppear { buscarDadosOng() }
        .onChange(of: itemSelecionado) { _ in
            processarEFazerUploadDaFoto()
        }
        .sheet(isPresented: $mostrarCracha) {
            CartaoIdentificacaoView(usuario: usuario, ong: ongCompleta)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - COMPONENTES DE INTERFACE

    private var headerSection: some View {
        VStack(spacing: 20) {
            HStack {
                Button(action: onVoltarParaVitrine) {
                    Label("Vitrine", systemImage: "house.fill")
                        .font(.system(size: 13, weight: .bold))
                        .padding(.vertical, 8).padding(.horizontal, 14)
                        .background(Color.black.opacity(0.3)).clipShape(Capsule())
                }
                Spacer()
                Button(action: { try? Auth.auth().signOut(); onLogout() }) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .padding(10).background(Color.white.opacity(0.15)).clipShape(Circle())
                }
            }
            .padding(.top, 50)
            
            HStack(spacing: 15) {
                // LOGO AGORA REDIRECIONA PARA A VITRINE COMPLETA
                Button(action: { onVoltarParaVitrine() }) {
                    avatarOngView
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(usuario.nome).font(.system(size: 18, weight: .bold))
                    Text("Identificação do Captador")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }
                Spacer()
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, 24).padding(.bottom, 30)
        .background(LinearGradient(colors: [violetDark, localMagenta], startPoint: .top, endPoint: .bottom))
        .clipShape(RoundedCorner(radius: 32, corners: [.bottomLeft, .bottomRight]))
    }

    private var credentialCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("INSTITUIÇÃO PARCEIRA")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(localMagenta)
                    Text(nomeOng)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "checkmark.seal.fill").font(.title).foregroundColor(.blue)
            }
            
            Divider().background(Color.white.opacity(0.1))
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("CNPJ REGISTRADO")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.gray)
                    Text(ongCompleta?.cnpj ?? "---")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }
                Spacer()
                
                // BOTÃO AGORA LEVA DIRETO PARA A VITRINE
                Button(action: { onVoltarParaVitrine() }) {
                    Text("VER NA VITRINE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10).padding(.vertical, 8)
                        .background(violetDark)
                        .cornerRadius(8)
                }
            }
        }
        .padding(20).background(cardBg).cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(localMagenta.opacity(0.3), lineWidth: 1))
    }

    private var trustCard: some View {
        HStack(spacing: 15) {
            Image(systemName: "shield.checkered").foregroundColor(.green).font(.title3)
                .padding(10).background(Color.green.opacity(0.1)).clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text("Doação Direta e Segura").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                Text("O valor via PIX cai direto na conta oficial da instituição.").font(.system(size: 12)).foregroundColor(.gray)
            }
        }
        .padding().frame(maxWidth: .infinity, alignment: .leading).background(cardBg.opacity(0.5)).cornerRadius(16)
    }

    private var photoUploadButton: some View {
        PhotosPicker(selection: $itemSelecionado, matching: .images) {
            HStack {
                Image(systemName: "camera.badge.ellipsis")
                Text("Enviar foto para o crachá digital")
            }
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(localMagenta)
            .padding().frame(maxWidth: .infinity).background(localMagenta.opacity(0.1)).cornerRadius(12)
        }
    }

    private var avatarOngView: some View {
        Group {
            if let img = converterBase64(usuario.foto_url.isEmpty ? (ongCompleta?.imagem_url ?? "") : usuario.foto_url) {
                Image(uiImage: img).resizable().scaledToFill()
                    .frame(width: 50, height: 50).clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.4), lineWidth: 2))
            } else {
                Image(systemName: "person.crop.circle.fill").font(.system(size: 50)).foregroundColor(.white.opacity(0.5))
            }
        }
    }

    private var botaoNovaDoacao: some View {
        Button(action: onNovaDoacaoClick) {
            HStack(spacing: 16) {
                Image(systemName: "qrcode.viewfinder").font(.title).padding(10).background(Color.white.opacity(0.1).cornerRadius(12))
                VStack(alignment: .leading, spacing: 2) {
                    Text("GERAR DOAÇÃO AGORA").font(.system(size: 15, weight: .black))
                    Text("QR Code Pix Seguro").font(.system(size: 12)).opacity(0.8)
                }
                Spacer()
                Image(systemName: "arrow.right.circle.fill").font(.title2)
            }
            .padding().background(LinearGradient(colors: [violetDark, Color.purple], startPoint: .leading, endPoint: .trailing))
            .foregroundColor(.white).cornerRadius(18).shadow(color: violetDark.opacity(0.4), radius: 10, x: 0, y: 5)
        }
    }

    // MARK: - FUNÇÕES DE LÓGICA

    func processarEFazerUploadDaFoto() {
        Task {
            guard let item = itemSelecionado else { return }
            DispatchQueue.main.async { self.subindoFoto = true }
            
            if let data = try? await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                
                let targetSize = CGSize(width: 400, height: 400)
                let renderer = UIGraphicsImageRenderer(size: targetSize)
                let resizedImage = renderer.image { _ in
                    uiImage.draw(in: CGRect(origin: .zero, size: targetSize))
                }
                
                let fotoCompactada = resizedImage.jpegData(compressionQuality: 0.5)
                let base64 = fotoCompactada?.base64EncodedString() ?? ""
                
                try? await Firestore.firestore().collection("usuarios").document(usuario.id).updateData([
                    "foto_url": base64
                ])
            }
            DispatchQueue.main.async { self.subindoFoto = false }
        }
    }

    private func converterBase64(_ str: String) -> UIImage? {
        let clean = str.components(separatedBy: ",").last ?? str
        guard let data = Data(base64Encoded: clean) else { return nil }
        return UIImage(data: data)
    }

    func buscarDadosOng() {
        print("DEBUG_DB: Iniciando buscarDadosOng. ID da ONG: '\(usuario.ongId)'")
        
        // PROTEÇÃO CONTRA CRASH: Se o ID for vazio, não tenta buscar
        guard !usuario.ongId.isEmpty else {
            print("DEBUG_DB: Erro fatal - ongId está vazio. Abortando.")
            return
        }
        
        Firestore.firestore().collection("ongs").document(usuario.ongId).getDocument { snapshot, _ in
            guard let d = snapshot?.data() else { return }
            let id = snapshot?.documentID ?? ""
            let n = d["nome_fantasia"] as? String ?? d["nome"] as? String ?? "Instituição"
            let cau = d["causa"] as? String ?? ""
            let desc = d["descricao"] as? String ?? ""
            let img = d["imagem_url"] as? String ?? ""
            let cor = d["cor"] as? String ?? ""
            let cnp = d["cnpj"] as? String ?? ""
            let pix = d["pix"] as? String ?? ""
            
            let ong = Ong(id: id, nome: n, causa: cau, descricao: desc, imagem_url: img, cor: cor, cnpj: cnp, pix: pix)
            
            DispatchQueue.main.async {
                self.nomeOng = n
                self.ongCompleta = ong
            }
        }
    }
}

// --- COMPONENTES AUXILIARES ---

struct MenuButton: View {
    let icon: String; let label: String; let color: Color; var action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: icon).font(.system(size: 20)).padding(12)
                    .background(color.opacity(0.15)).foregroundColor(color).clipShape(Circle())
                Spacer().frame(height: 8)
                Text(label).font(.system(size: 12, weight: .bold)).foregroundColor(.white)
            }
            .frame(maxWidth: .infinity).frame(height: 90).background(Color(red: 0.11, green: 0.11, blue: 0.12)).cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.05), lineWidth: 1))
        }
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity; var corners: UIRectCorner = .allCorners
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
