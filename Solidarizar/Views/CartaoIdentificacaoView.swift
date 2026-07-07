import SwiftUI
import CoreImage.CIFilterBuiltins

struct CartaoIdentificacaoView: View {
    let usuario: Usuario
    let ong: Ong?
    
    @State private var virado = false
    @State private var imagemGerada: Image? = nil
    @State private var mostrarPreviewSimulador = false // Variável para o truque do simulador
    
    // --- DADOS PARA O COMPARTILHAMENTO ---
    var urlDoacao: String {
        "https://solidarizar.com.br/doar/\(usuario.id)"
    }
    
    var mensagemCompartilhamento: String {
        let nomeInstituicao = ong?.nome ?? "nossa causa"
        let descricao = ong?.descricao ?? "Faça a diferença na vida de quem precisa."
        
        return "Apoie a \(nomeInstituicao)!\n\n\(descricao)\n\nFaça sua doação rápida e segura acessando o link oficial ou escaneando meu crachá:\n\(urlDoacao)"
    }
    
    var body: some View {
        VStack(spacing: 20) {
            
            Spacer().frame(height: 20)
            
            // --- CONTAINER DO CRACHÁ (FLIP ANIMADO) ---
            ZStack {
                Group {
                    if !virado {
                        FrenteCracha(usuario: usuario)
                    } else {
                        VersoCracha(usuario: usuario, ong: ong, urlDoacao: urlDoacao)
                            .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                    }
                }
                .transition(.opacity) // Transição suave
                .onTapGesture {
                    // 👇 FEEDBACK TÁTIL (Toque Leve) 👇
                    let gerador = UIImpactFeedbackGenerator(style: .light)
                    gerador.impactOccurred()
                    
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                        virado.toggle()
                    }
                }
            }
            .rotation3DEffect(.degrees(virado ? 180 : 0), axis: (x: 0, y: 1, z: 0))
            .shadow(color: .black.opacity(0.15), radius: 25, x: 0, y: 15) // Sombra premium flutuante
            
            Spacer()
            
            // --- BOTÃO DE COMPARTILHAMENTO E DEBUG ---
            if let imagem = imagemGerada {
                ShareLink(
                    item: imagem,
                    subject: Text("Apoie nossa causa!"),
                    message: Text(mensagemCompartilhamento),
                    preview: SharePreview("Crachá Digital", image: imagem)
                ) {
                    HStack(spacing: 12) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 20, weight: .bold))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Compartilhar Crachá")
                                .font(.system(size: 16, weight: .bold))
                            Text("Enviar imagem única no WhatsApp")
                                .font(.system(size: 12))
                                .opacity(0.8)
                        }
                    }
                    .padding()
                    .frame(maxWidth: 320)
                    .background(LinearGradient(colors: [Color(red: 0.30, green: 0.11, blue: 0.58), Color(red: 0.85, green: 0.27, blue: 0.94)], startPoint: .leading, endPoint: .trailing))
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .shadow(color: Color.purple.opacity(0.4), radius: 10, x: 0, y: 5)
                }
                .padding(.bottom, 5)
                
                // 👇 TRUQUE PARA O SIMULADOR 👇
                #if targetEnvironment(simulator)
                Button {
                    // Feedback tátil médio para o botão
                    let gerador = UIImpactFeedbackGenerator(style: .medium)
                    gerador.impactOccurred()
                    
                    mostrarPreviewSimulador = true
                } label: {
                    Text("👁️ Ver Imagem Gerada (Debug)")
                        .font(.caption)
                        .bold()
                        .foregroundColor(.blue)
                        .padding(.bottom, 20)
                }
                .sheet(isPresented: $mostrarPreviewSimulador) {
                    VStack {
                        Text("Preview da arte para o WhatsApp:")
                            .font(.headline)
                            .padding()
                        
                        imagem
                            .resizable()
                            .scaledToFit()
                            .border(Color.gray.opacity(0.3), width: 1)
                            .padding()
                        
                        Button("Fechar Preview") {
                            mostrarPreviewSimulador = false
                        }
                        .padding()
                    }
                }
                #endif
                // 👆 FIM DO TRUQUE 👆
                
            } else {
                ProgressView("Gerando arquivo de alta qualidade...")
                    .padding(.bottom, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.95, green: 0.95, blue: 0.97).ignoresSafeArea())
        .onAppear {
            // Pequeno delay para garantir que as fontes/imagens renderizem antes da foto
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                gerarImagemParaCompartilhar()
            }
        }
    }
    
    // MARK: - GERA A IMAGEM ÚNICA (FRENTE + VERSO LADO A LADO)
    @MainActor
    private func gerarImagemParaCompartilhar() {
        // Cria uma View invisível com as duas partes lado a lado
        let viewExportacao = CrachaExportView(usuario: usuario, ong: ong, urlDoacao: urlDoacao)
            .frame(width: 720, height: 580) // Tamanho generoso para a imagem final
        
        let renderer = ImageRenderer(content: viewExportacao)
        renderer.scale = 4.0 // Scale 4.0 = Qualidade absurda (tipo 4K), texto não borra no zap
        
        if let uiImage = renderer.uiImage {
            self.imagemGerada = Image(uiImage: uiImage)
            
            // 👇 FEEDBACK TÁTIL (Sucesso ao gerar a imagem) 👇
            let geradorSucesso = UINotificationFeedbackGenerator()
            geradorSucesso.notificationOccurred(.success)
        }
    }
}

