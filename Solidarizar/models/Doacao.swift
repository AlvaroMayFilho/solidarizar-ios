import Foundation
import FirebaseFirestore

struct Doacao: Codable, Identifiable {
    var id: String = "" // O ID do documento
    var ongNome: String = ""
    var valor: Double = 0.0
    var status: String = "PENDENTE" // Começa como pendente no Pix
    var data: Date = Date()
    var emailDoador: String = ""
    var cpfDoador: String = ""
    var recorrente: Bool = false
    var metodo: String = ""
    
    // --- NOVOS CAMPOS PARA AUTOMATIZAÇÃO E MONITORAMENTO ---
    var captadorId: String = ""
    var asaasId: String = ""
    
    // Mapeamento exato com o seu Banco de Dados Firebase
    enum CodingKeys: String, CodingKey {
        case id
        case status
        case data
        case recorrente
        case metodo
        case ongNome = "ong_nome"
        case valor = "valor_bruto" // Mantendo seu padrão de banco
        case emailDoador = "email_doador"
        case cpfDoador = "cpf_doador"
        case captadorId = "captador_id"
        case asaasId = "asaas_id"
    }
}
