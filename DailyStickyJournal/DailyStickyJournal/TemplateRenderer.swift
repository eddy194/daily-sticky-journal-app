import Foundation

enum TemplateRenderer {
    static func render(template: String, for date: Date, calendar: Calendar = .current, locale: Locale = .current) -> String {
        let normalizedTemplate: String = {
            // Allow users to paste templates with literal "\n" sequences.
            if template.contains("\\n"), !template.contains("\n") {
                return template
                    .replacingOccurrences(of: "\\r\\n", with: "\n")
                    .replacingOccurrences(of: "\\n", with: "\n")
                    .replacingOccurrences(of: "\\t", with: "\t")
            }
            return template
        }()

        let localizedDate: String = {
            let formatter = DateFormatter()
            formatter.calendar = calendar
            formatter.locale = locale
            formatter.timeZone = calendar.timeZone
            formatter.dateStyle = .long
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }()

        let isoDate: String = DateKey.from(date: date, calendar: calendar)

        let weekday: String = {
            let formatter = DateFormatter()
            formatter.calendar = calendar
            formatter.locale = locale
            formatter.timeZone = calendar.timeZone
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        }()

        return normalizedTemplate
            .replacingOccurrences(of: "{{date}}", with: localizedDate)
            .replacingOccurrences(of: "{{iso_date}}", with: isoDate)
            .replacingOccurrences(of: "{{weekday}}", with: weekday)
    }
}
