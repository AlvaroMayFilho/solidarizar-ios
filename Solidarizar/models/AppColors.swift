import SwiftUI

// Uma extensão para o Swift aprender as suas cores do Figma/Android
extension Color {
    // --- CORES PERSONALIZADAS DO ONGSPLIT ---
    static let darkBackground = Color(red: 0.07, green: 0.10, blue: 0.17) // #121A2C
    static let cardBackground = Color(red: 0.12, green: 0.16, blue: 0.23) // #1E293B
    static let textWhite      = Color(red: 0.97, green: 0.98, blue: 0.99) // #F8FAFC
    static let textGray       = Color(red: 0.58, green: 0.64, blue: 0.72) // #94A3B8
    static let greenMoney     = Color(red: 0.06, green: 0.73, blue: 0.51) // #10B981
    static let purpleAction   = Color(red: 0.55, green: 0.36, blue: 0.96) // #8B5CF6
    static let orangeAction   = Color(red: 0.96, green: 0.62, blue: 0.04) // #F59E0B
    
    static let localPurpleDark = Color(red: 0.30, green: 0.11, blue: 0.58) // #4C1D95
    static let localMagenta    = Color(red: 0.85, green: 0.27, blue: 0.94) // #D946EF
    
    // Função mágica para ler a cor "#Hex" que vem do banco de dados (ong.cor)
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6: // RGB (24-bit)
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (1, 1, 1)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: 1
        )
    }
}
