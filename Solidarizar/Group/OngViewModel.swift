import Foundation
import SwiftUI
import Combine // <--- Essa é a biblioteca mágica que faltava para o @Published funcionar!
import FirebaseFirestore

class OngViewModel: ObservableObject {
    @Published var ongs: [Ong] = []
    @Published var carregando: Bool = true
    
    func buscarOngs() {
            let db = Firestore.firestore()
            
            db.collection("ongs")
                .whereField("status", isEqualTo: true)
                .getDocuments { snapshot, error in
                    
                    DispatchQueue.main.async {
                        self.carregando = false
                        
                        if let error = error {
                            print("Erro de conexão: \(error.localizedDescription)")
                            return
                        }
                        
                        guard let documents = snapshot?.documents else { return }
                        
                        // AQUI ESTÁ A MÁGICA: Mapeamento manual à prova de falhas!
                        self.ongs = documents.compactMap { doc -> Ong? in
                            let data = doc.data()
                            
                            return Ong(
                                id: doc.documentID, // Já puxa o ID real do documento
                                nome: data["nome"] as? String ?? "",
                                nome_fantasia: data["nome_fantasia"] as? String ?? "",
                                causa: data["causa"] as? String ?? "",
                                descricao: data["descricao"] as? String ?? "",
                                historia: data["historia"] as? String ?? "",
                                imagem_url: data["imagem_url"] as? String ?? "",
                                cor: data["cor"] as? String ?? "#3B82F6",
                                banners: data["banners"] as? [String] ?? [],
                                cnpj: data["cnpj"] as? String ?? "",
                                pix: data["pix"] as? String ?? "",
                                status: data["status"] as? Bool ?? true
                            )
                        }
                    }
                }
        }
    }
