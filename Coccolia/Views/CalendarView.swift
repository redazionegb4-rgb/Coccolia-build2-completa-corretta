import SwiftUI

struct CalendarView: View {
    @EnvironmentObject private var store: PetStore
    @State private var showingAdd = false
    @State private var selectedEvent: PetEvent?

    private var groupedDays: [Date] {
        Dictionary(
            grouping: store.events.sorted { $0.date < $1.date },
            by: { AppDateTime.calendar.startOfDay(for: $0.date) }
        ).keys.sorted()
    }

    var body: some View {
        List {
            ForEach(groupedDays, id: \.self) { day in
                Section(ItalianDate.dateOnly.string(from: day)) {
                    ForEach(
                        store.events
                            .filter { AppDateTime.calendar.isDate($0.date, inSameDayAs: day) }
                            .sorted { $0.date < $1.date }
                    ) { event in
                        EventRow(event: event)
                            .contentShape(Rectangle())
                            .onTapGesture { selectedEvent = event }
                            .accessibilityAddTraits(.isButton)
                    }
                }
            }
        }
        .overlay {
            if store.events.isEmpty {
                ContentUnavailableView(
                    "Calendario vuoto",
                    systemImage: "calendar",
                    description: Text("Aggiungi visite, farmaci, vaccini o toelettature.")
                )
            }
        }
        .navigationTitle("Calendario")
        .toolbar {
            Button { showingAdd = true } label: { Image(systemName: "plus") }
        }
        .sheet(isPresented: $showingAdd) { AddEventView() }
        .sheet(item: $selectedEvent) { event in
            AddEventView(eventToEdit: event)
        }
    }
}
