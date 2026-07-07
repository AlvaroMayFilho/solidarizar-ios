import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct MinhasDoacoesView: View {
    @Environment(\.openURL) var openURL
    
    // --- PROPRIEDADES ---
    var usuario: Usuario? = nil
    var onVoltar: () -> Void
    var emailRecente: String
    var onSouCaptadorClick: () -> Void
    var onIrParaHome: () -> Void // <--- Parâmetro de navegação
    
    // --- ESTADOS ---
    @State private var estagio: String = "login"
    @State private var emailInput: String = ""
    @State private var minhasDoacoes: [Doacao] = []
    @State private var carregando = false
    @State private var mostrarAlertaCancelamento = false
    @State private var doacaoParaCancelar: Doacao? = nil
    @State private var mostrarAlertaErro = false
    @State private var mensagemErro = ""
    
    // --- PALETA PREMIUM ---
    let pageBackground = Color(red: 0.07, green: 0.10, blue: 0.17)
    let cardBg = Color(red: 0.12, green: 0.16, blue: 0.23)
    let brandViolet = Color(red: 0.55, green: 0.36, blue: 0.96)
    let brandMagenta = Color(red: 0.85, green: 0.27, blue: 0.94)
    let brandOrange = Color(red: 0.96, green: 0.62, blue: 0.04)
    let statusGreen = Color(red: 0.06, green: 0.73, blue: 0.51)
    let statusRed = Color(red: 0.94, green: 0.27, blue: 0.27)
    let txtWhite = Color(red: 0.97, green: 0.98, blue: 0.99)
    let txtGray = Color(red: 0.58, green: 0.64, blue: 0.72)
    
    // --- LÓGICA DE DADOS ---
    var totalDoado: Double {
        minhasDoacoes.filter { $0.status.lowercased() == "concluida" || $0.status.lowercased() == "ativa" }.reduce(0) { $0 + $1.valor }
    }

    var nomeExibicao: String {
        let nome = usuario?.nome.components(separatedBy: " ").first ?? "Doador"
        return "Olá, \(nome)"
    }

    var inicialAvatar: String {
        String(nomeExibicao.replacingOccurrences(of: "Olá, ", with: "").prefix(1)).uppercased()
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.09, green: 0.05, blue: 0.15), pageBackground], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Button(action: onVoltar) {
                        Image(systemName: "chevron.left").font(.system(size: 20, weight: .semibold)).foregroundColor(.white).padding()
                    }
                    Spacer()
                    Text("Área do Doador").font(.headline).foregroundColor(txtWhite)
                    Spacer()
                    if estagio == "lista" {
                        Button(action: fazerLogout) {
                            Image(systemName: "power").foregroundColor(statusRed).padding()
                        }
                    } else { Spacer().frame(width: 44) }
                }.padding(.top, 10)
                
                if estagio == "login" { telaLogin } else { telaLista }
            }
        }
        .onAppear {
            if let user = usuario {
                self.emailInput = user.email
                self.estagio = "lista"
                buscarDoacoes(email: user.email)
            } else if !emailRecente.isEmpty {
                self.emailInput = emailRecente
                self.estagio = "lista"
                buscarDoacoes(email: emailRecente)
            }
        }
    }
    
    @ViewBuilder
    private var telaLogin: some View {
        ScrollView {
            VStack {
                Spacer().frame(height: 60)
                Image(systemName: "envelope.open.fill").foregroundColor(brandViolet).font(.system(size: 48))
                Text("Gerencie suas doações").font(.title2).bold().foregroundColor(txtWhite).padding(.top)
                HStack {
                    Image(systemName: "envelope.fill").foregroundColor(txtGray)
                    TextField("Seu E-mail", text: $emailInput).foregroundColor(txtWhite).keyboardType(.emailAddress).autocapitalization(.none)
                }.padding().background(cardBg).cornerRadius(12).padding(24)
                
                Button(action: { buscarDoacoes(email: emailInput) }) {
                    Text("ACESSAR HISTÓRICO").bold().frame(maxWidth: .infinity).frame(height: 56).background(LinearGradient(colors: [brandViolet, brandMagenta], startPoint: .leading, endPoint: .trailing)).foregroundColor(.white).cornerRadius(18)
                }.padding(.horizontal, 24).disabled(carregando || emailInput.isEmpty)
                
                Button(action: onSouCaptadorClick) {
                    Text("Sou membro da equipe / Captador").foregroundColor(txtGray).padding(.top, 40)
                }
            }
        }
    }
    
    @ViewBuilder
    private var telaLista: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(spacing: 16) {
                    Circle().fill(LinearGradient(colors: [brandViolet, brandMagenta], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 80, height: 80)
                        .overlay(Text(inicialAvatar).font(.system(size: 32, weight: .heavy)).foregroundColor(.white))
                    Text(nomeExibicao).font(.title2).bold().foregroundColor(txtWhite)
                }.padding(.vertical, 24)
                
                HStack(spacing: 16) {
                    VStack(alignment: .leading) {
                        Text("Total").font(.caption).foregroundColor(txtGray)
                        Text("R$ \(String(format: "%.2f", totalDoado).replacingOccurrences(of: ".", with: ","))").bold().foregroundColor(txtWhite)
                    }.padding(16).frame(maxWidth: .infinity, alignment: .leading).background(cardBg).cornerRadius(16)
                    
                    VStack(alignment: .leading) {
                        Text("Apoios").font(.caption).foregroundColor(txtGray)
                        Text("\(minhasDoacoes.count)").bold().foregroundColor(txtWhite)
                    }.padding(16).frame(maxWidth: .infinity, alignment: .leading).background(cardBg).cornerRadius(16)
                }.padding(.horizontal, 24).padding(.bottom, 24)
                
                VStack(spacing: 16) {
                    if usuario?.tipo == "PRIMARIO" || usuario?.tipo == "SECUNDARIO" {
                        MenuRowView(icon: "chart.bar.fill", title: "Central de Arrecadação", subtitle: "Acesse seu painel", iconColor: brandOrange, cardBg: cardBg, txtWhite: txtWhite, txtGray: txtGray) {
                            onIrParaHome()
                        }
                    }
                    MenuRowView(icon: "list.bullet.rectangle", title: "Histórico", subtitle: "Suas contribuições", iconColor: brandViolet, cardBg: cardBg, txtWhite: txtWhite, txtGray: txtGray) { }
                    MenuRowView(icon: "arrow.right.square", title: "Sair", subtitle: "Encerrar sessão", iconColor: statusRed, cardBg: cardBg, txtWhite: txtWhite, txtGray: txtGray) { fazerLogout() }
                    MenuRowView(icon: "trash.fill", title: "Excluir Conta", subtitle: "Apagar dados permanentemente", iconColor: statusRed, cardBg: cardBg, txtWhite: txtWhite, txtGray: txtGray) {
                        if let url = URL(string: "https://solidarizar.com.br/excluir-conta") {
                            openURL(url)
                        }
                    }
                }.padding(.horizontal, 24)
                
                LazyVStack(spacing: 16) {
                    ForEach(minhasDoacoes) { doacao in
                        CardDoacaoRealView(doacao: doacao, colors: (cardBg, brandViolet, statusGreen, statusRed, txtWhite, txtGray)) {
                            self.doacaoParaCancelar = doacao
                            self.mostrarAlertaCancelamento = true
                        }
                    }
                }.padding(24)
            }
        }
    }

    func buscarDoacoes(email: String) {
        carregando = true
        Firestore.firestore().collection("transacoes").whereField("email_doador", isEqualTo: email.trimmingCharacters(in: .whitespacesAndNewlines)).getDocuments { snap, _ in
            if let docs = snap?.documents {
                self.minhasDoacoes = docs.compactMap { try? $0.data(as: Doacao.self) }
                self.minhasDoacoes.sort { $0.data > $1.data }
            }
            self.carregando = false
            withAnimation { self.estagio = "lista" }
        }
    }
    
    func fazerLogout() {
        // Ao executar o signOut, o Listener Global do SolidarizarApp toma conta do redirecionamento
        // e joga o usuário imediatamente para a tela "welcome", evitando bugs de rotas duplas.
        try? Auth.auth().signOut()
        withAnimation { estagio = "login"; emailInput = ""; minhasDoacoes = [] }
    }
    
    func confirmarCancelamento() {
        guard let id = doacaoParaCancelar?.id else { return }
        Firestore.firestore().collection("transacoes").document(id).updateData(["status": "Cancelada"]) { _ in buscarDoacoes(email: emailInput) }
    }
}

