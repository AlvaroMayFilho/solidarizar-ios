import SwiftUI
import UIKit
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

// --- CONFIGURAÇÃO INICIAL DO FIREBASE ---
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct SolidarizarApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @StateObject private var ongViewModel = OngViewModel()
    
    // --- ESTADOS DE NAVEGAÇÃO ---
    // 1. ALTERADO: O app agora nasce no estado "welcome"
    @State private var telaAtual: String = "welcome"
    @State private var ongSelecionada: Ong? = nil
    @State private var captadorLogado: Usuario? = nil
    
    // Referência para o ouvinte em tempo real
    @State private var listenerCaptador: ListenerRegistration? = nil
    
    // --- ESTADOS DE DADOS (PIX E DOAÇÃO) ---
    @State private var valorSucesso: String = ""
    @State private var isRecorrenteSucesso: Bool = false
    @State private var pixCopiaColaRetornado: String = ""
    @State private var qrCodeRetornado: String = ""
    @State private var asaasIdRetornado: String = ""
    @State private var emailDoadorVitrine: String = ""
    
    // --- ESTADO DE SAQUE ---
    @State private var saldoParaSaque: Double = 0.0
    
    // --- UI CONTROLS ---
    @State private var processandoPagamento: Bool = false
    @State private var mostrarAlerta: Bool = false
    @State private var mensagemAlerta: String = ""

    var body: some Scene {
        WindowGroup {
            ZStack {
                // ==========================================
                // ROTEADOR DE TELAS
                // ==========================================
                
                // 2. ADICIONADO: Nova tela inicial do app
                if telaAtual == "welcome" {
                    WelcomeView(
                        onAvancarParaLogin: {
                            withAnimation { telaAtual = "auth_selection" } // REDIRECIONADO
                        }
                    )
                }
                // 3. ADICIONADO: Tela Intermediária de Seleção
                else if telaAtual == "auth_selection" {
                    AuthSelectionView(
                        onVoltar: { withAnimation { telaAtual = "welcome" } },
                        onIrParaLogin: { withAnimation { telaAtual = "login" } },
                        onIrParaCadastro: { withAnimation { telaAtual = "cadastro_convite" } }
                    )
                }
                // Procure por este trecho no seu SolidarizarApp.swift
                else if telaAtual == "vitrine" {
                    VitrineView(
                        ongs: ongViewModel.ongs,
                        carregando: ongViewModel.carregando,
                        onLoginClick: { withAnimation { telaAtual = "minhas_doacoes" } },
                        onOngClick: { ong in
                            ongSelecionada = ong
                            telaAtual = "detalhes_ong"
                        },
                        usuario: captadorLogado // <--- ESTA LINHA É A CHAVE
                    ).task { ongViewModel.buscarOngs() }
                }
                else if telaAtual == "minhas_doacoes" {
                    MinhasDoacoesView(
                        usuario: captadorLogado,
                        onVoltar: { withAnimation { telaAtual = "vitrine" } },
                        emailRecente: emailDoadorVitrine,
                        onSouCaptadorClick: {
                            if Auth.auth().currentUser != nil {
                                buscarDadosCaptador()
                            } else {
                                withAnimation { telaAtual = "login" }
                            }
                        },
                        onIrParaHome: { withAnimation { telaAtual = "home" } } // <--- Corrigido
                    )
                } // <--- CHAVE ADICIONADA AQUI
                else if telaAtual == "login" {
                    LoginView(
                        onLoginSuccess: { buscarDadosCaptador() },
                        onVoltar: { withAnimation { telaAtual = "auth_selection" } }, // REDIRECIONADO
                        onIrParaCadastro: { withAnimation { telaAtual = "cadastro_convite" } }
                    )
                }
                else if telaAtual == "cadastro_convite" {
                    CadastroView(
                        onVoltar: { withAnimation { telaAtual = "auth_selection" } }, // REDIRECIONADO
                        onCadastroSucesso: { withAnimation { telaAtual = "login" } }
                    )
                }
                else if telaAtual == "home" {
                    if let user = captadorLogado {
                        HomeView(
                            usuario: user,
                            onLogout: {
                                pararaOuvinte()
                                try? Auth.auth().signOut()
                                captadorLogado = nil
                                withAnimation { telaAtual = "welcome" } // Volta pro welcome ao sair
                            },
                            onVoltarParaVitrine: {
                                withAnimation { telaAtual = "vitrine" }
                            },
                            onVerDetalhesOng: { ong in
                                self.ongSelecionada = ong
                                withAnimation { telaAtual = "detalhes_ong" }
                            },
                            onSolicitarSaque: { saldo in
                                self.saldoParaSaque = saldo
                                withAnimation { telaAtual = "solicitar_saque" }
                            },
                            onNovaDoacaoClick: { withAnimation { telaAtual = "nova_arrecadacao" } },
                            onExtratoClick: { withAnimation { telaAtual = "extrato" } },
                            onEquipeClick: { withAnimation { telaAtual = "equipe" } }
                        )
                    } else {
                        Color.black.onAppear { telaAtual = "welcome" }
                    }
                }
                else if telaAtual == "equipe" {
                    if let user = captadorLogado {
                        EquipeView(usuario: user, onVoltar: { withAnimation { telaAtual = "home" } })
                    }
                }
                else if telaAtual == "extrato" {
                    if let user = captadorLogado {
                        ExtratoView(
                            usuario: user,
                            onVoltar: { withAnimation { telaAtual = "home" } },
                            onSolicitarSaque: { saldo in
                                self.saldoParaSaque = saldo
                                withAnimation { telaAtual = "solicitar_saque" }
                            }
                        )
                    }
                }
                else if telaAtual == "nova_arrecadacao" {
                    if let user = captadorLogado {
                        NovaArrecadacaoView(
                            usuario: user,
                            onVoltar: { withAnimation { telaAtual = "home" } },
                            onAvancarParaPix: { valor, nomeDoador, cpf, renuncia in
                                let nomeOng = ongViewModel.ongs.first(where: { $0.id == user.ongId })?.nome ?? "Instituição Parceira"
                                processarPagamento(tipo: "pix", valor: String(format: "%.2f", valor), recorrente: false, nomeDoador: nomeDoador, email: "", cpf: cpf, ongId: user.ongId, ongNome: nomeOng)
                            }
                        )
                    }
                }
                else if telaAtual == "solicitar_saque" {
                    SolicitarSaqueView(
                        saldoDisponivel: saldoParaSaque,
                        onVoltar: { withAnimation { telaAtual = "extrato" } },
                        onConfirmarSaque: { valorSolicitado in
                            processarSaque(valor: valorSolicitado)
                        }
                    )
                }
                else if telaAtual == "detalhes_ong", let ong = ongSelecionada {
                    DetalhesOngView(ong: ong, onVoltar: { telaAtual = (captadorLogado != nil ? "home" : "vitrine") }, onDoarClick: { telaAtual = "checkout" })
                }
                else if telaAtual == "checkout", let ong = ongSelecionada {
                    CheckoutView(
                        ong: ong,
                        onVoltar: { telaAtual = "detalhes_ong" },
                        onConfirmarPagamento: { tipo, valor, recorrente, email, cpf in
                            self.emailDoadorVitrine = email
                            processarPagamento(tipo: tipo, valor: valor, recorrente: recorrente, nomeDoador: "Doador", email: email, cpf: cpf, ongId: ong.id, ongNome: ong.nome)
                        }
                    )
                }
                else if telaAtual == "pagamento_pix" {
                    PagamentoPixView(
                        pixCopiaCola: pixCopiaColaRetornado,
                        qrCodeBase64: qrCodeRetornado,
                        valor: Double(valorSucesso.replacingOccurrences(of: ",", with: ".")) ?? 0.0,
                        asaasId: asaasIdRetornado,
                        usuarioId: captadorLogado?.id ?? "",
                        onSucesso: { telaAtual = "sucesso" },
                        onCancelar: { telaAtual = captadorLogado != nil ? "home" : "vitrine" }
                    )
                }
                else if telaAtual == "sucesso" {
                    SucessoView(
                        valor: valorSucesso,
                        ongNome: "A Instituição",
                        isRecorrente: isRecorrenteSucesso,
                        onVoltarInicio: {
                            telaAtual = captadorLogado != nil ? "home" : "vitrine"
                            limparDadosSessao()
                        }
                    )
                }
                
                if processandoPagamento {
                    LoadingOverlay()
                }
            }
            .alert("Aviso", isPresented: $mostrarAlerta) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(mensagemAlerta)
            }
            .onAppear {
                // 1. Lógica para manter a sessão ativa ao abrir o app
                if Auth.auth().currentUser != nil {
                    buscarDadosCaptador()
                }
                
                // 2. Listener Global de Logout:
                // Se o usuário clicar em "Sair" em qualquer tela do app, isso será ativado e jogará ele para a tela Welcome
                Auth.auth().addStateDidChangeListener { _, user in
                    if user == nil {
                        pararaOuvinte()
                        captadorLogado = nil
                        limparDadosSessao()
                        withAnimation { telaAtual = "welcome" }
                    }
                }
            }
        }
    }
    
    // =====================================
    // LÓGICA DE SINCRONIZAÇÃO E API (MANTIDA INTACTA)
    // =====================================

    func buscarDadosCaptador() {
            guard let user = Auth.auth().currentUser else { return }
            let db = Firestore.firestore()
            pararaOuvinte()

            print("DEBUG_DB: Procurando perfil para o UID/Email: '\(user.uid)'")

            // 1. Busca na coleção 'usuarios' onde o CAMPO 'email' seja igual ao seu user.uid
            db.collection("usuarios").whereField("email", isEqualTo: user.uid).limit(to: 1).getDocuments { snapshot, _ in
                
                // Se ele achar o documento que tem o seu e-mail dentro...
                if let docs = snapshot?.documents, let perfil = docs.first {
                    print("DEBUG_DB: Perfil encontrado! ID real: \(perfil.documentID)")
                    
                    // Ele pega o ID real do documento (aquele código embaralhado) e cria o ouvinte nele
                    self.listenerCaptador = db.collection("usuarios").document(perfil.documentID).addSnapshotListener { doc, err in
                        DispatchQueue.main.async {
                            if let doc = doc, doc.exists {
                                do {
                                    self.captadorLogado = try doc.data(as: Usuario.self)
                                    
                                    // Redirecionamento de sucesso
                                    if self.telaAtual == "login" || self.telaAtual == "cadastro_convite" || self.telaAtual == "welcome" || self.telaAtual == "auth_selection" {
                                        withAnimation { self.telaAtual = "vitrine" }
                                    } else if self.telaAtual == "minhas_doacoes" {
                                        withAnimation { self.telaAtual = "home" }
                                    }
                                } catch {
                                    print("🔥 ERRO DE DECODIFICAÇÃO NO SWIFT: \(error)")
                                    self.mensagemAlerta = "Erro: Estrutura do perfil incompatível."
                                    self.mostrarAlerta = true
                                }
                            }
                        }
                    }
                } else {
                    // Se não achar o e-mail, ele avisa que o perfil não existe
                    DispatchQueue.main.async {
                        self.mensagemAlerta = "Perfil não encontrado na coleção usuários."
                        self.mostrarAlerta = true
                        try? Auth.auth().signOut()
                        withAnimation { self.telaAtual = "welcome" }
                    }
                }
            }
        }
    
    func pararaOuvinte() {
        listenerCaptador?.remove()
        listenerCaptador = nil
    }

    func processarSaque(valor: Double) {
        guard let user = captadorLogado else { return }
        if user.cpf.isEmpty {
            mensagemAlerta = "Cadastre seu CPF no perfil primeiro!"
            mostrarAlerta = true
            return
        }
        processandoPagamento = true
        Task {
            do {
                let request = SaqueRequest(captador_id: user.id, cpf_chave_pix: user.cpf, valor_solicitado: valor)
                let response = try await ApiService.shared.solicitarSaque(request: request)
                DispatchQueue.main.async {
                    self.processandoPagamento = false
                    self.mensagemAlerta = response.sucesso ? "Saque solicitado com sucesso!" : response.mensagem
                    self.mostrarAlerta = true
                    if response.sucesso { withAnimation { self.telaAtual = "extrato" } }
                }
            } catch {
                DispatchQueue.main.async {
                    self.processandoPagamento = false
                    self.mensagemAlerta = "Erro de conexão."
                    self.mostrarAlerta = true
                }
            }
        }
    }
    
    func processarPagamento(tipo: String, valor: String, recorrente: Bool, nomeDoador: String, email: String, cpf: String, ongId: String, ongNome: String) {
            let valorNum = Double(valor.replacingOccurrences(of: ",", with: ".")) ?? 0.0
            
            if valorNum < 20.0 {
                self.mensagemAlerta = "O valor mínimo para doação é de R$ 20,00."
                self.mostrarAlerta = true
                return
            }
            
            processandoPagamento = true
            Task {
                do {
                    if tipo == "pix" {
                        let request = PixRequest(
                            valor: valorNum,
                            cpf_doador: cpf,
                            nome_doador: nomeDoador,
                            captador_id: captadorLogado?.id ?? "",
                            captador_nome: captadorLogado?.nome ?? "Vitrine",
                            ong_id: ongId,
                            lider_id: captadorLogado?.liderId ?? ""
                        )
                        
                        // 1. O Backend gera o PIX e SALVA no banco de dados sozinho.
                        let res = try await ApiService.shared.criarPix(request: request)
                        
                        DispatchQueue.main.async {
                            self.pixCopiaColaRetornado = res.copia_cola
                            self.qrCodeRetornado = res.imagem_base64
                            self.asaasIdRetornado = res.id_transacao_asaas
                            
                            // 2. Prepara a tela de sucesso
                            self.valorSucesso = valor
                            self.isRecorrenteSucesso = recorrente
                            self.processandoPagamento = false
                            self.telaAtual = "pagamento_pix"
                        }
                    } else {
                        // Lógica futura para cartão de crédito, se houver
                        DispatchQueue.main.async {
                            self.valorSucesso = valor
                            self.isRecorrenteSucesso = recorrente
                            self.processandoPagamento = false
                            self.telaAtual = "sucesso"
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.processandoPagamento = false
                        self.mensagemAlerta = "Erro ao processar doação: \(error.localizedDescription)"
                        self.mostrarAlerta = true
                    }
                }
            }
        }
    
    func limparDadosSessao() {
        pixCopiaColaRetornado = ""
        qrCodeRetornado = ""
        asaasIdRetornado = ""
    }
}

struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.8).ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView().scaleEffect(2).tint(.white)
                Text("Processando...").foregroundColor(.white).font(.headline)
            }
        }
    }
}
