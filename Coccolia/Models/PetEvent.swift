import Foundation

struct PetEvent: Identifiable, Codable, Hashable {
    enum Category: String, Codable, CaseIterable, Identifiable {
        case vaccine = "Vaccino"
        case medication = "Farmaco"
        case vet = "Visita veterinaria"
        case grooming = "Toelettatura"
        case custom = "Altro"
        var id: String { rawValue }
        var symbol: String {
            switch self {
            case .vaccine: return "syringe"
            case .medication: return "pill.fill"
            case .vet: return "stethoscope"
            case .grooming: return "scissors"
            case .custom: return "calendar.badge.plus"
            }
        }
    }

    var id: UUID = UUID()
    var petID: UUID
    var title: String
    var category: Category
    var date: Date
    var notes: String
    var reminderEnabled: Bool
}
