import SwiftUI
import PhotosUI

struct PetDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: PetStore
    let pet: Pet
    @State private var showingEvent = false
    @State private var showingEdit = false
    @State private var showingDeleteConfirmation = false

    private var currentPet: Pet { store.pet(for: pet.id) ?? pet }
    private var petEvents: [PetEvent] {
        store.events.filter { $0.petID == currentPet.id }.sorted { $0.date < $1.date }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                PetAvatar(pet: currentPet, size: 150)
                Text(currentPet.name).font(.largeTitle.bold())
                Text([currentPet.species, currentPet.breed].filter { !$0.isEmpty }.joined(separator: " • "))
                    .foregroundStyle(.secondary)

                infoCard
                groomingCard
                healthCard

                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Label("Elimina bambino", systemImage: "trash.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.bordered)
                .tint(.red)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Appuntamenti e promemoria").font(.title2.bold())
                    if petEvents.isEmpty {
                        Text("Nessun appuntamento registrato")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                    } else {
                        ForEach(petEvents) { EventRow(event: $0) }
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(currentPet.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button("Modifica") { showingEdit = true }
                    .fontWeight(.semibold)
                Button { showingEvent = true } label: {
                    Image(systemName: "calendar.badge.plus")
                }
            }
        }
        .sheet(isPresented: $showingEvent) {
            AddEventView(preselectedPetID: currentPet.id)
        }
        .sheet(isPresented: $showingEdit) {
            EditPetView(pet: currentPet)
        }
        .alert("Eliminare \(currentPet.name)?", isPresented: $showingDeleteConfirmation) {
            Button("Annulla", role: .cancel) { }
            Button("Elimina definitivamente", role: .destructive) {
                store.deletePet(currentPet)
                dismiss()
            }
        } message: {
            Text("Verranno eliminati anche gli appuntamenti, i promemoria, le spese e i documenti collegati. Questa operazione non può essere annullata.")
        }
    }

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Profilo").font(.headline)
                Spacer()
                Button {
                    showingEdit = true
                } label: {
                    Label("Modifica", systemImage: "pencil")
                        .font(.subheadline.bold())
                }
                .buttonStyle(.borderless)
                .foregroundStyle(AppTheme.tealDark)
            }
            LabeledContent("Sesso", value: currentPet.sex.rawValue)
            if let birthDate = currentPet.birthDate {
                LabeledContent("Nascita", value: ItalianDate.dateOnly.string(from: birthDate))
            }
            if let weight = currentPet.weight {
                LabeledContent("Peso", value: String(format: "%.1f kg", weight))
            }
            if !currentPet.microchip.isEmpty {
                LabeledContent("Microchip", value: currentPet.microchip)
            }
            if !currentPet.mainColor.isEmpty {
                LabeledContent("Colore", value: currentPet.mainColor)
            }
        }
        .petCard()
    }

    private var groomingCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Cura e toelettatura", systemImage: "scissors").font(.headline)
            Text("Registra bagno, taglio, spazzolatura, unghie e altri trattamenti.")
                .foregroundStyle(.secondary)
            Button("Aggiungi appuntamento") { showingEvent = true }
                .buttonStyle(.borderedProminent)
        }
        .petCard()
    }

    private var healthCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Salute", systemImage: "heart.text.square.fill").font(.headline)
            if currentPet.allergies.isEmpty {
                Text("Nessuna allergia registrata").foregroundStyle(.secondary)
            } else {
                Text("Allergie: \(currentPet.allergies)")
            }
            if !currentPet.distinctiveFeatures.isEmpty {
                Text("Caratteristiche: \(currentPet.distinctiveFeatures)")
                    .foregroundStyle(.secondary)
            }
            if !currentPet.notes.isEmpty {
                Text(currentPet.notes).foregroundStyle(.secondary)
            }
        }
        .petCard()
    }
}

