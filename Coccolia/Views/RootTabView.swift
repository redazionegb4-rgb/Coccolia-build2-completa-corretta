import SwiftUI

struct RootTabView: View {
    @AppStorage("coccolia.onboarded") private var onboarded = false

    var body: some View {
        Group {
            if onboarded {
                CoccoliaTabs()
            } else {
                CoccoliaOnboarding(onboarded: $onboarded)
            }
        }
        .animation(.easeInOut, value: onboarded)
    }
}

struct CoccoliaOnboarding: View {
    @Binding var onboarded: Bool
    @AppStorage("parentName") private var parentName = ""
    @AppStorage("babyName") private var babyName = ""
    @AppStorage("babyBorn") private var born = true
    @AppStorage("babyDate") private var date = Date().timeIntervalSince1970
    @State private var step = 0

    var body: some View {
        ZStack {
            AppTheme.page.ignoresSafeArea()
            Circle()
                .fill(AppTheme.lavender.opacity(0.5))
                .frame(width: 340)
                .offset(x: 180, y: -340)

            VStack(spacing: 28) {
                Spacer()

                ZStack {
                    RoundedRectangle(cornerRadius: 34)
                        .fill(AppTheme.brandGradient)
                    Image(systemName: "figure.and.child.holdinghands")
                        .font(.system(size: 56, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 120, height: 120)
                .shadow(color: AppTheme.teal.opacity(0.25), radius: 20, y: 10)

                Text(step == 0 ? "Benvenuta in Coccolia" : "Conosciamoci meglio")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.navy)
                    .multilineTextAlignment(.center)

                Text(step == 0 ? "Tutto il mondo del tuo bambino, sempre con te." : "Pochi dettagli per creare uno spazio tutto vostro.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                VStack(spacing: 16) {
                    if step == 0 {
                        field("Il tuo nome", text: $parentName, icon: "person.fill")
                    } else {
                        Picker("", selection: $born) {
                            Text("È già nato").tag(true)
                            Text("Sono in gravidanza").tag(false)
                        }
                        .pickerStyle(.segmented)

                        field(born ? "Nome del bambino" : "Nome scelto", text: $babyName, icon: "heart.fill")

                        DatePicker(
                            born ? "Data di nascita" : "Data presunta del parto",
                            selection: Binding(
                                get: { Date(timeIntervalSince1970: date) },
                                set: { date = $0.timeIntervalSince1970 }
                            ),
                            displayedComponents: .date
                        )
                        .padding()
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    }

                    Button {
                        if step == 0 {
                            step = 1
                        } else {
                            onboarded = true
                        }
                    } label: {
                        Text(step == 0 ? "Continua" : "Entra in Coccolia")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppTheme.brandGradient)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                    .disabled(step == 0 ? parentName.isEmpty : babyName.isEmpty)
                    .opacity((step == 0 ? parentName.isEmpty : babyName.isEmpty) ? 0.5 : 1)
                }
                .padding(22)
                .background(.white.opacity(0.72))
                .clipShape(RoundedRectangle(cornerRadius: 28))

                Spacer()
            }
            .padding(24)
        }
    }

    private func field(_ title: String, text: Binding<String>, icon: String) -> some View {
        HStack {
            Image(systemName: icon).foregroundStyle(AppTheme.teal)
            TextField(title, text: text)
        }
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

struct CoccoliaTabs: View {
    var body: some View {
        TabView {
            NavigationStack { DashboardView() }
                .tabItem { Label("Oggi", systemImage: "house.fill") }
            NavigationStack { RoutineView() }
                .tabItem { Label("Routine", systemImage: "clock.fill") }
            NavigationStack { GrowthView() }
                .tabItem { Label("Crescita", systemImage: "chart.line.uptrend.xyaxis") }
            NavigationStack { MemoriesView() }
                .tabItem { Label("Ricordi", systemImage: "photo.on.rectangle.angled") }
            NavigationStack { MoreView() }
                .tabItem { Label("Altro", systemImage: "square.grid.2x2.fill") }
        }
        .tint(AppTheme.teal)
    }
}

struct DashboardView: View {
    @AppStorage("parentName") private var parent = ""
    @AppStorage("babyName") private var baby = ""
    @AppStorage("babyBorn") private var born = true

    private let cards = [
        ("Poppata", "drop.fill", "Ultima: 2 ore fa"),
        ("Sonno", "moon.stars.fill", "Oggi: 6h 20m"),
        ("Pannolino", "sparkles", "Ultimo: 45 min fa"),
        ("Crescita", "chart.line.uptrend.xyaxis", "Aggiorna misure")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Ciao, \(parent) 👋").font(.title2.bold())
                        Text(born ? "Ecco la giornata di \(baby)" : "Tu e \(baby), giorno dopo giorno")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Circle()
                        .fill(AppTheme.brandGradient)
                        .frame(width: 52, height: 52)
                        .overlay(Image(systemName: "figure.and.child.holdinghands").foregroundStyle(.white))
                }

                HeroCard()
                Text("Accesso rapido").font(.title3.bold())

                LazyVGrid(columns: [GridItem(), GridItem()], spacing: 14) {
                    ForEach(cards, id: \.0) { card in
                        NavigationLink {
                            QuickLogView(kind: card.0)
                        } label: {
                            VStack(alignment: .leading, spacing: 12) {
                                Image(systemName: card.1).font(.title2).foregroundStyle(AppTheme.teal)
                                Text(card.0).font(.headline).foregroundStyle(AppTheme.navy)
                                Text(card.2).font(.caption).foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 22))
                            .shadow(color: .black.opacity(0.04), radius: 10, y: 5)
                        }
                    }
                }

                Text("Prossimi appuntamenti").font(.title3.bold())
                HStack {
                    Image(systemName: "stethoscope").foregroundStyle(AppTheme.teal)
                    VStack(alignment: .leading) {
                        Text("Controllo pediatrico").fontWeight(.semibold)
                        Text("Martedì, 10:30").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                }
                .padding()
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .padding()
        }
        .background(AppTheme.page)
        .navigationTitle("Coccolia")
    }
}

struct HeroCard: View {
    @AppStorage("babyName") private var baby = ""

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 30)
                .fill(AppTheme.brandGradient)
                .frame(height: 190)

