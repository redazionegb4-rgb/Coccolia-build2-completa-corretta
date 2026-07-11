import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: PetStore
    @State private var showingAddPet = false
    @State private var showingAddEvent = false
    @State private var showingAddExpense = false
    @State private var showingNotifications = false
    @State private var preferredCategory: PetEvent.Category? = nil
    @State private var selectedEvent: PetEvent?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                topBar
                hero
                petsSection
                upcomingSection
                quickActions
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 34)
        }
        .background(Color.white.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingAddPet) { AddPetView() }
        .sheet(isPresented: $showingAddEvent) {
            AddEventView(initialCategory: preferredCategory)
                .onDisappear { preferredCategory = nil }
        }
        .sheet(item: $selectedEvent) { event in
            AddEventView(eventToEdit: event)
        }
        .sheet(isPresented: $showingAddExpense) { AddExpenseView() }
        .sheet(isPresented: $showingNotifications) { NotificationsPanel() }
    }

    private var topBar: some View {
        HStack {
            Spacer()

            HStack(spacing: 2) {
                Text("Pet")
                    .foregroundStyle(AppTheme.navy)
                Text("Care")
                    .foregroundStyle(AppTheme.teal)
                ZStack {
                    Image(systemName: "figure.and.child.holdinghands")
                        .font(.system(size: 25, weight: .bold))
                        .foregroundStyle(AppTheme.teal)
                    Image(systemName: "heart.fill")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(.white)
                        .offset(y: 4)
                }
            }
            .font(.system(size: 34, weight: .bold, design: .rounded))

            Spacer()

            Button {
                showingNotifications = true
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell")
                        .font(.system(size: 23, weight: .semibold))
                        .foregroundStyle(AppTheme.navy)
                        .frame(width: 44, height: 44)

                    if store.unreadNotificationCount > 0 {
                        Text("\(min(store.unreadNotificationCount, 9))")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                            .frame(width: 20, height: 20)
                            .background(Color.red)
                            .clipShape(Circle())
                            .offset(x: 3, y: 1)
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Apri notifiche")
        }
        .padding(.leading, 44)
    }

    private var hero: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white, AppTheme.mint.opacity(0.72)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            BlobShape()
                .fill(AppTheme.mint)
                .frame(width: 220, height: 205)
                .offset(x: 35, y: 25)

            VStack(spacing: -14) {
                Text("🐶")
                    .font(.system(size: 100))
                HStack(spacing: -10) {
                    Text("🐱").font(.system(size: 70))
                    Text("🐰").font(.system(size: 62))
                    Text("🐦").font(.system(size: 50))
                }
            }
            .offset(x: 20, y: 22)

            VStack(alignment: .leading, spacing: 10) {
                Text("Ciao, \(store.profile?.displayName ?? "Amico")! 👋")
                    .font(.system(size: 29, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.navy)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text("Come sta la tua compagnia oggi?")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.navy.opacity(0.72))

                Button { showingAddPet = true } label: {
                    Label("Aggiungi bambino", systemImage: "plus")
                        .font(.headline)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 13)
                        .background(AppTheme.teal)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                        .shadow(color: AppTheme.teal.opacity(0.24), radius: 8, y: 5)
                }
                .padding(.top, 5)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 18)
            .padding(.top, 20)
            .padding(.bottom, 20)
            .padding(.trailing, 130)
        }
        .frame(height: 260)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
    }

    private var petsSection: some View {
        VStack(alignment: .leading, spacing: 13) {
            sectionHeader("I miei bambini", trailing: AnyView(
                NavigationLink {
                    PetsView()
                } label: {
                    HStack(spacing: 4) {
                        Text("Vedi tutti")
                        Image(systemName: "chevron.right")
                    }
                }
            ))

            if store.pets.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "pawprint.circle.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(AppTheme.teal)
                    Text("Nessun bambino")
                        .font(.headline)
                    Text("Aggiungi il tuo primo amico per iniziare.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button("Aggiungi ora") { showingAddPet = true }
                        .buttonStyle(.borderedProminent)
                        .tint(AppTheme.teal)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 22)
                .petCard()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(store.pets) { pet in
                            NavigationLink {
                                PetDetailView(pet: pet)
                            } label: {
                                PetMiniCard(pet: pet)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 3)
                }
            }
        }
    }

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 13) {
            sectionHeader("Prossimi impegni", trailing: AnyView(
                Button { preferredCategory = nil; showingAddEvent = true } label: {
                    Image(systemName: "plus")
                        .font(.headline)
                        .frame(width: 34, height: 34)
                        .background(AppTheme.teal)
                        .foregroundStyle(.white)
                        .clipShape(Circle())
                }
            ))

            if store.notificationEvents.isEmpty {
                HStack(spacing: 14) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.title2)
                        .foregroundStyle(AppTheme.teal)
                        .frame(width: 52, height: 52)
                        .background(AppTheme.mint)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Nessun impegno in programma")
                            .font(.headline)
                        Text("Aggiungi una visita, un farmaco o una toelettatura.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .petCard()
            } else {
                ForEach(store.upcomingEvents.prefix(5)) { event in
                    EventRow(event: event)
                        .contentShape(Rectangle())
                        .onTapGesture { selectedEvent = event }
                        .accessibilityAddTraits(.isButton)
                }
            }
        }
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 13) {
            Text("Azioni rapide")
                .font(.title2.bold())
                .foregroundStyle(AppTheme.navy)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 9), count: 4), spacing: 9) {
                QuickAction(title: "Nuova visita", icon: "cross.case.fill", background: AppTheme.mint, tint: AppTheme.tealDark) {
                    preferredCategory = .vet; showingAddEvent = true
                }
                QuickAction(title: "Nuovo farmaco", icon: "pill.fill", background: AppTheme.lavender, tint: .purple) {
                    preferredCategory = .medication; showingAddEvent = true
                }
                QuickAction(title: "Nuova toelettatura", icon: "scissors", background: AppTheme.peach, tint: .orange) {
                    preferredCategory = .grooming; showingAddEvent = true
                }
                QuickAction(title: "Aggiungi spesa", icon: "eurosign.circle.fill", background: AppTheme.sky, tint: .blue) {
                    showingAddExpense = true
                }
            }
        }
    }

    private func sectionHeader(_ title: String, trailing: AnyView) -> some View {
        HStack {
            Text(title)
                .font(.title2.bold())
                .foregroundStyle(AppTheme.navy)
            Spacer()
            trailing
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.tealDark)
        }
    }
}

