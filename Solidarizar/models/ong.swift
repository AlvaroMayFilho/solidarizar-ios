import Foundation

struct Ong: Codable, Identifiable {
    var id: String = ""
    var nome: String = ""
    var nome_fantasia: String = ""
    var causa: String = ""
    var descricao: String = ""
    var historia: String = ""
    var imagem_url: String = ""
    var cor: String = "#3B82F6"
    var banners: [String] = []
    var cnpj: String = ""
    var pix: String = ""
    var status: Bool = true
}