// MARK: - VIEW SECRETA (FRENTE E VERSO LADO A LADO PARA O WHATSAPP)
struct CrachaExportView: View {
    let usuario: Usuario
    let ong: Ong?
    let urlDoacao: String
    
    var body: some View {
        HStack(spacing: 40) {
            FrenteCracha(usuario: usuario)
            VersoCracha(usuario: usuario, ong: ong, urlDoacao: urlDoacao)
        }
        .padding(40)
        .background(Color(red: 0.95, green: 0.95, blue: 0.97)) // Fundo cinza claro para as bordas brancas destacarem
    }
}

// MARK: - FRENTE DO CRACHÁ
struct FrenteCracha: View {
    let usuario: Usuario
    let bgCorApp = Color(red: 0.95, green: 0.95, blue: 0.97)
    
    var body: some View {
        VStack(spacing: 0) {
            // --- HEADER COM FOTO ALINHADA ---
            ZStack(alignment: .bottom) {
                // Fundo Roxo Premium
                LinearGradient(colors: [Color(red: 0.30, green: 0.11, blue: 0.58), Color(red: 0.85, green: 0.27, blue: 0.94)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .frame(height: 140)
                    .clipShape(CustomHeaderShape()) // Corte curvo elegante
                
                // Textos do Topo
                VStack(spacing: 4) {
                    // O "furo" do cordão do crachá
                    Capsule()
                        .fill(bgCorApp)
                        .frame(width: 60, height: 12)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                        .padding(.top, -10)
                        .padding(.bottom, 10)
                    
                    Text("SOLIDARIZAR")
                        .font(.system(size: 16, weight: .black))
                        .foregroundColor(.white)
                        .tracking(3)
                    Text("Conectando você a quem precisa")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.bottom, 75)
                
                // Foto do Usuário
                if let img = converterBase64(usuario.foto_url) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 110, height: 110)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 5))
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                        .offset(y: 55)
                } else {
                    Image(systemName: "person.fill")
                        .resizable()
                        .scaledToFit()
                        .padding(25)
                        .frame(width: 110, height: 110)
                        .foregroundColor(.gray.opacity(0.5))
                        .background(Color.white)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 5))
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                        .offset(y: 55)
                }
            }
            .padding(.bottom, 65)
            
            // --- INFORMAÇÕES DO CAPTADOR ---
            VStack(spacing: 6) {
                // Nome + Selo Verificado
                HStack(spacing: 6) {
                    Text(usuario.nome.uppercased())
                        .font(.system(size: 20, weight: .black))
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 18))
                }
                .padding(.horizontal, 16)
                
                // Cargo
                Text(usuario.cargo.uppercased())
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(red: 0.30, green: 0.11, blue: 0.58))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(8)
                
                Spacer().frame(height: 15)
                
                // Box de Identificação
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("IDENTIFICAÇÃO (ID)")
                            .font(.system(size: 8, weight: .black))
                            .foregroundColor(.gray)
                        Text(usuario.id)
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .lineLimit(1)
                            .minimumScaleFactor(0.4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color(red: 0.96, green: 0.96, blue: 0.98))
                    .cornerRadius(12)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("VALIDADE")
                            .font(.system(size: 8, weight: .black))
                            .foregroundColor(.gray)
                        Text(usuario.data_validade.isEmpty ? "12/2026" : usuario.data_validade)
                            .font(.system(size: 11, weight: .black))
                            .lineLimit(1)
                    }
                    .padding(12)
                    .background(Color(red: 0.96, green: 0.96, blue: 0.98))
                    .cornerRadius(12)
                }
                .padding(.horizontal, 24)
            }
            
            Spacer()
            
            // Rodapé
            HStack(spacing: 6) {
                Image(systemName: "arrow.triangle.2.circlepath")
                Text("Crachá Oficial • Toque para virar")
            }
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.gray.opacity(0.5))
            .padding(.bottom, 20)
        }
        .frame(width: 320, height: 500)
        .background(Color.white)
        .cornerRadius(24)
    }
    
    private func converterBase64(_ str: String) -> UIImage? {
        let clean = str.components(separatedBy: ",").last ?? str
        guard let data = Data(base64Encoded: clean) else { return nil }
        return UIImage(data: data)
    }
}

