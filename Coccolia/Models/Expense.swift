import Foundation

struct Expense: Identifiable, Codable, Hashable {
    enum Category: String, Codable, CaseIterable, Identifiable {
        case veterinary = "Veterinario"
        case food = "Alimentazione"
        case medicine = "Farmaci"
        case grooming = "Toelettatura"
        case accessories = "Accessori"
        case other = "Altro"
        var id: String { rawValue }
    }

    var id: UUID = UUID()
    var petID: UUID?
    var category: Category
    var amount: Double
    var date: Date
    var note: String
}
