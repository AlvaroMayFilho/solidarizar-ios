import SwiftUI
import FirebaseFirestore

struct PagamentoPixView: View {
    let pixCopiaCola: String
    let qrCodeBase64: String
    let valor: Double
    let asaasId: String
    let usuarioId: String
    
    let onSucesso: () -> Void
    let onCancelar: () -> Void
    
    // --- ESTADOS ---
    @State private var pixCopiado = false
    @State private var pagamentoConfirmado = false
    @State private var listener: ListenerRegistration? = nil
    @State private var animarQr = false

    // Paleta de Cores Oficial
    let pageBackground = Color(red: 0.07, green: 0.10, blue: 0.17) // #121A2C
    let cardBg = Color(red: 0.12, green: 0.16, blue: 0.23)         // #1E293B
    let brandViolet = Color(red: 0.55, green: 0.36, blue: 0.96)    // #8B5CF6
    let brandMagenta = Color(red: 0.85, green: 0.27, blue: 0.94)   // #D946EF
    let greenMoney = Color(red: 0.06, green: 0.73, blue: 0.51)    // #10B981
    let txtGray = Color(red: 0.58, green: 0.64, blue: 0.72)        // #94A3B8

    var mensagemSucesso: String {
        if usuarioId.isEmpty {
            return "O valor já foi repassado para a ONG. Muito obrigado por ajudar!"
        } else {
            return "O valor já foi processado e sua comissão registrada no extrato."
        }
    }

    func converterQrCodeParaImagem() -> UIImage? {
        let cleanBase64 = qrCodeBase64.components(separatedBy: ",").last ?? qrCodeBase64
        guard let data = Data(base64Encoded: cleanBase64) else { return nil }
        return UIImage(data: data)
    }

    var body: some View {
        ZStack {
            pageBackground.ignoresSafeArea()
            
            if !pagamentoConfirmado {
                // --- TELA DE PAGAMENTO (AGUARDANDO) ---
                VStack(spacing: 20) {
                    
                    // Header
                    VStack(spacing: 8) {
                        Capsule()
                            .fill(brandViolet.opacity(0.3))
                            .frame(width: 40, height: 4)
                            .padding(.top, 8)
                        
                        Text("PAGAMENTO VIA PIX")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(brandViolet)
                            .tracking(2)
                            .padding(.top, 10)
                    }

                    // Valor e Status
                    VStack(spacing: 4) {
                        Text("R$ \(String(format: "%.2f", valor))")
                            .font(.system(size: 42, weight: .black))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 8) {
                            ProgressView()
                                .tint(brandViolet)
                                .scaleEffect(0.8)
                            Text("Aguardando confirmação...")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(txtGray)
                        }
                    }
                    .padding(.vertical, 10)

                    // QR Code Container
                    VStack(spacing: 20) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color.white)
                                .shadow(color: brandViolet.opacity(0.2), radius: 20)
                            
                            if let img = converterQrCodeParaImagem() {
                                Image(uiImage: img)
                                    .resizable()
                                    .interpolation(.none)
                                    .scaledToFit()
                                    .padding(20)
                            } else {
                                Image(systemName: "qrcode")
                                    .font(.system(size: 80))
                                    .foregroundColor(.gray.opacity(0.2))
                            }
                        }
                        .frame(width: 260, height: 260)
                        .scaleEffect(animarQr ? 1.0 : 0.95)
                        
                        // Botão Copia e Cola
                        Button(action: {
                            UIPasteboard.general.string = pixCopiaCola
                            withAnimation { pixCopiado = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation { pixCopiado = false }
                            }
                        }) {
                            HStack {
                                Image(systemName: pixCopiado ? "checkmark.circle.fill" : "doc.on.doc.fill")
                                Text(pixCopiado ? "CÓDIGO COPIADO" : "COPIAR CÓDIGO PIX")
                            }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(pixCopiado ? greenMoney : cardBg)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(pixCopiado ? Color.clear : brandViolet.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 40)
                    }

                    Spacer()

                    // Instrução Final
                    Text("Abra o app do seu banco e escolha a opção\n**Pix Copia e Cola** ou escaneie o QR Code.")
                        .font(.system(size: 13))
                        .foregroundColor(txtGray)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)

                    Button(action: onCancelar) {
                        Text("CANCELAR DOAÇÃO")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.red.opacity(0.8))
                            .padding(.bottom, 20)
                    }
                }
                .transition(.opacity)
                
            } else {
                // --- TELA DE SUCESSO (INTEGRADA) ---
                VStack(spacing: 30) {
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .fill(greenMoney.opacity(0.15))
                            .frame(width: 140, height: 140)
                        
                        Circle()
                            .fill(greenMoney)
                            .frame(width: 90, height: 90)
                            .shadow(color: greenMoney.opacity(0.4), radius: 15)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(spacing: 12) {
                        Text("Pagamento Confirmado!")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(mensagemSucesso)
                            .font(.system(size: 16))
                            .foregroundColor(txtGray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    
                    Spacer()
                    
                    Button(action: onSucesso) {
                        Text("CONCLUIR")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(colors: [brandViolet, brandMagenta], startPoint: .leading, endPoint: .trailing)
                            )
                            .cornerRadius(28)
                            .shadow(color: brandViolet.opacity(0.3), radius: 10)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 30)
                }
                .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .opacity))
            }
        }
        .onAppear {
            iniciarOuvinteFirebase()
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                animarQr = true
            }
        }
        .onDisappear {
            listener?.remove()
        }
    }

    // --- LÓGICA DO FIREBASE (MANTIDA INTEGRALMENTE) ---
    func iniciarOuvinteFirebase() {
        guard !asaasId.isEmpty else { return }
        let db = Firestore.firestore()
        listener = db.collection("transacoes")
            .whereField("asaas_id", isEqualTo: asaasId)
            .addSnapshotListener { snapshot, error in
                if let doc = snapshot?.documents.first {
                    let status = doc.get("status") as? String ?? ""
                    if status == "CONCLUIDA" {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                            pagamentoConfirmado = true
                        }
                    }
                }
            }
    }
}