            Circle()
                .fill(.white.opacity(0.16))
                .frame(width: 160)
                .offset(x: 230, y: -50)

            VStack(alignment: .leading, spacing: 9) {
                Text("IL NOSTRO PICCOLO MONDO").font(.caption.bold()).tracking(1.4)
                Text(baby).font(.system(size: 34, weight: .bold, design: .rounded))
                Text("Ogni giorno una nuova scoperta ✨")
                HStack {
                    Label("3 mesi", systemImage: "birthday.cake.fill")
                    Spacer()
                    Label("Tutto bene", systemImage: "heart.fill")
                }
                .font(.subheadline.bold())
                .padding(.top, 10)
            }
            .foregroundStyle(.white)
            .padding(24)
        }
    }
}

struct RoutineView: View {
    private let items = [
        ("Poppata", "drop.fill", "Registra latte o allattamento"),
        ("Sonno", "moon.fill", "Inizio e fine riposo"),
        ("Pannolino", "sparkles", "Cambio e note"),
        ("Pappa", "fork.knife", "Pasti e nuovi alimenti"),
        ("Bagnetto", "bathtub.fill", "Cura e igiene"),
        ("Temperatura", "thermometer.medium", "Controlla la febbre")
    ]

    var body: some View {
        List(items, id: \.0) { item in
            NavigationLink {
                QuickLogView(kind: item.0)
            } label: {
                HStack(spacing: 15) {
                    Circle()
                        .fill(AppTheme.teal.opacity(0.12))
                        .frame(width: 48, height: 48)
                        .overlay(Image(systemName: item.1).foregroundStyle(AppTheme.teal))
                    VStack(alignment: .leading) {
                        Text(item.0).font(.headline)
                        Text(item.2).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.page)
        .navigationTitle("Routine")
    }
}

struct QuickLogView: View {
    let kind: String
    @State private var when = Date()
    @State private var note = ""
    @State private var saved = false

    var body: some View {
        Form {
            Section("Dettagli") {
                DatePicker("Quando", selection: $when)
                TextField("Aggiungi una nota", text: $note)
            }
            Section {
                Button("Salva \(kind)") { saved = true }
                    .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle(kind)
        .alert("Salvato!", isPresented: $saved) {
            Button("OK", role: .cancel) { }
        }
    }
}

struct GrowthView: View {
    @State private var weight = "6.4"
    @State private var height = "62"

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                MetricCard(title: "Peso", value: "\(weight) kg", icon: "scalemass.fill", progress: 0.68)
                MetricCard(title: "Altezza", value: "\(height) cm", icon: "ruler.fill", progress: 0.74)

                VStack(alignment: .leading, spacing: 14) {
                    Text("Nuova misurazione").font(.headline)
                    TextField("Peso in kg", text: $weight)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                    TextField("Altezza in cm", text: $height)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                    Button("Salva misurazione") { }
                        .buttonStyle(.borderedProminent)
                        .tint(AppTheme.teal)
                }
                .padding()
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 22))
            }
            .padding()
        }
        .background(AppTheme.page)
        .navigationTitle("Crescita")
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let progress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: icon).foregroundStyle(AppTheme.teal)
                Text(title).font(.headline)
                Spacer()
                Text(value).font(.title2.bold())
            }
            ProgressView(value: progress).tint(AppTheme.teal)
            Text("Crescita regolare").font(.caption).foregroundStyle(.secondary)
        }
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }
}

