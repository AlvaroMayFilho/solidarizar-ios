import SwiftUI
import FirebaseFirestore

// --- MODELOS ---
struct MembroStats: Identifiable {
    var id: String { usuario.id }
    var usuario: Usuario
    var totalVendido: Double
    var comissaoLider: Double
}

struct Convite: Identifiable, Codable {
    @DocumentID var id: String?
    var codigo: String = ""
    var liderId: String = ""
    var ongId: String = ""
    var status: String = "ATIVO"
    @ServerTimestamp var dataCriacao: Timestamp?
}

// --- TELA PRINCIPAL ---
struct EquipeView: View {
    var usuario: Usuario
    var onVoltar: () -> Void
    
    @State private var listaMembros: [MembroStats] = []
    @State private var listaConvitesAtivos: [Convite] = []
    @State private var carregando = true
    
    @State private var totalEquipeVendeu = 0.0
    @State private var totalGanhosLider = 0.0
    
    // Referências para os ouvintes em tempo real
    @State private var listenerConvites: ListenerRegistration? = nil
    @State private var listenerMembros: ListenerRegistration? = nil
    
    @State private var mostrarAlerta = false
    @State private var mensagemAlerta = ""
    
    // Paleta de Cores Premium
    let darkBackground = Color(red: 0.05, green: 0.05, blue: 0.05)
    let cardBackground = Color(red: 0.11, green: 0.11, blue: 0.12)
    let purpleAction = Color(red: 0.55, green: 0.36, blue: 0.96)
    let orangeAction = Color(red: 0.96, green: 0.62, blue: 0.04)
    let greenMoney = Color(red: 0.06, green: 0.73, blue: 0.51)
    
    var body: some View {
        ZStack {
            darkBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // --- TOP BAR ---
                HStack {
                    Button(action: {
                        pararOuvintes()
                        onVoltar()
                    }) {
                        Image(systemName: "arrow.left")
                            .foregroundColor(.white)
                            .font(.system(size: 20, weight: .bold))
                            .padding()
                    }
                    Text("Gestão de Equipe")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.top, 10)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        if usuario.tipo == "PRIMARIO" {
                            // --- ÁREA DE CONVITES ---
                            VStack(spacing: 16) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("Códigos de Convite")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.gray)
                                        
                                        let slots = listaMembros.count + listaConvitesAtivos.count
                                        Text("\(slots)/10 Ocupados")
                                            .font(.system(size: 12))
                                            .foregroundColor(slots >= 10 ? .red : greenMoney)
                                    }
                                    Spacer()
                                    Button(action: gerarNovoConvite) {
                                        HStack {
                                            Image(systemName: "plus.circle.fill")
                                            Text("Novo Código")
                                        }
                                        .font(.system(size: 12, weight: .bold))
                                        .padding(.horizontal, 12).padding(.vertical, 8)
                                        .background(purpleAction)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                    }
                                    .disabled(listaMembros.count + listaConvitesAtivos.count >= 10)
                                }
                                
