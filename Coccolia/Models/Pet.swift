import Foundation

struct Pet: Identifiable, Codable, Hashable {
    enum Sex: String, Codable, CaseIterable, Identifiable {
        case male = "Maschio"
        case female = "Femmina"
        case unknown = "Non so"
        var id: String { rawValue }
    }

    var id: UUID = UUID()
    var name: String
    var species: String
    var breed: String
    var sex: Sex
    var birthDate: Date?
    var weight: Double?
    var microchip: String
    var mainColor: String
    var distinctiveFeatures: String
    var allergies: String
    var notes: String
    var photoData: Data?

    static let sample = Pet(
        name: "Milo",
        species: "Cane",
        breed: "Golden Retriever",
        sex: .male,
        birthDate: Calendar.current.date(byAdding: .year, value: -3, to: Date()),
        weight: 28.4,
        microchip: "",
        mainColor: "Dorato",
        distinctiveFeatures: "Macchia chiara sul petto",
        allergies: "",
        notes: "Ama giocare con la pallina",
        photoData: nil
    )
}
