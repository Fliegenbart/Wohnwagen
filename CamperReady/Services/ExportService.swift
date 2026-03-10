import Foundation
import UIKit

struct ExportFile {
    let title: String
    let url: URL
}

enum ExportService {
    static func exportCostsCSV(costs: [CostEntry]) throws -> ExportFile {
        let header = "Datum,Kategorie,Betrag EUR,Notiz\n"
        let rows = costs
            .sorted(by: { $0.date > $1.date })
            .map { "\($0.date.shortDateString()),\($0.category.title),\($0.amountEUR),\($0.notes.replacingOccurrences(of: ",", with: " "))" }
            .joined(separator: "\n")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("CamperReady-Kosten.csv")
        try (header + rows).write(to: url, atomically: true, encoding: .utf8)
        return ExportFile(title: "Kosten CSV", url: url)
    }

    static func exportMaintenanceCSV(entries: [MaintenanceEntry]) throws -> ExportFile {
        let header = "Datum,Kategorie,Titel,Kosten EUR,Notiz\n"
        let rows = entries
            .sorted(by: { $0.date > $1.date })
            .map { "\($0.date.shortDateString()),\($0.category.title),\($0.title),\($0.costEUR ?? 0),\($0.notes.replacingOccurrences(of: ",", with: " "))" }
            .joined(separator: "\n")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("CamperReady-Wartung.csv")
        try (header + rows).write(to: url, atomically: true, encoding: .utf8)
        return ExportFile(title: "Wartung CSV", url: url)
    }

    static func exportDashboardPDF(snapshot: DashboardSnapshot) throws -> ExportFile {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("CamperReady-Dashboard.pdf")
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 595, height: 842))
        try renderer.writePDF(to: url) { context in
            context.beginPage()
            let headline = [
                "CamperReady Bereitschaftsbericht",
                snapshot.vehicleName,
                snapshot.nextTripTitle,
                snapshot.overallHeadline
            ].joined(separator: "\n")

            let paragraph = NSMutableParagraphStyle()
            paragraph.lineSpacing = 6
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18, weight: .semibold),
                .paragraphStyle: paragraph
            ]
            headline.draw(in: CGRect(x: 40, y: 40, width: 515, height: 120), withAttributes: attributes)

            let body = snapshot.dimensions.map { result in
                "\(result.title): \(result.summary)\n\(result.reasons.joined(separator: " "))"
            }.joined(separator: "\n\n")
            body.draw(in: CGRect(x: 40, y: 180, width: 515, height: 600), withAttributes: [
                .font: UIFont.systemFont(ofSize: 14),
                .paragraphStyle: paragraph
            ])
        }
        return ExportFile(title: "Dashboard PDF", url: url)
    }
}
