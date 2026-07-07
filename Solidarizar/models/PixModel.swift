import Foundation

// --- MODELOS DE DADOS (Equivalente ao data class) ---

struct PixRequest: Codable {
    let valor: Double
    let cpf_doador: String
    let nome_doador: String
    let captador_id: String
    let captador_nome: String
    let ong_id: String
    let lider_id: String
}

struct PixResponse: Codable {
    let sucesso: Bool
    let imagem_base64: String
    let copia_cola: String
    let id_transacao_asaas: String
}
