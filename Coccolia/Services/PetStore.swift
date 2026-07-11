import Foundation
import SwiftUI

struct UserProfile: Codable, Hashable {
    var firstName: String
    var lastName: String
    var email: String
    var acceptedPrivacy: Bool
    var createdAt: Date

    var displayName: String {
        let trimmed = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Amico" : trimmed
    }
}

@MainActor
final class PetStore: ObservableObject {
    @Published var profile: UserProfile? { didSet { save() } }
    @Published var pets: [Pet] = [] { didSet { save() } }
    @Published var events: [PetEvent] = [] { didSet { save() } }
    @Published var expenses: [Expense] = [] { didSet { save() } }
    @Published var documents: [PetDocument] = [] { didSet { save() } }
    @Published var readNotificationEventIDs: Set<UUID> = [] { didSet { save() } }

    private struct Snapshot: Codable {
        var profile: UserProfile?
        var pets: [Pet]
        var events: [PetEvent]
        var expenses: [Expense]
        var documents: [PetDocument]
        var readNotificationEventIDs: Set<UUID>?
    }

    private let fileURL: URL
    private var isLoading = false

    init() {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        fileURL = directory.appendingPathComponent("coccolia-data.json")
        load()
    }

    var upcomingEvents: [PetEvent] {
        events
            .filter { $0.date >= AppDateTime.calendar.startOfDay(for: Date()) }
            .sorted { $0.date < $1.date }
    }

    /// Only events whose 24-hour reminder window has started belong in the in-app inbox.
    var notificationEvents: [PetEvent] {
        let now = Date()
        return upcomingEvents.filter { event in
            guard event.reminderEnabled else { return false }
            let reminderDate = AppDateTime.calendar.date(byAdding: .hour, value: -24, to: event.date) ?? event.date
            return reminderDate <= now
        }
    }

    var unreadUpcomingEvents: [PetEvent] {
        notificationEvents.filter { !readNotificationEventIDs.contains($0.id) }
    }

    var unreadNotificationCount: Int { unreadUpcomingEvents.count }

    func isNotificationRead(for event: PetEvent) -> Bool {
        readNotificationEventIDs.contains(event.id)
    }

    func markNotificationRead(for event: PetEvent) {
        readNotificationEventIDs.insert(event.id)
    }

    func markAllNotificationsRead() {
        readNotificationEventIDs.formUnion(notificationEvents.map(\.id))
    }

    func pet(for id: UUID) -> Pet? { pets.first { $0.id == id } }
    func addPet(_ pet: Pet) { pets.append(pet) }
    func updatePet(_ pet: Pet) {
        guard let index = pets.firstIndex(where: { $0.id == pet.id }) else { return }
        pets[index] = pet
    }
    func deletePets(at offsets: IndexSet) {
        let petsToDelete = offsets.compactMap { index in
            pets.indices.contains(index) ? pets[index] : nil
        }
        petsToDelete.forEach(deletePet)
    }

    func deletePet(_ pet: Pet) {
        let linkedEvents = events.filter { $0.petID == pet.id }
        NotificationManager.shared.removePendingNotifications(
            identifiers: linkedEvents.map { $0.id.uuidString }
        )

        let linkedDocuments = documents.filter { $0.petID == pet.id }
        for document in linkedDocuments {
            try? FileManager.default.removeItem(at: documentURL(for: document))
        }

        readNotificationEventIDs.subtract(linkedEvents.map(\.id))
        events.removeAll { $0.petID == pet.id }
        expenses.removeAll { $0.petID == pet.id }
        documents.removeAll { $0.petID == pet.id }
        pets.removeAll { $0.id == pet.id }
    }

    func addEvent(_ event: PetEvent) { events.append(event) }

    func updateEvent(_ event: PetEvent) {
        guard let index = events.firstIndex(where: { $0.id == event.id }) else { return }
        events[index] = event
    }

    func deleteEvent(_ event: PetEvent) {
        NotificationManager.shared.removePendingNotifications(identifiers: [event.id.uuidString])
        readNotificationEventIDs.remove(event.id)
        events.removeAll { $0.id == event.id }
    }

    func addExpense(_ expense: Expense) { expenses.append(expense) }

    func updateExpense(_ expense: Expense) {
        guard let index = expenses.firstIndex(where: { $0.id == expense.id }) else { return }
        expenses[index] = expense
    }

    func deleteExpense(_ expense: Expense) {
        expenses.removeAll { $0.id == expense.id }
    }

    func importDocument(from sourceURL: URL, title: String, type: String, petID: UUID) -> Bool {
        let hasAccess = sourceURL.startAccessingSecurityScopedResource()
        defer { if hasAccess { sourceURL.stopAccessingSecurityScopedResource() } }
        let directory = fileURL.deletingLastPathComponent().appendingPathComponent("Documents", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let ext = sourceURL.pathExtension
        let storedName = UUID().uuidString + (ext.isEmpty ? "" : "." + ext)
        let destination = directory.appendingPathComponent(storedName)
        do {
            try FileManager.default.copyItem(at: sourceURL, to: destination)
            documents.append(PetDocument(petID: petID, title: title, type: type, createdAt: Date(), fileName: storedName))
            return true
        } catch { return false }
    }

    func documentURL(for document: PetDocument) -> URL {
        fileURL.deletingLastPathComponent().appendingPathComponent("Documents", isDirectory: true).appendingPathComponent(document.fileName)
    }

    func updateDocument(_ document: PetDocument) {
        guard let index = documents.firstIndex(where: { $0.id == document.id }) else { return }
        documents[index] = document
    }

    func deleteDocument(_ document: PetDocument) {
        try? FileManager.default.removeItem(at: documentURL(for: document))
        documents.removeAll { $0.id == document.id }
    }

    func createLocalProfile(firstName: String, lastName: String, email: String, acceptedPrivacy: Bool) {
        profile = UserProfile(
            firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
            lastName: lastName.trimmingCharacters(in: .whitespacesAndNewlines),
            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
            acceptedPrivacy: acceptedPrivacy,
            createdAt: Date()
        )
    }

    private func load() {
        isLoading = true
        defer { isLoading = false }
        guard let data = try? Data(contentsOf: fileURL),
              let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data) else { return }
        profile = snapshot.profile
        pets = snapshot.pets
        events = snapshot.events
        expenses = snapshot.expenses
        documents = snapshot.documents
        readNotificationEventIDs = snapshot.readNotificationEventIDs ?? []
    }

    private func save() {
        guard !isLoading else { return }
        let snapshot = Snapshot(
            profile: profile,
            pets: pets,
            events: events,
            expenses: expenses,
            documents: documents,
            readNotificationEventIDs: readNotificationEventIDs
        )
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: fileURL, options: [.atomic])
    }
}