                                if listaConvitesAtivos.isEmpty {
                                    Text("Nenhum código ativo.")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray.opacity(0.6))
                                        .padding(.top, 8)
                                } else {
                                    ForEach(listaConvitesAtivos) { convite in
                                        ItemConviteView(convite: convite, onExcluir: { excluirConvite(id: convite.id ?? "") })
                                    }
                                }
                            }
                            .padding(20)
                            .background(cardBackground)
                            .cornerRadius(16)
                            
                            // --- DASHBOARD FINANCEIRO ---
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Vendas da Equipe").font(.system(size: 12)).foregroundColor(.gray)
                                    Text("R$ \(String(format: "%.2f", totalEquipeVendeu))")
                                        .font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                                }
                                Spacer()
                                VStack(alignment: .trailing) {
                                    Text("Seu Ganho (3%)").font(.system(size: 12, weight: .bold)).foregroundColor(purpleAction)
                                    Text("+ R$ \(String(format: "%.2f", totalGanhosLider))")
                                        .font(.system(size: 18, weight: .bold)).foregroundColor(greenMoney)
                                }
                            }
                            .padding(20)
                            .background(cardBackground)
                            .cornerRadius(16)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(purpleAction.opacity(0.3), lineWidth: 1))
                            
                            // --- LISTA DE MEMBROS ---
                            Text("Membros Ativos")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.top, 8)
                            
                            if carregando {
                                ProgressView().tint(purpleAction).frame(maxWidth: .infinity)
                            } else if listaMembros.isEmpty {
                                Text("Sua equipe ainda está vazia.")
                                    .foregroundColor(.gray).frame(maxWidth: .infinity, alignment: .center)
                            } else {
                                ForEach(listaMembros) { stats in
                                    CardMembroView(stats: stats, onIndicar: { indicarPromocao(membroId: stats.usuario.id) })
                                }
                            }
                            
                        } else {
                            // VISÃO DO SECUNDÁRIO
                            VStack(spacing: 16) {
                                Image(systemName: "person.2.badge.key.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(purpleAction.opacity(0.5))
                                Text("Área Restrita a Líderes")
                                    .font(.headline).foregroundColor(.white)
                                Text("Para recrutar novos parceiros e ganhar sobre as vendas deles, você precisa ser promovido a Líder Primário.")
                                    .font(.subheadline).foregroundColor(.gray).multilineTextAlignment(.center)
                            }
                            .padding(40)
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(24)
                }
            }
        }
        .onAppear { iniciarOuvintes() }
        .onDisappear { pararOuvintes() }
        .alert("Aviso", isPresented: $mostrarAlerta) {
            Button("OK", role: .cancel) { }
        } message: { Text(mensagemAlerta) }
    }
    
    // MARK: - Lógica Firebase Tempo Real
    
    func iniciarOuvintes() {
        guard usuario.tipo == "PRIMARIO" else {
            self.carregando = false
            return
        }
        let db = Firestore.firestore()
        
        // 1. Escutar Convites
        listenerConvites = db.collection("convites")
            .whereField("liderId", isEqualTo: usuario.id)
            .whereField("status", isEqualTo: "ATIVO")
            .addSnapshotListener { snap, _ in
                self.listaConvitesAtivos = snap?.documents.compactMap { try? $0.data(as: Convite.self) } ?? []
            }
        
        // 2. Escutar Membros e Vendas
        listenerMembros = db.collection("usuarios")
            .whereField("liderId", isEqualTo: usuario.id)
            .addSnapshotListener { snapUsers, _ in
                guard let userDocs = snapUsers?.documents else {
                    self.carregando = false
                    return
                }
                
                let membros = userDocs.compactMap { try? $0.data(as: Usuario.self) }
                
                // Busca vendas da equipe para compor o stats
                db.collection("transacoes")
                    .whereField("lider_id", isEqualTo: usuario.id)
                    .whereField("status", isEqualTo: "CONCLUIDA")
                    .getDocuments { snapTrans, _ in
                        var tempMembrosStats: [MembroStats] = []
                        var somaVendasTotal = 0.0
                        
                        for membro in membros {
                            let vendasMembro = snapTrans?.documents.filter { ($0.data()["captador_id"] as? String) == membro.id } ?? []
                            let total = vendasMembro.reduce(0.0) { $0 + (($1.data()["valor_bruto"] as? Double) ?? 0.0) }
                            
                            somaVendasTotal += total
                            tempMembrosStats.append(MembroStats(usuario: membro, totalVendido: total, comissaoLider: total * 0.03))
                        }
                        
                        DispatchQueue.main.async {
                            self.listaMembros = tempMembrosStats
                            self.totalEquipeVendeu = somaVendasTotal
                            self.totalGanhosLider = somaVendasTotal * 0.03
                            self.carregando = false
                        }
                    }
            }
    }
    
    func pararOuvintes() {
        listenerConvites?.remove()
        listenerMembros?.remove()
    }
    
    func gerarNovoConvite() {
        let db = Firestore.firestore()
        let codigo = String(UUID().uuidString.prefix(5)).uppercased()
        let novoConvite = Convite(codigo: codigo, liderId: usuario.id, ongId: usuario.ongId, status: "ATIVO")
        // CORREÇÃO: Adicionado '_ =' para silenciar o aviso de resultado não utilizado
        _ = try? db.collection("convites").addDocument(from: novoConvite)
    }
    
    func excluirConvite(id: String) {
        Firestore.firestore().collection("convites").document(id).delete()
    }
    
    func indicarPromocao(membroId: String) {
        Firestore.firestore().collection("usuarios").document(membroId).updateData(["status_promocao": "PENDENTE"]) { err in
            if err == nil {
                mensagemAlerta = "Indicação de promoção enviada!"
                mostrarAlerta = true
            }
        }
    }
}

// --- SUBCOMPONENTES ---

struct ItemConviteView: View {
    var convite: Convite
    var onExcluir: () -> Void
    
    var body: some View {
        HStack {
            HStack(spacing: 12) {
                Image(systemName: "ticket.fill")
                    .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                Text(convite.codigo)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .tracking(2)
            }
            Spacer()
            HStack(spacing: 16) {
                Button(action: compartilhar) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(Color(red: 0.55, green: 0.36, blue: 0.96))
                }
                Button(action: onExcluir) {
                    Image(systemName: "trash.fill").foregroundColor(.red.opacity(0.7))
                }
            }
        }
        .padding(16)
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
    
    func compartilhar() {
        let msg = "Venha fazer parte da minha equipe na Solidarizar! Use meu código de convite: \(convite.codigo)"
        let av = UIActivityViewController(activityItems: [msg], applicationActivities: nil)
        
        // CORREÇÃO: Forma moderna de apresentar ViewController no SwiftUI
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(av, animated: true)
        }
    }
}

struct CardMembroView: View {
    var stats: MembroStats
    var onIndicar: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                ZStack {
                    Circle().fill(Color.purple.opacity(0.15)).frame(width: 40, height: 40)
                    Image(systemName: "person.fill").foregroundColor(.purple)
                }
                VStack(alignment: .leading) {
                    Text(stats.usuario.nome).font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                    Text("Vendas: R$ \(String(format: "%.2f", stats.totalVendido))").font(.system(size: 12)).foregroundColor(.gray)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Seu Bônus").font(.system(size: 10)).foregroundColor(.gray)
                    Text("+R$ \(String(format: "%.2f", stats.comissaoLider))").font(.system(size: 14, weight: .bold)).foregroundColor(.green)
                }
            }
            
            Divider().background(Color.gray.opacity(0.2))
            
            HStack {
                Spacer()
                if stats.usuario.tipo == "PRIMARIO" {
                    BadgeView(texto: "Já é Líder", cor: .green, icone: "checkmark.seal.fill")
                } else if stats.usuario.statusPromocao == "PENDENTE" {
                    BadgeView(texto: "Promoção Pendente", cor: .orange, icone: "clock.fill")
                } else {
                    Button(action: onIndicar) {
                        Text("Indicar para Líder")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(red: 0.11, green: 0.11, blue: 0.12))
        .cornerRadius(14)
    }
}

struct BadgeView: View {
    var texto: String
    var cor: Color
    var icone: String
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icone).font(.system(size: 10))
            Text(texto).font(.system(size: 11, weight: .bold))
        }
        .foregroundColor(cor)
        .padding(.horizontal, 10).padding(.vertical, 4)
        .background(cor.opacity(0.1))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(cor.opacity(0.3), lineWidth: 1))
    }
}
