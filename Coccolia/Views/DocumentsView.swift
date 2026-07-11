import SwiftUI
import UniformTypeIdentifiers
import QuickLook

struct DocumentsView: View {
    @EnvironmentObject private var store: PetStore
    @State private var showingImporter = false
    @State private var showingAddSheet = false
    @State private var importedURL: URL?
    @State private var previewDocument: PetDocument?
    @State private var documentToEdit: PetDocument?
    @State private var documentToDelete: PetDocument?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.white.ignoresSafeArea()

            if store.documents.isEmpty {
                emptyState
            } else {
                documentsList

                Button {
                    showingImporter = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                        .frame(width: 58, height: 58)
                        .background(AppTheme.brandGradient)
                        .clipShape(Circle())
                        .shadow(color: AppTheme.teal.opacity(0.3), radius: 12, y: 7)
                }
                .padding(22)
            }
        }
        .navigationTitle("Documenti")
        .navigationBarTitleDisplayMode(.large)
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.pdf, .image, .plainText, .data],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                importedURL = url
                showingAddSheet = true
            }
        }
        .sheet(isPresented: $showingAddSheet, onDismiss: { importedURL = nil }) {
            if let importedURL {
                AddDocumentView(sourceURL: importedURL)
            }
        }
        .sheet(item: $documentToEdit) { document in
            EditDocumentView(document: document)
        }
        .fullScreenCover(item: $previewDocument) { document in
            DocumentPreviewScreen(
                document: document,
                url: store.documentURL(for: document),
                onEdit: {
                    previewDocument = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        documentToEdit = document
                    }
                },
                onDelete: {
                    store.deleteDocument(document)
                    previewDocument = nil
                }
            )
        }
        .confirmationDialog(
            "Eliminare questo documento?",
            isPresented: Binding(
                get: { documentToDelete != nil },
                set: { if !$0 { documentToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Elimina definitivamente", role: .destructive) {
                if let documentToDelete { store.deleteDocument(documentToDelete) }
                documentToDelete = nil
            }
            Button("Annulla", role: .cancel) { documentToDelete = nil }
        } message: {
            Text("Il file verrà rimosso dal dispositivo. Questa operazione non può essere annullata.")
        }
    }

    private var documentsList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Archivio Coccolia")
                            .font(.title2.bold())
                            .foregroundStyle(AppTheme.navy)
                        Text("Documenti salvati sul dispositivo")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "lock.shield.fill")
                        .foregroundStyle(AppTheme.teal)
                        .font(.title2)
                }
                .padding(18)
                .background(AppTheme.mint)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                LazyVStack(spacing: 14) {
                    ForEach(store.documents.sorted { $0.createdAt > $1.createdAt }) { document in
                        Button {
                            previewDocument = document
                        } label: {
                            DocumentCard(document: document)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button {
                                documentToEdit = document
                            } label: {
                                Label("Modifica", systemImage: "pencil")
                            }
                            Button(role: .destructive) {
                                documentToDelete = document
                            } label: {
                                Label("Elimina", systemImage: "trash")
                            }
                        }
                        .swipeActionsIfAvailable(
                            onEdit: { documentToEdit = document },
                            onDelete: { documentToDelete = document }
                        )
                    }
                }
            }
            .padding(18)
            .padding(.bottom, 90)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle().fill(AppTheme.sky).frame(width: 116, height: 116)
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 45))
                    .foregroundStyle(.blue)
            }
            Text("I documenti del tuo bambino")
                .font(.title2.bold())
                .foregroundStyle(AppTheme.navy)
            Text("Conserva libretto sanitario, vaccini, ricette, referti e ricevute direttamente sul dispositivo.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 30)
            Button { showingImporter = true } label: {
                Label("Aggiungi documento", systemImage: "plus")
                    .font(.headline)
                    .frame(maxWidth: 270)
                    .padding(.vertical, 15)
                    .background(AppTheme.brandGradient)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
                    .shadow(color: AppTheme.teal.opacity(0.22), radius: 9, y: 5)
            }
        }
        .padding(24)
    }
}

private extension View {
    @ViewBuilder
    func swipeActionsIfAvailable(onEdit: @escaping () -> Void, onDelete: @escaping () -> Void) -> some View {
        // Le schede sono in uno ScrollView, quindi il menu contestuale è il controllo principale.
        // Questo helper mantiene il punto di estensione senza alterare il layout corrente.
        self
    }
}

