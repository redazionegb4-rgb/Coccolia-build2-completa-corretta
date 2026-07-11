import SwiftUI
import PhotosUI

struct AddPetView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: PetStore
    @State private var photoItem: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var name = ""
    @State private var species = "Cane"
    @State private var breed = ""
    @State private var sex: Pet.Sex = .unknown
    @State private var hasBirthDate = false
    @State private var birthDate = Date()
    @State private var weight = ""
    @State private var microchip = ""
    @State private var mainColor = ""
    @State private var features = ""
    @State private var allergies = ""
    @State private var notes = ""
    @State private var reminders = true

    private let speciesOptions = [("Cane","dog.fill"),("Gatto","cat.fill"),("Coniglio","hare.fill"),("Uccello","bird.fill"),("Altro","ellipsis")]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    hero
                    card("1. Foto dell’bambino") { photoPicker }
                    card("2. Informazioni generali") { generalInfo }
                    card("3. Salute e identificazione") { healthInfo }
                    card("4. Caratteristiche") { characteristics }
                    card("5. Allergie e note") { notesSection }
                    card("6. Promemoria personalizzati") { remindersSection }
                    HStack(spacing: 10) {
                        Image(systemName: "shield.checkered").foregroundStyle(AppTheme.teal)
                        VStack(alignment: .leading) {
                            Text("I tuoi dati sono al sicuro").font(.subheadline.bold())
                            Text("Tutte le informazioni restano sul dispositivo.").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding().background(AppTheme.mint).clipShape(RoundedRectangle(cornerRadius: 20))
                    Button(action: save) {
                        Label("Salva profilo", systemImage: "figure.and.child.holdinghands")
                            .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(AppTheme.brandGradient).foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                    }.disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    Button("Annulla") { dismiss() }.foregroundStyle(AppTheme.tealDark)
                }
                .padding(18).padding(.bottom, 20)
            }
            .background(AppTheme.page.ignoresSafeArea())
            .navigationTitle("Aggiungi bambino")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button { dismiss() } label: { Image(systemName: "chevron.left") } } }
        }
    }

    private var hero: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Aggiungi il tuo\nnuovo amico").font(.system(size: 28, weight: .bold, design: .rounded)).foregroundStyle(AppTheme.navy)
                Text("Compila le informazioni per creare il profilo.").font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            ZStack {
                BlobShape().fill(AppTheme.mint).frame(width: 145, height: 125)
                HStack(spacing: -8) {
                    Text("🐶").font(.system(size: 58))
                    Text("🐱").font(.system(size: 48)).offset(y: 25)
                    Text("🐰").font(.system(size: 42)).offset(y: 34)
                }
            }
        }
    }

    private func card<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) { Text(title).font(.title3.bold()).foregroundStyle(AppTheme.navy); content() }
            .petCard(18)
    }

    private var photoPicker: some View {
        PhotosPicker(selection: $photoItem, matching: .images) {
            Group {
                if let photoData, let image = UIImage(data: photoData) { Image(uiImage: image).resizable().scaledToFill() }
                else {
                    VStack(spacing: 10) {
                        Image(systemName: "camera.fill").font(.title2).foregroundStyle(.white).frame(width: 58,height:58).background(AppTheme.teal).clipShape(Circle())
                        Text("Aggiungi una foto").font(.headline).foregroundStyle(AppTheme.navy)
                        Text("JPG, PNG o HEIC").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 190)
            .background(Color.white)
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(style: StrokeStyle(lineWidth: 1.5, dash: [7])).foregroundStyle(AppTheme.navy.opacity(0.15)))
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .onChange(of: photoItem) { _, newItem in Task { photoData = try? await newItem?.loadTransferable(type: Data.self) } }
    }

    private var generalInfo: some View {
        VStack(spacing: 15) {
            field("Nome dell’bambino *", placeholder: "Es. Milo", text: $name, icon: "figure.and.child.holdinghands")
            VStack(alignment: .leading, spacing: 10) {
                Text("Tipo di bambino *").font(.subheadline.bold())
                HStack(spacing: 9) {
                    ForEach(speciesOptions, id: \.0) { item in
                        Button { species = item.0 } label: {
                            VStack(spacing: 6) { Image(systemName: item.1).font(.title3); Text(item.0).font(.caption2) }
                                .foregroundStyle(species == item.0 ? AppTheme.tealDark : AppTheme.navy)
                                .frame(maxWidth: .infinity).padding(.vertical, 10)
                                .background(species == item.0 ? AppTheme.mint : Color.white)
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(species == item.0 ? AppTheme.teal : Color.gray.opacity(0.2)))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }.buttonStyle(.plain)
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
            if hasBirthDate { DatePicker("Data di nascita", selection: $birthDate, displayedComponents: .date).environment(\.locale, Locale(identifier: "it_IT")) }
        }
    }

    private var healthInfo: some View { VStack(spacing: 14) { field("Peso attuale", placeholder: "0,0 kg", text: $weight, icon: "scalemass.fill"); field("Numero microchip", placeholder: "Inserisci il numero (se disponibile)", text: $microchip, icon: "cpu") } }
    private var characteristics: some View { VStack(spacing: 14) { field("Colore principale", placeholder: "Es. Marrone, bianco...", text: $mainColor, icon: "paintpalette.fill"); multiline("Caratteristiche distintive", placeholder: "Macchia sull’occhio, pelo lungo...", text: $features) } }
    private var notesSection: some View { VStack(spacing: 14) { multiline("Allergie o intolleranze", placeholder: "Es. Allergico ai pollini...", text: $allergies); multiline("Note aggiuntive", placeholder: "Scrivi qui note importanti...", text: $notes) } }
    private var remindersSection: some View { Toggle(isOn: $reminders) { VStack(alignment: .leading, spacing: 4) { Text("Imposta promemoria").font(.headline); Text("Per vaccinazioni, antiparassitari o toelettatura.").font(.caption).foregroundStyle(.secondary) } }.tint(AppTheme.teal) }

    private func field(_ label: String, placeholder: String, text: Binding<String>, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 7) { Text(label).font(.subheadline.bold()); HStack { Image(systemName: icon).foregroundStyle(AppTheme.teal); TextField(placeholder, text: text) }.padding(14).background(AppTheme.page).clipShape(RoundedRectangle(cornerRadius: 15)) }
    }
    private func multiline(_ label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 7) { Text(label).font(.subheadline.bold()); TextField(placeholder, text: text, axis: .vertical).lineLimit(3...5).padding(14).background(AppTheme.page).clipShape(RoundedRectangle(cornerRadius: 15)) }
    }
    private func sexButton(_ value: Pet.Sex, icon: String, tint: Color) -> some View {
        Button { sex = value } label: { VStack(spacing: 6) { Image(systemName: icon).font(.title2); Text(value.rawValue).font(.caption.bold()) }.frame(maxWidth: .infinity).padding(.vertical, 12).foregroundStyle(tint).background(sex == value ? tint.opacity(0.14) : AppTheme.page).clipShape(RoundedRectangle(cornerRadius: 16)) }.buttonStyle(.plain)
    }

    private func save() {
        let parsedWeight = Double(weight.replacingOccurrences(of: ",", with: "."))
        store.addPet(Pet(name: name, species: species, breed: breed, sex: sex, birthDate: hasBirthDate ? birthDate : nil, weight: parsedWeight, microchip: microchip, mainColor: mainColor, distinctiveFeatures: features, allergies: allergies, notes: notes, photoData: photoData))
        dismiss()
    }
}

struct BlobShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path(); p.move(to: CGPoint(x: rect.minX + rect.width*0.15, y: rect.minY + rect.height*0.15));
        p.addCurve(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height*0.35), control1: CGPoint(x: rect.minX + rect.width*0.45, y: rect.minY - 10), control2: CGPoint(x: rect.maxX + 10, y: rect.minY));
        p.addCurve(to: CGPoint(x: rect.maxX - rect.width*0.1, y: rect.maxY), control1: CGPoint(x: rect.maxX, y: rect.maxY*0.65), control2: CGPoint(x: rect.maxX + 10, y: rect.maxY));
        p.addCurve(to: CGPoint(x: rect.minX, y: rect.maxY*0.72), control1: CGPoint(x: rect.width*0.55, y: rect.maxY + 10), control2: CGPoint(x: rect.minX, y: rect.maxY));
        p.addCurve(to: CGPoint(x: rect.minX + rect.width*0.15, y: rect.minY + rect.height*0.15), control1: CGPoint(x: rect.minX - 5, y: rect.height*0.4), control2: CGPoint(x: rect.minX, y: rect.minY)); return p
    }
}
