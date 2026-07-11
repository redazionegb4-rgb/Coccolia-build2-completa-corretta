import Foundation

struct PetDocument: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var petID: UUID
    var title: String
    var type: String
    var createdAt: Date
    var fileName: String
}
