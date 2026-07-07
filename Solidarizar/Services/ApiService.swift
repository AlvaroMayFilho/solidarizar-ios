import Foundation

// ==========================================
// MODELOS DE DADOS PARA LOGIN
// ==========================================
struct LoginApiRequest: Codable {
    let email: String
    let senha: String
}

struct LoginApiResponse: Codable {
    let sucesso: Bool
    let mensagem: String?
    let tipo: String?
    let ong_id: String?
    let token: String? // O "Crachá Vip" que vem do Python
}

// ==========================================
// MODELOS DE DADOS PARA SAQUE
// ==========================================
struct SaqueRequest: Codable {
    let captador_id: String
    let cpf_chave_pix: String
    let valor_solicitado: Double
}

struct SaqueResponse: Codable {
    let sucesso: Bool
    let mensagem: String
}

// ==========================================
// SEGURANÇA: DELEGATE PARA CERTIFICADOS SSL
// ==========================================
class InsecureSessionDelegate: NSObject, URLSessionDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

// ==========================================
// SERVICE: API PRINCIPAL
// ==========================================
class ApiService {
    
    // CORREÇÃO 1: Removido o "www." para bater com o servidor e evitar redirecionamento (perda de Body)
    private let baseURL = "https://solidarizar.com.br/api"
    
    static let shared = ApiService()
    
    private var session: URLSession
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 30
        
        let delegate = InsecureSessionDelegate()
        self.session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
    }
    
    // --- FUNÇÃO DE LOGIN VIA API (COM CUSTOM TOKEN) ---
    func loginApp(request: LoginApiRequest) async throws -> LoginApiResponse {
        // Usa a baseURL + /login para bater em https://solidarizar.com.br/api/login
        guard let url = URL(string: "\(baseURL)/login") else {
            throw URLError(.badURL)
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        // Se for 401 (Não autorizado), a API devolve um JSON válido com "sucesso: false" e "mensagem"
        if httpResponse.statusCode == 401 {
            return try JSONDecoder().decode(LoginApiResponse.self, from: data)
        }
        
        if httpResponse.statusCode != 200 {
            let erroDoPython = String(data: data, encoding: .utf8) ?? "Erro desconhecido"
            print("🔥 O BACKEND RECUSOU O LOGIN (Status \(httpResponse.statusCode)): \(erroDoPython)")
            throw URLError(.badServerResponse)
        }
        
        do {
            return try JSONDecoder().decode(LoginApiResponse.self, from: data)
        } catch {
            print("🔥 ERRO DE LEITURA DO JSON NO LOGIN: \(error)")
            throw error
        }
    }

    // --- FUNÇÃO 1: CRIAR PIX ---
    func criarPix(request: PixRequest) async throws -> PixResponse {
        guard let url = URL(string: "\(baseURL)/criar_pix") else {
            throw URLError(.badURL)
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)
        
        let (data, response) = try await session.data(for: urlRequest)
        
        // CORREÇÃO 2: Dedo-duro do Erro do Backend
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if httpResponse.statusCode != 200 {
            // Se o Python reclamar, vai aparecer gigante no console do Xcode!
            let erroDoPython = String(data: data, encoding: .utf8) ?? "Erro desconhecido"
            print("🔥 O BACKEND RECUSOU A REQUISIÇÃO (Status \(httpResponse.statusCode)): \(erroDoPython)")
            throw URLError(.badServerResponse)
        }
        
        do {
            return try JSONDecoder().decode(PixResponse.self, from: data)
        } catch {
            // CORREÇÃO 3: Dedo-duro do JSON Swift
            print("🔥 ERRO DE LEITURA DO JSON: O Swift não conseguiu ler a resposta porque uma variável não bateu. Detalhe: \(error)")
            throw error
        }
    }
    
    // --- FUNÇÃO 2: SOLICITAR SAQUE ---
    func solicitarSaque(request: SaqueRequest) async throws -> SaqueResponse {
        guard let url = URL(string: "\(baseURL)/captador/solicitar_saque") else {
            throw URLError(.badURL)
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)
        
        let (data, response) = try await session.data(for: urlRequest)
        
        do {
            return try JSONDecoder().decode(SaqueResponse.self, from: data)
        } catch {
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                let erroSaque = String(data: data, encoding: .utf8) ?? "Erro desconhecido"
                print("🔥 ERRO NO SAQUE: \(erroSaque)")
                throw URLError(.badServerResponse)
            }
            throw error
        }
    }
}