struct DocumentCard: View {
    @EnvironmentObject private var store: PetStore
    let document: PetDocument

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(tint)
                .frame(width: 58, height: 58)
                .background(tint.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 18))
            VStack(alignment: .leading, spacing: 5) {
                Text(document.title).font(.headline).foregroundStyle(AppTheme.navy)
                Text("\(store.pet(for: document.petID)?.name ?? "Bambino") • \(document.type)")
                    .font(.subheadline).foregroundStyle(tint)
                Text("Aggiunto il \(ItalianDate.dateOnly.string(from: document.createdAt))")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.tertiary)
        }
        .petCard(14)
    }

    private var symbol: String {
        switch document.type {
        case "Libretto sanitario": return "cross.case.fill"
        case "Vaccinazione": return "syringe.fill"
        case "Ricetta": return "pills.fill"
        case "Referto": return "waveform.path.ecg.rectangle.fill"
        case "Ricevuta": return "eurosign.circle.fill"
        default: return "doc.fill"
        }
    }

    private var tint: Color {
        document.type == "Vaccinazione" ? .green :
        document.type == "Ricetta" ? .purple :
        document.type == "Ricevuta" ? .blue : AppTheme.tealDark
    }
}

struct AddDocumentView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: PetStore
    let sourceURL: URL
    @State private var title = ""
    @State private var type = "Libretto sanitario"
    @State private var selectedPetID: UUID?
    private let types = ["Libretto sanitario", "Vaccinazione", "Ricetta", "Referto", "Certificato", "Ricevuta", "Altro"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Documento") {
                    TextField("Titolo", text: $title)
                    Picker("Categoria", selection: $type) { ForEach(types, id: \.self) { Text($0) } }
                    Picker("Bambino", selection: $selectedPetID) {
                        Text("Seleziona").tag(UUID?.none)
                        ForEach(store.pets) { Text($0.name).tag(Optional($0.id)) }
                    }
                }
                Section { Label(sourceURL.lastPathComponent, systemImage: "paperclip").font(.subheadline) }
            }
            .navigationTitle("Nuovo documento")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                selectedPetID = store.pets.first?.id
                if title.isEmpty { title = sourceURL.deletingPathExtension().lastPathComponent }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Annulla") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") {
                        guard let petID = selectedPetID else { return }
                        if store.importDocument(from: sourceURL, title: title, type: type, petID: petID) { dismiss() }
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedPetID == nil)
                }
            }
        }
    }
}

struct EditDocumentView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: PetStore
    let document: PetDocument

    @State private var title: String
    @State private var type: String
    @State private var selectedPetID: UUID?
    @State private var showingDeleteConfirmation = false

    private let types = ["Libretto sanitario", "Vaccinazione", "Ricetta", "Referto", "Certificato", "Ricevuta", "Altro"]

    init(document: PetDocument) {
        self.document = document
        _title = State(initialValue: document.title)
        _type = State(initialValue: document.type)
        _selectedPetID = State(initialValue: document.petID)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Documento") {
                    TextField("Titolo", text: $title)
                    Picker("Categoria", selection: $type) { ForEach(types, id: \.self) { Text($0) } }
                    Picker("Bambino", selection: $selectedPetID) {
                        ForEach(store.pets) { Text($0.name).tag(Optional($0.id)) }
                    }
                }
                Section("File") {
                    Label(document.fileName, systemImage: "paperclip")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Section {
                    Button("Elimina documento", role: .destructive) { showingDeleteConfirmation = true }
                }
            }
            .navigationTitle("Modifica documento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Annulla") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedPetID == nil)
                }
            }
            .confirmationDialog(
                "Eliminare questo documento?",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Elimina definitivamente", role: .destructive) {
                    store.deleteDocument(document)
                    dismiss()
                }
                Button("Annulla", role: .cancel) { }
            } message: {
                Text("Il file verrà rimosso dal dispositivo. Questa operazione non può essere annullata.")
            }
        }
    }

    private func save() {
        guard let selectedPetID else { return }
        var updated = document
        updated.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.type = type
        updated.petID = selectedPetID
        store.updateDocument(updated)
        dismiss()
    }
}

struct DocumentPreviewScreen: View {
    @Environment(\.dismiss) private var dismiss
    let document: PetDocument
    let url: URL
    let onEdit: () -> Void
    let onDelete: () -> Void
    @State private var showingDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            QuickLookPreview(url: url)
                .ignoresSafeArea(edges: .bottom)
                .navigationTitle(document.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            dismiss()
                        } label: {
                            Label("Indietro", systemImage: "chevron.left")
                        }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            Button(action: onEdit) { Label("Modifica", systemImage: "pencil") }
                            ShareLink(item: url) { Label("Condividi", systemImage: "square.and.arrow.up") }
                            Button(role: .destructive) { showingDeleteConfirmation = true } label: {
                                Label("Elimina", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
                .confirmationDialog(
                    "Eliminare questo documento?",
                    isPresented: $showingDeleteConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Elimina definitivamente", role: .destructive, action: onDelete)
                    Button("Annulla", role: .cancel) { }
                } message: {
                    Text("Il file verrà rimosso dal dispositivo.")
                }
        }
    }
}

struct QuickLookPreview: UIViewControllerRepresentable {
    let url: URL
    func makeCoordinator() -> Coordinator { Coordinator(url: url) }
    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }
    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {}

    final class Coordinator: NSObject, QLPreviewControllerDataSource {
        let url: URL
        init(url: URL) { self.url = url }
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem { url as NSURL }
    }
}