struct PetMiniCard: View {
    let pet: Pet
    private var background: Color {
        let palette = [AppTheme.mint, AppTheme.lavender, AppTheme.peach, AppTheme.sky, AppTheme.pink]
        return palette[abs(pet.id.hashValue) % palette.count]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            PetAvatar(pet: pet, size: 120)
            Text(pet.name)
                .font(.headline)
                .foregroundStyle(AppTheme.navy)
                .lineLimit(1)
            Text(pet.species)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .frame(width: 156, alignment: .leading)
        .background(background.opacity(0.58))
        .clipShape(RoundedRectangle(cornerRadius: 23, style: .continuous))
        .overlay(alignment: .bottomTrailing) {
            Image(systemName: "figure.and.child.holdinghands")
                .font(.caption.bold())
                .foregroundStyle(AppTheme.teal)
                .frame(width: 31, height: 31)
                .background(.white)
                .clipShape(Circle())
                .shadow(color: AppTheme.navy.opacity(0.1), radius: 4, y: 2)
                .offset(x: 2, y: 2)
        }
        .shadow(color: AppTheme.navy.opacity(0.07), radius: 10, y: 5)
    }
}

struct PetAvatar: View {
    let pet: Pet
    var size: CGFloat

    var body: some View {
        Group {
            if let data = pet.photoData, let image = UIImage(data: data) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                ZStack {
                    LinearGradient(colors: [AppTheme.mint, .white], startPoint: .topLeading, endPoint: .bottomTrailing)
                    Image(systemName: "figure.and.child.holdinghands")
                        .font(.system(size: size * 0.35, weight: .bold))
                        .foregroundStyle(AppTheme.teal)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
    }
}

struct EventRow: View {
    @EnvironmentObject private var store: PetStore
    let event: PetEvent

    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: event.category.symbol)
                .font(.title2)
                .foregroundStyle(event.category.tintColor)
                .frame(width: 58, height: 58)
                .background(event.category.softColor)
                .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.headline)
                    .foregroundStyle(AppTheme.navy)
                Text(store.pet(for: event.petID)?.name ?? "Bambino")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(event.category.tintColor)
                HStack(spacing: 5) {
                    Image(systemName: "calendar")
                    Text(ItalianDate.full.string(from: event.date))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 4)

