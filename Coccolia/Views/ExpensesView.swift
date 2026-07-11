import SwiftUI

struct ExpensesView: View {
    @EnvironmentObject private var store: PetStore
    @State private var showingAdd = false
    @State private var expenseToEdit: Expense?
    @State private var expenseToDelete: Expense?

    private var total: Double { store.expenses.reduce(0) { $0 + $1.amount } }

    var body: some View {
        List {
            Section {
                HStack {
                    Text("Totale registrato").font(.headline)
                    Spacer()
                    Text(total, format: .currency(code: "EUR"))
                        .font(.title2.bold())
                        .foregroundStyle(AppTheme.teal)
                }
            }

            ForEach(store.expenses.sorted { $0.date > $1.date }) { expense in
                Button {
                    expenseToEdit = expense
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(expense.category.rawValue)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text(expense.note.isEmpty ? ItalianDate.dateOnly.string(from: expense.date) : expense.note)
                                .foregroundStyle(.secondary)
                            if let petID = expense.petID, let pet = store.pet(for: petID) {
                                Text(pet.name)
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.tealDark)
                            }
                        }
                        Spacer()
                        Text(expense.amount, format: .currency(code: "EUR"))
                            .bold()
                            .foregroundStyle(.primary)
                        Image(systemName: "chevron.right")
                            .font(.caption.bold())
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        expenseToDelete = expense
                    } label: {
                        Label("Elimina", systemImage: "trash")
                    }
                    Button {
                        expenseToEdit = expense
                    } label: {
                        Label("Modifica", systemImage: "pencil")
                    }
                    .tint(AppTheme.teal)
                }
                .contextMenu {
                    Button {
                        expenseToEdit = expense
                    } label: {
                        Label("Modifica", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        expenseToDelete = expense
                    } label: {
                        Label("Elimina", systemImage: "trash")
                    }
                }
            }
        }
        .overlay {
            if store.expenses.isEmpty {
                ContentUnavailableView(
                    "Nessuna spesa",
                    systemImage: "wallet.pass",
                    description: Text("Registra le spese dei tuoi bambini.")
                )
            }
        }
        .navigationTitle("Spese")
        .toolbar {
            Button { showingAdd = true } label: { Image(systemName: "plus") }
        }
        .sheet(isPresented: $showingAdd) {
            ExpenseEditorView(mode: .create)
        }
        .sheet(item: $expenseToEdit) { expense in
            ExpenseEditorView(mode: .edit(expense))
        }
        .confirmationDialog(
            "Eliminare questa spesa?",
            isPresented: Binding(
                get: { expenseToDelete != nil },
                set: { if !$0 { expenseToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Elimina definitivamente", role: .destructive) {
                if let expenseToDelete { store.deleteExpense(expenseToDelete) }
                expenseToDelete = nil
            }
            Button("Annulla", role: .cancel) { expenseToDelete = nil }
        } message: {
            Text("Questa operazione non può essere annullata.")
        }
    }
}

struct ExpenseEditorView: View {
    enum Mode {
        case create
        case edit(Expense)
    }

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: PetStore

    let mode: Mode
    @State private var petID: UUID?
    @State private var category: Expense.Category = .veterinary
    @State private var amount = ""
    @State private var date = Date()
    @State private var note = ""
    @State private var showingDeleteConfirmation = false

    private var editingExpense: Expense? {
        if case .edit(let expense) = mode { return expense }
        return nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Picker("Bambino", selection: $petID) {
                    Text("Nessuno specifico").tag(UUID?.none)
                    ForEach(store.pets) { Text($0.name).tag(Optional($0.id)) }
                }
                Picker("Categoria", selection: $category) {
                    ForEach(Expense.Category.allCases) { Text($0.rawValue).tag($0) }
                }
                TextField("Importo", text: $amount)
                    .keyboardType(.decimalPad)
                DatePicker("Data", selection: $date, displayedComponents: .date)
                    .environment(\.locale, Locale(identifier: "it_IT"))
                TextField("Nota", text: $note)

                if editingExpense != nil {
                    Section {
                        Button("Elimina spesa", role: .destructive) {
                            showingDeleteConfirmation = true
                        }
                    }
                }
            }
            .navigationTitle(editingExpense == nil ? "Nuova spesa" : "Modifica spesa")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: loadValues)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") { save() }
                        .disabled(parsedAmount == nil)
                }
            }
            .confirmationDialog(
                "Eliminare questa spesa?",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Elimina definitivamente", role: .destructive) {
                    if let editingExpense { store.deleteExpense(editingExpense) }
                    dismiss()
                }
                Button("Annulla", role: .cancel) { }
            } message: {
                Text("Questa operazione non può essere annullata.")
            }
        }
    }

    private var parsedAmount: Double? {
        Double(amount.replacingOccurrences(of: ",", with: "."))
    }

    private func loadValues() {
        guard let expense = editingExpense else { return }
        petID = expense.petID
        category = expense.category
        amount = String(format: "%.2f", locale: Locale(identifier: "it_IT"), expense.amount)
        date = expense.date
        note = expense.note
    }

    private func save() {
        guard let value = parsedAmount else { return }
        if let original = editingExpense {
            var updated = original
            updated.petID = petID
            updated.category = category
            updated.amount = value
            updated.date = date
            updated.note = note
            store.updateExpense(updated)
        } else {
            store.addExpense(Expense(petID: petID, category: category, amount: value, date: date, note: note))
        }
        dismiss()
    }
}

/// Schermata compatibile usata dalle azioni rapide della Home.
/// Apre l'editor delle spese in modalità creazione.
struct AddExpenseView: View {
    var body: some View {
        ExpenseEditorView(mode: .create)
    }
}

