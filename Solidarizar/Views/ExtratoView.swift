import SwiftUI
import FirebaseFirestore

struct ExtratoView: View {
    let usuario: Usuario
    var onVoltar: () -> Void
    var onSolicitarSaque: (Double) -> Void // Função para abrir a tela de saque
    
    // Controle de Abas: "movimentacoes" ou "financeiro"
    @State private var abaSelecionada: String = "movimentacoes"
    
    // Estados de Dados (Extrato)
    @State private var listaMovimentacoes: [[String: Any]] = []
    @State private var carregando: Bool = true
    @State private var transacoesTemp: [[String: Any]] = []
    @State private var saquesTemp: [[String: Any]] = []
    
    // Estados de Dados (Financeiro - Movidos da Home)
    @State private var totalCaptado: Double = 0.0
    @State private var comissaoPessoal: Double = 0.0
    @State private var comissaoEquipe: Double = 0.0
    
    // Referências para os ouvintes
    @State private var listenerTransacoes: ListenerRegistration? = nil
    @State private var listenerSaques: ListenerRegistration? = nil
    @State private var listenerEquipe: ListenerRegistration? = nil
    
    var minhaComissaoTotal: Double {
        comissaoPessoal + comissaoEquipe
    }
    
    // Paleta de Cores
    let darkBackground = Color(red: 0.05, green: 0.05, blue: 0.05)
    let cardBackground = Color(red: 0.11, green: 0.11, blue: 0.12)
    let purpleAction = Color(red: 0.55, green: 0.36, blue: 0.96)
    let orangeAction = Color(red: 0.96, green: 0.62, blue: 0.04)
    let greenMoney = Color(red: 0.06, green: 0.73, blue: 0.51)
    let textGray = Color.gray
    let textWhite = Color.white
    
    var body: some View {
        ZStack {
            darkBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // --- TOP BAR ---
                HStack {
                    Button(action: {
                        stopListeners()
                        onVoltar()
                    }) {
                        Image(systemName: "arrow.left")
                            .foregroundColor(textWhite)
                            .font(.system(size: 20, weight: .bold))
                            .padding()
                    }
                    Text("Minha Conta")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(textWhite)
                    Spacer()
                }
                .padding(.top, 10)
                
                // --- SELETOR DE ABAS (FILTROS) ---
                HStack(spacing: 0) {
                    TabButton(title: "Extrato", isSelected: abaSelecionada == "movimentacoes") {
                        abaSelecionada = "movimentacoes"
                    }
                    TabButton(title: "Financeiro", isSelected: abaSelecionada == "financeiro") {
                        abaSelecionada = "financeiro"
                    }
                }
                .background(cardBackground)
                .cornerRadius(12)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                
                // --- CONTEÚDO DINÂMICO ---
                if abaSelecionada == "movimentacoes" {
                    abaExtratoView
                } else {
                    abaFinanceiroView
                }
            }
        }
        .onAppear {
            startListeners()
        }
        .onDisappear {
            stopListeners()
        }
    }
    
    // MARK: - ABA 1: EXTRATO
    private var abaExtratoView: some View {
        Group {
            if carregando {
                Spacer(); ProgressView().tint(purpleAction).scaleEffect(1.5); Spacer()
            } else if listaMovimentacoes.isEmpty {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "tray.fill").font(.system(size: 40)).foregroundColor(textGray.opacity(0.3))
                    Text("Nenhuma movimentação encontrada.").foregroundColor(textGray)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(0..<listaMovimentacoes.count, id: \.self) { index in
                            let item = listaMovimentacoes[index]
                            let tipo = item["tipo_item"] as? String ?? ""
                            
                            if tipo == "ENTRADA" {
                                CardDoacaoItem(dados: item, greenMoney: greenMoney, orangeAction: orangeAction, cardBackground: cardBackground)
                            } else {
                                CardSaqueItem(dados: item, orangeAction: orangeAction, cardBackground: cardBackground)
                            }
                        }
                    }
                    .padding(16)
                }
            }
        }
    }
    
    // MARK: - ABA 2: FINANCEIRO (ELEMENTOS MOVIDOS DA HOME)
    private var abaFinanceiroView: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                // Card de Total Arrecadado (Pessoal)
                VStack(spacing: 8) {
                    Text("Total Arrecadado (Pessoal)")
                        .font(.caption)
                        .foregroundColor(textGray)
                    Text("R$ \(String(format: "%.2f", totalCaptado))")
                        .font(.system(size: 38, weight: .black))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .background(purpleAction.opacity(0.1))
                .cornerRadius(20)
                
                // Card de Comissão e Botão de Saque
                VStack(spacing: 20) {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Sua Comissão Disponível")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(textGray)
                            Text("R$ \(String(format: "%.2f", minhaComissaoTotal))")
                                .font(.system(size: 30, weight: .bold))
                                .foregroundColor(greenMoney)
                            
                            if comissaoEquipe > 0 {
                                Text("(Inclui R$ \(String(format: "%.2f", comissaoEquipe)) da equipe)")
                                    .font(.caption2).fontWeight(.semibold).foregroundColor(purpleAction)
                            }
                        }
                        Spacer()
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(greenMoney)
                    }
                    
                    Button(action: { onSolicitarSaque(minhaComissaoTotal) }) {
                        HStack {
                            Text("💰")
                            Text("Solicitar Saque").fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color(red: 0.23, green: 0.51, blue: 0.96))
                        .foregroundColor(.white)
                        .cornerRadius(14)
                    }
                    
                    Divider().background(Color.white.opacity(0.1))
                    
                    HStack {
                        Image(systemName: "info.circle").font(.caption)
                        Text("Pagamento automático via API (Pix)").font(.caption2)
                        Spacer()
                    }
                    .foregroundColor(textGray)
                }
                .padding(24)
                .background(cardBackground)
                .cornerRadius(20)
            }
            .padding(16)
        }
    }
    
    // MARK: - Lógica de Dados
    
    func startListeners() {
        let db = Firestore.firestore()
        
        // Listener de Transações (Entradas)
        listenerTransacoes = db.collection("transacoes")
            .whereField("captador_id", isEqualTo: usuario.id)
            .addSnapshotListener { snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                var novasTrans: [[String: Any]] = []
                var sTotal = 0.0; var sComPessoal = 0.0
                
                for doc in docs {
                    var data = doc.data()
                    data["id"] = doc.documentID
                    data["tipo_item"] = "ENTRADA"
                    novasTrans.append(data)
                    
                    if (data["status"] as? String) == "CONCLUIDA" {
                        let valor = data["valor_bruto"] as? Double ?? 0.0
                        sTotal += valor
                        if !(data["renuncia_comissao"] as? Bool ?? false) {
                            let perc = (usuario.tipo == "PRIMARIO") ? 0.15 : 0.12
                            sComPessoal += (valor * perc)
                        }
                    }
                }
                self.totalCaptado = sTotal
                self.comissaoPessoal = sComPessoal
                self.transacoesTemp = novasTrans
                unificarEOrdenar()
            }
            
        // Listener de Equipe (Se for Líder)
        if usuario.tipo == "PRIMARIO" {
            listenerEquipe = db.collection("transacoes")
                .whereField("lider_id", isEqualTo: usuario.id)
                .whereField("status", isEqualTo: "CONCLUIDA")
                .addSnapshotListener { snapshot, _ in
                    guard let docs = snapshot?.documents else { return }
                    var sComEquipe = 0.0
                    for doc in docs {
                        let data = doc.data()
                        if (data["captador_id"] as? String) != usuario.id {
                            sComEquipe += ((data["valor_bruto"] as? Double ?? 0.0) * 0.03)
                        }
                    }
                    self.comissaoEquipe = sComEquipe
                }
        }

        // Listener de Saques (Saídas)
        listenerSaques = db.collection("saques")
            .whereField("captador_id", isEqualTo: usuario.id)
            .addSnapshotListener { snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                var novosSaq: [[String: Any]] = []
                for doc in docs {
                    var data = doc.data()
                    data["id"] = doc.documentID
                    data["tipo_item"] = "SAIDA"
                    if let ds = data["data_solicitacao"] { data["data"] = ds }
                    novosSaq.append(data)
                }
                self.saquesTemp = novosSaq
                unificarEOrdenar()
            }
    }
    
    func unificarEOrdenar() {
        let unificada = transacoesTemp + saquesTemp
        self.listaMovimentacoes = unificada.sorted {
            (($0["data"] as? Timestamp)?.dateValue() ?? Date.distantPast) > (($1["data"] as? Timestamp)?.dateValue() ?? Date.distantPast)
        }
        self.carregando = false
    }
    
    func stopListeners() {
        listenerTransacoes?.remove()
        listenerSaques?.remove()
        listenerEquipe?.remove()
    }
}

