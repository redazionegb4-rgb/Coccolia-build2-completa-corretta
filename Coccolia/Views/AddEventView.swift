import SwiftUI

struct AddEventView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: PetStore

    let preselectedPetID: UUID?
    let initialCategory: PetEvent.Category?
    let eventToEdit: PetEvent?

    @State private var selectedPetID: UUID?
    @State private var category: PetEvent.Category
    @State private var title: String
    @State private var date: Date
    @State private var notes: String
    @State private var reminder: Bool
    @State private var showingDeleteConfirmation = false

    init(
        preselectedPetID: UUID? = nil,
        initialCategory: PetEvent.Category? = nil,
        eventToEdit: PetEvent? = nil
    ) {
        self.preselectedPetID = preselectedPetID
        self.initialCategory = initialCategory
        self.eventToEdit = eventToEdit

        let startingCategory = eventToEdit?.category ?? initialCategory ?? .vet
        _selectedPetID = State(initialValue: eventToEdit?.petID ?? preselectedPetID)
        _category = State(initialValue: startingCategory)
        _title = State(initialValue: eventToEdit?.title ?? startingCategory.rawValue)
        _date = State(initialValue: eventToEdit?.date ?? AppDateTime.calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date())
        _notes = State(initialValue: eventToEdit?.notes ?? "")
        _reminder = State(initialValue: eventToEdit?.reminderEnabled ?? true)
    }

    private var isEditing: Bool { eventToEdit != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Dettagli") {
                    Picker("Bambino", selection: $selectedPetID) {
                        Text("Seleziona").tag(UUID?.none)
                        ForEach(store.pets) { pet in
                            Text(pet.name).tag(Optional(pet.id))
                        }
                    }

                    Picker("Categoria", selection: $category) {
                        ForEach(PetEvent.Category.allCases) { item in
                            Text(item.rawValue).tag(item)
                        }
                    }

                    TextField("Titolo", text: $title)
                }

                Section("Data e ora") {
                    DatePicker("Data", selection: $date, displayedComponents: .date)
                    DatePicker("Ora", selection: $date, displayedComponents: .hourAndMinute)
                    LabeledContent("Riepilogo", value: ItalianDate.full.string(from: date))
                        .font(.subheadline)
                }

                Section("Promemoria") {
                    Toggle("Avvisami 24 ore prima", isOn: $reminder)
                    TextField("Note", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                if isEditing {
                    Section {
                        Button(role: .destructive) {
                            showingDeleteConfirmation = true
                        } label: {
                            Label("Elimina appuntamento", systemImage: "trash")
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                }
            }
            .environment(\.locale, Locale(identifier: "it_IT"))
            .environment(\.calendar, AppDateTime.calendar)
            .environment(\.timeZone, AppDateTime.timeZone)
            .navigationTitle(isEditing ? "Modifica impegno" : "Nuovo impegno")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") { save() }
                        .disabled(selectedPetID == nil)
                }
            }
            .onAppear {
                if selectedPetID == nil {
                    selectedPetID = preselectedPetID ?? store.pets.first?.id
                }
            }
            .onChange(of: category) { oldValue, newValue in
                if title.isEmpty || title == oldValue.rawValue || PetEvent.Category.allCases.map(\.rawValue).contains(title) {
                    title = newValue.rawValue
                }
            }
            .alert("Eliminare questo appuntamento?", isPresented: $showingDeleteConfirmation) {
                Button("Annulla", role: .cancel) { }
                Button("Elimina", role: .destructive) { deleteEvent() }
            } message: {
                Text("L’appuntamento e il relativo promemoria verranno eliminati definitivamente.")
            }
        }
    }

    private func save() {
        guard let petID = selectedPetID else { return }

        let event = PetEvent(
            id: eventToEdit?.id ?? UUID(),
            petID: petID,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? category.rawValue : title.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category,
            date: date,
            notes: notes,
            reminderEnabled: reminder
        )

        if isEditing {
            store.updateEvent(event)
        } else {
            store.addEvent(event)
        }

        Task {
            await NotificationService.cancel(for: event.id)
            if reminder {
                _ = await NotificationService.requestAuthorization()
                await NotificationService.schedule(for: event)
            }
        }

        dismiss()
    }

    private func deleteEvent() {
        guard let event = eventToEdit else { return }
        store.deleteEvent(event)
        Task { await NotificationService.cancel(for: event.id) }
        dismiss()
    }
}
