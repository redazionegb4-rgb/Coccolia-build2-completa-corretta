import SwiftUI

enum AppTheme {
    static let page = Color(red: 0.985, green: 0.965, blue: 0.945)
    static let navy = Color(red: 0.20, green: 0.18, blue: 0.28)
    static let teal = Color(red: 0.84, green: 0.48, blue: 0.58)
    static let tealDark = Color(red: 0.63, green: 0.29, blue: 0.42)
    static let mint = Color(red: 0.91, green: 0.83, blue: 0.75)
    static let pink = Color(red: 1.00, green: 0.90, blue: 0.94)
    static let peach = Color(red: 1.00, green: 0.93, blue: 0.84)
    static let lavender = Color(red: 0.87, green: 0.81, blue: 0.94)
    static let sky = Color(red: 0.88, green: 0.94, blue: 1.00)
    static let lemon = Color(red: 1.00, green: 0.97, blue: 0.78)

    static let brandGradient = LinearGradient(
        colors: [
            Color(red: 0.93, green: 0.56, blue: 0.66),
            Color(red: 0.68, green: 0.53, blue: 0.86)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct CardModifier: ViewModifier {
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: AppTheme.navy.opacity(0.07), radius: 14, y: 7)
    }
}

extension View {
    func petCard(_ padding: CGFloat = 16) -> some View {
        modifier(CardModifier(padding: padding))
    }
}

extension PetEvent.Category {
    var tintColor: Color {
        switch self {
        case .vaccine:
            return Color(red: 0.30, green: 0.65, blue: 0.34)
        case .medication:
            return Color(red: 0.56, green: 0.31, blue: 0.88)
        case .vet:
            return Color(red: 0.15, green: 0.46, blue: 0.86)
        case .grooming:
            return Color(red: 0.92, green: 0.27, blue: 0.48)
        case .custom:
            return Color(red: 0.95, green: 0.55, blue: 0.18)
        }
    }

    var softColor: Color {
        tintColor.opacity(0.13)
    }
}

enum AppDateTime {
    static let timeZone = TimeZone(identifier: "Europe/Rome")!

    static var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "it_IT")
        calendar.timeZone = timeZone
        return calendar
    }()
}

enum ItalianDate {
    static let full: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "it_IT")
        formatter.calendar = AppDateTime.calendar
        formatter.timeZone = AppDateTime.timeZone
        formatter.dateFormat = "d MMMM yyyy • HH:mm"
        return formatter
    }()

    static let dateOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "it_IT")
        formatter.calendar = AppDateTime.calendar
        formatter.timeZone = AppDateTime.timeZone
        formatter.dateFormat = "d MMMM yyyy"
        return formatter
    }()

    static let timeOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "it_IT")
        formatter.calendar = AppDateTime.calendar
        formatter.timeZone = AppDateTime.timeZone
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}