// MARK: - COMPONENTES AUXILIARES (DENTRO DO ARQUIVO)

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(isSelected ? .white : .gray)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(isSelected ? Color.purple.opacity(0.8) : Color.clear)
                .cornerRadius(10)
                .padding(4)
        }
    }
}

struct CardDoacaoItem: View {
    var dados: [String: Any]
    let greenMoney: Color
    let orangeAction: Color
    let cardBackground: Color
    
    var body: some View {
        let valor = (dados["valor_bruto"] as? NSNumber)?.doubleValue ?? 0.0
        let status = dados["status"] as? String ?? "PENDENTE"
        let cor = status == "CONCLUIDA" ? greenMoney : orangeAction
        
        HStack(spacing: 0) {
            Rectangle().fill(cor).frame(width: 4)
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Doação Recebida").font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                    Text(status).font(.system(size: 10, weight: .black)).foregroundColor(cor)
                }
                Spacer()
                Text("R$ \(String(format: "%.2f", valor))").bold().foregroundColor(cor)
            }.padding(16)
        }.background(cardBackground).cornerRadius(14)
    }
}

struct CardSaqueItem: View {
    var dados: [String: Any]
    let orangeAction: Color
    let cardBackground: Color
    
    var body: some View {
        let valor = (dados["valor_solicitado"] as? NSNumber)?.doubleValue ?? 0.0
        let status = dados["status"] as? String ?? "PENDENTE"
        let cor: Color = (status == "CONCLUIDO" || status == "PAGO") ? .red : orangeAction
        
        HStack(spacing: 0) {
            Rectangle().fill(cor).frame(width: 4)
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Saque Solicitado").font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                    Text(status).font(.system(size: 10, weight: .black)).foregroundColor(cor)
                }
                Spacer()
                Text("- R$ \(String(format: "%.2f", valor))").bold().foregroundColor(cor)
            }.padding(16)
        }.background(cardBackground).cornerRadius(14)
    }
}