// MARK: - COMPONENTES
struct MenuRowView: View {
    var icon: String; var title: String; var subtitle: String; var iconColor: Color; var cardBg: Color; var txtWhite: Color; var txtGray: Color; var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon).foregroundColor(iconColor).frame(width: 40, height: 40).background(cardBg).cornerRadius(10)
                VStack(alignment: .leading) {
                    Text(title).bold().foregroundColor(txtWhite)
                    Text(subtitle).font(.caption).foregroundColor(txtGray)
                }
                Spacer()
            }.padding().background(cardBg).cornerRadius(16).overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.05), lineWidth: 1))
        }
    }
}

struct CardDoacaoRealView: View {
    var doacao: Doacao
    var colors: (cardBg: Color, violet: Color, green: Color, red: Color, txtWhite: Color, txtGray: Color)
    var onCancelarClick: () -> Void
    var body: some View {
        let isAtiva = doacao.status.lowercased() == "concluida" || doacao.status.lowercased() == "ativa" || doacao.status.lowercased() == "confirmada"
        let statusColor = isAtiva ? colors.green : colors.red
        HStack(spacing: 0) {
            Rectangle().fill(doacao.recorrente ? colors.violet : statusColor).frame(width: 5)
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading) {
                        Text(doacao.ongNome).bold().foregroundColor(colors.txtWhite)
                        Text(doacao.recorrente ? "Assinatura Mensal" : "Doação Única").font(.caption).foregroundColor(colors.txtGray)
                    }
                    Spacer()
                    Text(doacao.status.uppercased()).font(.system(size: 10, weight: .bold)).foregroundColor(statusColor).padding(4).background(statusColor.opacity(0.1)).cornerRadius(4)
                }
                Divider().background(Color.white.opacity(0.05))
                HStack {
                    Text("R$ \(String(format: "%.2f", doacao.valor).replacingOccurrences(of: ".", with: ","))").bold().foregroundColor(colors.txtWhite)
                    Spacer()
                    if isAtiva && doacao.recorrente {
                        Button(action: onCancelarClick) { Text("Cancelar").font(.caption2).bold().foregroundColor(colors.red).padding(6).overlay(RoundedRectangle(cornerRadius: 4).stroke(colors.red, lineWidth: 1)) }
                    } else { Text(formatarData(doacao.data)).font(.caption).foregroundColor(colors.txtGray) }
                }
            }.padding(16)
        }
        .background(colors.cardBg).cornerRadius(16).overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.05), lineWidth: 1))
    }
    func formatarData(_ data: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: data)
    }
}