struct EditPetView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: PetStore

    let pet: Pet

    @State private var photoItem: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var name: String
    @State private var species: String
    @State private var breed: String
    @State private var sex: Pet.Sex
    @State private var hasBirthDate: Bool
    @State private var birthDate: Date
    @State private var weight: String
    @State private var microchip: String
    @State private var mainColor: String
    @State private var features: String
    @State private var allergies: String
    @State private var notes: String

    private let speciesOptions = [
        ("Cane", "dog.fill"),
        ("Gatto", "cat.fill"),
        ("Coniglio", "hare.fill"),
        ("Uccello", "bird.fill"),
        ("Altro", "ellipsis")
    ]

    init(pet: Pet) {
        self.pet = pet
        _photoData = State(initialValue: pet.photoData)
        _name = State(initialValue: pet.name)
        _species = State(initialValue: pet.species)
        _breed = State(initialValue: pet.breed)
        _sex = State(initialValue: pet.sex)
        _hasBirthDate = State(initialValue: pet.birthDate != nil)
        _birthDate = State(initialValue: pet.birthDate ?? Date())
        _weight = State(initialValue: pet.weight.map { String(format: "%.1f", $0).replacingOccurrences(of: ".", with: ",") } ?? "")
        _microchip = State(initialValue: pet.microchip)
        _mainColor = State(initialValue: pet.mainColor)
        _features = State(initialValue: pet.distinctiveFeatures)
        _allergies = State(initialValue: pet.allergies)
        _notes = State(initialValue: pet.notes)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    photoCard
                    sectionCard("Informazioni generali") { generalInfo }
                    sectionCard("Salute e identificazione") { healthInfo }
                    sectionCard("Caratteristiche") { characteristics }
                    sectionCard("Allergie e note") { notesSection }

                    Button(action: save) {
                        Label("Salva modifiche", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppTheme.brandGradient)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(18)
                .padding(.bottom, 24)
            }
            .background(AppTheme.page.ignoresSafeArea())
            .navigationTitle("Modifica \(pet.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
            }
        }
    }

    private var photoCard: some View {
        sectionCard("Foto dell’bambino") {
            PhotosPicker(selection: $photoItem, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    Group {
                        if let photoData, let image = UIImage(data: photoData) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                        } else {
                            VStack(spacing: 10) {
                                Image(systemName: "camera.fill")
                                    .font(.title2)
                                    .foregroundStyle(.white)
                                    .frame(width: 58, height: 58)
                                    .background(AppTheme.teal)
                                    .clipShape(Circle())
                                Text("Aggiungi una foto")
                                    .font(.headline)
                                    .foregroundStyle(AppTheme.navy)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 210, maxHeight: 210)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 34))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, AppTheme.teal)
                        .padding(10)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(AppTheme.teal.opacity(0.25), lineWidth: 1.5)
                )
            }
            .onChange(of: photoItem) { _, newItem in
                Task { photoData = try? await newItem?.loadTransferable(type: Data.self) }
            }
        }
    }

    private var generalInfo: some View {
        VStack(spacing: 15) {
            field("Nome dell’bambino *", placeholder: "Es. Milo", text: $name, icon: "figure.and.child.holdinghands")

            VStack(alignment: .leading, spacing: 10) {
                Text("Tipo di bambino *").font(.subheadline.bold())
                HStack(spacing: 8) {
                    ForEach(speciesOptions, id: \.0) { item in
                        Button { species = item.0 } label: {
                            VStack(spacing: 5) {
                                Image(systemName: item.1).font(.title3)
                                Text(item.0).font(.caption2)
                            }
                            .foregroundStyle(species == item.0 ? AppTheme.tealDark : AppTheme.navy)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(species == item.0 ? AppTheme.mint : Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(species == item.0 ? AppTheme.teal : Color.gray.opacity(0.2))
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            field("Razza", placeholder: "Es. Golden Retriever", text: $breed, icon: "figure.and.child.holdinghands")

            VStack(alignment: .leading, spacing: 10) {
                Text("Sesso").font(.subheadline.bold())
                HStack(spacing: 10) {
                    sexButton(.male, icon: "male", tint: .blue)
                    sexButton(.female, icon: "female", tint: .pink)
                    sexButton(.unknown, icon: "questionmark.circle", tint: .purple)
                }
            }

            Toggle("Conosco la data di nascita", isOn: $hasBirthDate)
                .tint(AppTheme.teal)
            if hasBirthDate {
                DatePicker("Data di nascita", selection: $birthDate, displayedComponents: .date)
                    .environment(\.locale, Locale(identifier: "it_IT"))
            }
        }
    }

    private var healthInfo: some View {
        VStack(spacing: 14) {
            field("Peso attuale", placeholder: "0,0 kg", text: $weight, icon: "scalemass.fill")
            field("Numero microchip", placeholder: "Inserisci il numero", text: $microchip, icon: "cpu")
        }
    }

    private var characteristics: some View {
        VStack(spacing: 14) {
            field("Colore principale", placeholder: "Es. Marrone, bianco...", text: $mainColor, icon: "paintpalette.fill")
            multiline("Caratteristiche distintive", placeholder: "Macchia sull’occhio, pelo lungo...", text: $features)
        }
    }

    private var notesSection: some View {
        VStack(spacing: 14) {
            multiline("Allergie o intolleranze", placeholder: "Es. Allergico ai pollini...", text: $allergies)
            multiline("Note aggiuntive", placeholder: "Scrivi qui note importanti...", text: $notes)
        }
    }

    private func sectionCard<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title).font(.title3.bold()).foregroundStyle(AppTheme.navy)
            content()
        }
        .petCard(18)
    }

    private func field(_ label: String, placeholder: String, text: Binding<String>, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label).font(.subheadline.bold())
            HStack {
                Image(systemName: icon).foregroundStyle(AppTheme.teal)
                TextField(placeholder, text: text)
            }
            .padding(14)
            .background(AppTheme.page)
            .clipShape(RoundedRectangle(cornerRadius: 15))
        }
    }

    private func multiline(_ label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label).font(.subheadline.bold())
            TextField(placeholder, text: text, axis: .vertical)
                .lineLimit(3...5)
                .padding(14)
                .background(AppTheme.page)
                .clipShape(RoundedRectangle(cornerRadius: 15))
        }
    }

    private func sexButton(_ value: Pet.Sex, icon: String, tint: Color) -> some View {
        Button { sex = value } label: {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.title2)
                Text(value.rawValue).font(.caption.bold())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .foregroundStyle(tint)
            .background(sex == value ? tint.opacity(0.14) : AppTheme.page)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private func save() {
        let parsedWeight = Double(weight.replacingOccurrences(of: ",", with: "."))
        let updatedPet = Pet(
            id: pet.id,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            species: species,
            breed: breed.trimmingCharacters(in: .whitespacesAndNewlines),
            sex: sex,
            birthDate: hasBirthDate ? birthDate : nil,
            weight: parsedWeight,
            microchip: microchip.trimmingCharacters(in: .whitespacesAndNewlines),
            mainColor: mainColor.trimmingCharacters(in: .whitespacesAndNewlines),
            distinctiveFeatures: features.trimmingCharacters(in: .whitespacesAndNewlines),
            allergies: allergies.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            photoData: photoData
        )
        store.updatePet(updatedPet)
        dismiss()
    }
}