struct MemoriesView: View {
    private let moments = [
        ("Primo sorriso", "face.smiling.fill"),
        ("Primo bagnetto", "bathtub.fill"),
        ("Prima pappa", "fork.knife"),
        ("Primi passi", "figure.walk")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ZStack {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(AppTheme.lavender.opacity(0.55))
                        .frame(height: 190)
                    VStack {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 45))
                            .foregroundStyle(AppTheme.teal)
                        Text("Aggiungi un ricordo").font(.title3.bold())
                        Text("Foto, parole e prime volte").foregroundStyle(.secondary)
                    }
                }

                Text("Prime volte").font(.title2.bold())
                ForEach(moments, id: \.0) { moment in
                    HStack {
                        Circle()
                            .fill(AppTheme.teal.opacity(0.12))
                            .frame(width: 48, height: 48)
                            .overlay(Image(systemName: moment.1).foregroundStyle(AppTheme.teal))
                        Text(moment.0).font(.headline)
                        Spacer()
                        Image(systemName: "plus.circle.fill").foregroundStyle(AppTheme.teal)
                    }
                    .padding()
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
            }
            .padding()
        }
        .background(AppTheme.page)
        .navigationTitle("Ricordi")
    }
}

struct MoreView: View {
    @AppStorage("coccolia.onboarded") private var onboarded = true
    private let sections = [
        ("Salute", "cross.case.fill"),
        ("Agenda", "calendar"),
        ("Vaccini", "syringe.fill"),
        ("Documenti", "doc.fill"),
        ("Spese", "eurosign.circle.fill"),
        ("Liste", "checklist"),
        ("Notifiche", "bell.fill"),
        ("Impostazioni", "gearshape.fill")
    ]

    var body: some View {
        List {
            Section {
                ForEach(sections, id: \.0) { item in
                    NavigationLink {
                        GenericFeature(title: item.0, icon: item.1)
                    } label: {
                        Label(item.0, systemImage: item.1)
                    }
                }
            }
            Section {
                Button("Configura un altro profilo") { onboarded = false }
                    .foregroundStyle(.red)
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.page)
        .navigationTitle("Tutto Coccolia")
    }
}

struct GenericFeature: View {
    let title: String
    let icon: String

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(AppTheme.teal)
            Text(title).font(.largeTitle.bold())
            Text("Questa sezione è pronta per raccogliere e organizzare tutte le informazioni importanti.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Aggiungi") { }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.teal)
        }
        .padding()
        .navigationTitle(title)
    }
}
