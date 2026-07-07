import Foundation
import FirebaseFirestore

struct Usuario: Codable {
    var id: String = ""
    var nome: String = ""
    var cpf: String = ""
    var email: String = ""
    
    // Obrigatório na sua lógica de negócio!
    var ongId: String = ""
    
    var liderId: String? = nil
    var statusPromocao: String = "NEUTRO"
    var data_cadastro: Date? = nil
    var tipo: String = "SECUNDARIO"
    var saldo_virtual: Double = 0.0
    
    // --- NOVOS CAMPOS PARA O CRACHÁ DIGITAL ---
    var cargo: String = "Captador Voluntário"
    var id_voluntario: String = ""
    var data_validade: String = ""
    var foto_url: String = ""

    enum CodingKeys: String, CodingKey {
        case id
        case nome
        case cpf
        case email
        case ongId
        case liderId
        case statusPromocao
        case data_cadastro
        case tipo
        case saldo_virtual
        
        // Mapeamento dos novos campos
        case cargo
        case id_voluntario
        case data_validade
        case foto_url
    }
    
    // --- A MÁGICA PARA O SWIFT AGIR IGUAL AO KOTLIN ---
    // Se a chave não vier do Firebase, ele usa o valor padrão em vez de travar o app.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? ""
        self.nome = try container.decodeIfPresent(String.self, forKey: .nome) ?? ""
        self.cpf = try container.decodeIfPresent(String.self, forKey: .cpf) ?? ""
        self.email = try container.decodeIfPresent(String.self, forKey: .email) ?? ""
        
        // Garante que o ongId seja String (nunca nulo), mas evita o crash se o banco falhar
        self.ongId = try container.decodeIfPresent(String.self, forKey: .ongId) ?? ""
        
        self.liderId = try container.decodeIfPresent(String.self, forKey: .liderId)
        self.statusPromocao = try container.decodeIfPresent(String.self, forKey: .statusPromocao) ?? "NEUTRO"
        self.data_cadastro = try container.decodeIfPresent(Date.self, forKey: .data_cadastro)
        self.tipo = try container.decodeIfPresent(String.self, forKey: .tipo) ?? "SECUNDARIO"
        self.saldo_virtual = try container.decodeIfPresent(Double.self, forKey: .saldo_virtual) ?? 0.0
        
        // Decodificação dos novos campos com valores padrão de segurança
        self.cargo = try container.decodeIfPresent(String.self, forKey: .cargo) ?? "Captador Voluntário"
        self.id_voluntario = try container.decodeIfPresent(String.self, forKey: .id_voluntario) ?? "---"
        self.data_validade = try container.decodeIfPresent(String.self, forKey: .data_validade) ?? "--/----"
        self.foto_url = try container.decodeIfPresent(String.self, forKey: .foto_url) ?? ""
    }
    
    // Construtor vazio padrão para podermos criar instâncias zeradas no código se precisar
    init() {}
}