// MARK: - VERSO DO CRACHÁ
struct VersoCracha: View {
    let usuario: Usuario
    let ong: Ong?
    let urlDoacao: String
    let bgCorApp = Color(red: 0.95, green: 0.95, blue: 0.97)
    
    var body: some View {
        VStack(spacing: 20) {
            
            // Furo do cordão (verso)
            Capsule()
                .fill(bgCorApp)
                .frame(width: 60, height: 12)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                .padding(.top, 25)
            
            Text("DOE COM SEGURANÇA")
                .font(.system(size: 14, weight: .black))
                .foregroundColor(Color(red: 0.30, green: 0.11, blue: 0.58))
                .padding(.top, 5)
            
            // QR CODE (Agora com uma borda bonita)
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: .purple.opacity(0.2), radius: 10, x: 0, y: 5)
                    .frame(width: 160, height: 160)
                
                Image(uiImage: gerarQRCode(da: urlDoacao))
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140, height: 140)
            }
            
            VStack(alignment: .leading, spacing: 14) {
                // Instituição com Selo de Verificado
                VStack(alignment: .leading, spacing: 4) {
                    Text("INSTITUIÇÃO BENEFICIADA").font(.system(size: 9, weight: .black)).foregroundColor(.gray)
                    HStack(spacing: 4) {
                        Text(ong?.nome ?? "Associação Parceira")
                            .font(.system(size: 14, weight: .black))
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 12))
                    }
                }
                
                InfoVersoItem(label: "CNPJ OFICIAL", valor: ong?.cnpj ?? "00.000.000/0001-00")
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("CÓDIGO DA INSTITUIÇÃO (ONG ID)")
                            .font(.system(size: 8, weight: .black))
                            .foregroundColor(.gray)
                        Text(usuario.ongId)
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(6)
                    }
                    
                    Spacer()
                    
                    // Membro Desde puxando a data de cadastro do usuário (corrigido para Date?)
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("MEMBRO DESDE")
                            .font(.system(size: 8, weight: .black))
                            .foregroundColor(.gray)
                        Text(formatarDataCadastro(usuario.data_cadastro))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color(red: 0.30, green: 0.11, blue: 0.58))
                    }
                }
            }
            .padding(.horizontal, 30)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            // Caixa de Aviso
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.shield.fill")
                    Text("ATENÇÃO")
                }
                .font(.system(size: 10, weight: .black))
                .foregroundColor(.red)
                
                Text("As doações devem ser realizadas exclusivamente escaneando o QR Code ou pelo link oficial da plataforma.")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .padding(12)
            .background(Color.red.opacity(0.05))
            .cornerRadius(12)
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .frame(width: 320, height: 500)
        .background(Color.white)
        .cornerRadius(24)
    }
    
    private func gerarQRCode(da string: String) -> UIImage {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        
        if let outputImage = filter.outputImage {
            if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
                return UIImage(cgImage: cgimg)
            }
        }
        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
    
    // Função auxiliar CORRIGIDA para formatar a data de cadastro (aceita Date?)
    private func formatarDataCadastro(_ dataObject: Date?) -> String {
        // Se a data vier nula do banco, retorna um valor padrão
        guard let date = dataObject else { return "2024" }
        
        let outFormatter = DateFormatter()
        outFormatter.locale = Locale(identifier: "pt_BR")
        outFormatter.dateFormat = "MMM yyyy" // Ex: "mar 2024"
        return outFormatter.string(from: date).capitalized
    }
}

// Subcomponente do Verso
struct InfoVersoItem: View {
    let label: String
    let valor: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.system(size: 9, weight: .black)).foregroundColor(.gray)
            Text(valor).font(.system(size: 14, weight: .black)).foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
        }
    }
}

// Formato curvo elegante para o fundo roxo da frente
struct CustomHeaderShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height - 30))
        path.addQuadCurve(to: CGPoint(x: 0, y: rect.height - 30), control: CGPoint(x: rect.width / 2, y: rect.height + 15))
        path.addLine(to: CGPoint(x: 0, y: 0))
        return path
    }
}
