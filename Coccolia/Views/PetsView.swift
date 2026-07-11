import SwiftUI

struct PetsView: View {
    @EnvironmentObject private var store: PetStore
    @State private var showingAdd = false
    @State private var petPendingDeletion: Pet?

    var body: some View {
        List {
            ForEach(store.pets) { pet in
                NavigationLink {
                    PetDetailView(pet: pet)
                } label: {
                    HStack(spacing: 14) {
                        PetAvatar(pet: pet, size: 64)
                        VStack(alignment: .leading) {
                            Text(pet.name).font(.headline)
                            Text([pet.species, pet.breed].filter { !$0.isEmpty }.joined(separator: " • "))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 5)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        petPendingDeletion = pet
                    } label: {
                        Label("Elimina", systemImage: "trash")
                    }
                }
            }
        }
        .overlay {
            if store.pets.isEmpty {
                ContentUnavailableView(
                    "I tuoi bambini",
                    systemImage: "figure.and.child.holdinghands",
                    description: Text("Aggiungi un bambino per iniziare.")
                )
            }
        }
        .navigationTitle("Bambini")
        .toolbar {
            Button { showingAdd = true } label: {
                Image(systemName: "plus")
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddPetView()
        }
        .confirmationDialog(
            "Eliminare l’bambino?",
            isPresented: Binding(
                get: { petPendingDeletion != nil },
                set: { if !$0 { petPendingDeletion = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let pet = petPendingDeletion {
                Button("Elimina definitivamente", role: .destructive) {
                    store.deletePet(pet)
                    petPendingDeletion = nil
                }
            }
            Button("Annulla", role: .cancel) {
                petPendingDeletion = nil
            }
        } message: {
            if let pet = petPendingDeletion {
                Text("Verranno eliminati anche gli appuntamenti, i promemoria, le spese e i documenti collegati a \(pet.name). Questa operazione non può essere annullata.")
            }
        }
    }
}