            VStack(alignment: .trailing, spacing: 10) {
                Text(relativeText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(event.category.tintColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(event.category.softColor)
                    .clipShape(Capsule())
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.tertiary)
            }
        }
        .petCard(13)
    }

    private var relativeText: String {
        let days = AppDateTime.calendar.dateComponents(
            [.day],
            from: AppDateTime.calendar.startOfDay(for: Date()),
            to: AppDateTime.calendar.startOfDay(for: event.date)
        ).day ?? 0
        if days <= 0 { return "Oggi" }
        if days == 1 { return "Domani" }
        return "Tra \(days) giorni"
    }
}

struct QuickAction: View {
    let title: String
    let icon: String
    let background: Color
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 9) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 45, height: 45)
                    .background(.white.opacity(0.82))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppTheme.navy)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity, minHeight: 112)
            .padding(.horizontal, 4)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}


private struct NotificationsPanel: View {
    @EnvironmentObject private var store: PetStore
    @Environment(\.dismiss) private var dismiss
    @State private var selectedEvent: PetEvent?

    var body: some View {
        NavigationStack {
            Group {
                if store.notificationEvents.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "bell.slash.fill")
                            .font(.system(size: 52))
                            .foregroundStyle(AppTheme.teal)
                        Text("Nessuna notifica")
                            .font(.title3.bold())
                            .foregroundStyle(AppTheme.navy)
                        Text("Qui troverai visite, farmaci, vaccini e toelettature in arrivo.")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 28)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white)
                } else {
                    List(store.notificationEvents) { event in
                        Button {
                            store.markNotificationRead(for: event)
                            selectedEvent = event
                        } label: {
                            notificationRow(for: event)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(
                            store.isNotificationRead(for: event)
                                ? Color.white
                                : AppTheme.mint.opacity(0.22)
                        )
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Notifiche")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if store.unreadNotificationCount > 0 {
                        Button("Segna tutte lette") {
                            store.markAllNotificationsRead()
                        }
                        .font(.subheadline.weight(.semibold))
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Chiudi") { dismiss() }
                }
            }
            .sheet(item: $selectedEvent) { event in
                AddEventView(eventToEdit: event)
            }
        }
    }

    private func notificationRow(for event: PetEvent) -> some View {
        let isRead = store.isNotificationRead(for: event)

        return HStack(spacing: 14) {
            Image(systemName: event.category.symbol)
                .font(.title3)
                .foregroundStyle(isRead ? Color.secondary : AppTheme.tealDark)
                .frame(width: 44, height: 44)
                .background(isRead ? Color(.secondarySystemBackground) : AppTheme.mint)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(isRead ? .headline.weight(.regular) : .headline)
                    .foregroundStyle(AppTheme.navy)
                Text(store.pet(for: event.petID)?.name ?? "Bambino")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isRead ? Color.secondary : AppTheme.tealDark)
                Text(ItalianDate.full.string(from: event.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if !isRead {
                Circle()
                    .fill(Color.red)
                    .frame(width: 9, height: 9)
                    .accessibilityLabel("Non letta")
            }

            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
        .padding(.vertical, 4)
    }
}

