import Foundation
import UIKit
import PDFKit

public final class PDFReportGenerator {
    public static let shared = PDFReportGenerator()

    private init() {}

    public func generateMonthlyReport(
        for month: Date,
        trips: [Trip],
        settings: UserSettings
    ) -> Data {
        let calendar = Calendar.current
        let monthComponents = calendar.dateComponents([.year, .month], from: month)
        
        let filteredTrips = trips.filter { trip in
            let tripComp = calendar.dateComponents([.year, .month], from: trip.startTime)
            return tripComp.year == monthComponents.year && tripComp.month == monthComponents.month
        }.sorted(by: { $0.startTime < $1.startTime })

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "nl_NL")
        dateFormatter.dateFormat = "LLLL yyyy"
        let monthTitle = dateFormatter.string(from: month).capitalized

        let totalKm = filteredTrips.reduce(0) { $0 + $1.distanceInKm }
        let workBusinessKm = filteredTrips.filter { $0.tripType == .workBusiness }.reduce(0) { $0 + $1.distanceInKm }
        let workPrivateKm = filteredTrips.filter { $0.tripType == .workPrivate }.reduce(0) { $0 + $1.distanceInKm }
        let privatePrivateKm = filteredTrips.filter { $0.tripType == .privatePrivate }.reduce(0) { $0 + $1.distanceInKm }

        let pageWidth: CGFloat = 841.89 // A4 Landscape (595.28 x 841.89)
        let pageHeight: CGFloat = 595.28
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let data = renderer.pdfData { context in
            var currentPage = 1
            var yOffset: CGFloat = 40.0
            let itemsPerPage = 12

            let chunks = filteredTrips.chunked(into: itemsPerPage)
            let totalPages = max(1, chunks.count)

            if chunks.isEmpty {
                // Empty report
                context.beginPage()
                drawHeader(
                    in: context.cgContext,
                    pageRect: pageRect,
                    monthTitle: monthTitle,
                    settings: settings,
                    totalKm: 0,
                    workBiz: 0,
                    workPriv: 0,
                    privPriv: 0,
                    page: 1,
                    totalPages: 1
                )
                let noDataText = "Geen geregistreerde ritten voor deze periode." as NSString
                noDataText.draw(at: CGPoint(x: 40, y: 220), withAttributes: [
                    .font: UIFont.systemFont(ofSize: 14, weight: .medium),
                    .foregroundColor: UIColor.secondaryLabel
                ])
                return
            }

            for chunk in chunks {
                context.beginPage()
                yOffset = drawHeader(
                    in: context.cgContext,
                    pageRect: pageRect,
                    monthTitle: monthTitle,
                    settings: settings,
                    totalKm: totalKm,
                    workBiz: workBusinessKm,
                    workPriv: workPrivateKm,
                    privPriv: privatePrivateKm,
                    page: currentPage,
                    totalPages: totalPages
                )

                // Draw Table
                yOffset = drawTable(trips: chunk, startY: yOffset, in: context.cgContext, pageRect: pageRect)
                currentPage += 1
            }
        }

        return data
    }

    private func drawHeader(
        in cgContext: CGContext,
        pageRect: CGRect,
        monthTitle: String,
        settings: UserSettings,
        totalKm: Double,
        workBiz: Double,
        workPriv: Double,
        privPriv: Double,
        page: Int,
        totalPages: Int
    ) -> CGFloat {
        let title = "RITTENREGISTRATIE - \(monthTitle.uppercased())" as NSString
        title.draw(at: CGPoint(x: 40, y: 30), withAttributes: [
            .font: UIFont.boldSystemFont(ofSize: 18),
            .foregroundColor: UIColor.black
        ])

        let driverInfo = "Bestuurder: \(settings.driverName)  |  Conform Belastingdienst Norm" as NSString
        driverInfo.draw(at: CGPoint(x: 40, y: 55), withAttributes: [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.darkGray
        ])

        // Summary Boxes
        let boxY: CGFloat = 75
        let boxHeight: CGFloat = 45
        let boxWidth: CGFloat = 175

        drawSummaryBox(x: 40, y: boxY, width: boxWidth, height: boxHeight, title: "TOTAAL GEREDEN", value: String(format: "%.1f km", totalKm), color: UIColor.systemBlue)
        drawSummaryBox(x: 225, y: boxY, width: boxWidth, height: boxHeight, title: "ZAKELIJK (WERK)", value: String(format: "%.1f km", workBiz), color: UIColor.systemTeal)
        drawSummaryBox(x: 410, y: boxY, width: boxWidth, height: boxHeight, title: "PRIVÉ (WERKAUTO)", value: String(format: "%.1f km", workPriv), color: workPriv > 500 ? UIColor.systemRed : UIColor.systemOrange)
        drawSummaryBox(x: 595, y: boxY, width: boxWidth, height: boxHeight, title: "PRIVÉ (PRIVÉAUTO)", value: String(format: "%.1f km", privPriv), color: UIColor.systemGreen)

        // Footer page number
        let pageStr = "Pagina \(page) van \(totalPages)" as NSString
        pageStr.draw(at: CGPoint(x: pageRect.width - 120, y: pageRect.height - 25), withAttributes: [
            .font: UIFont.systemFont(ofSize: 9),
            .foregroundColor: UIColor.gray
        ])

        return boxY + boxHeight + 20
    }

    private func drawSummaryBox(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, title: String, value: String, color: UIColor) {
        let rect = CGRect(x: x, y: y, width: width, height: height)
        let bgPath = UIBezierPath(roundedRect: rect, cornerRadius: 6)
        color.withAlphaComponent(0.12).setFill()
        bgPath.fill()

        let titleStr = title as NSString
        titleStr.draw(at: CGPoint(x: x + 10, y: y + 7), withAttributes: [
            .font: UIFont.boldSystemFont(ofSize: 8),
            .foregroundColor: color
        ])

        let valStr = value as NSString
        valStr.draw(at: CGPoint(x: x + 10, y: y + 20), withAttributes: [
            .font: UIFont.boldSystemFont(ofSize: 14),
            .foregroundColor: UIColor.black
        ])
    }

    private func drawTable(trips: [Trip], startY: CGFloat, in cgContext: CGContext, pageRect: CGRect) -> CGFloat {
        var currentY = startY
        let rowHeight: CGFloat = 26.0

        // Column X positions
        let colDatum: CGFloat = 40
        let colTijd: CGFloat = 110
        let colAuto: CGFloat = 175
        let colVan: CGFloat = 255
        let colNaar: CGFloat = 430
        let colType: CGFloat = 605
        let colKm: CGFloat = 705
        let colDoel: CGFloat = 755

        // Header Background
        let headerRect = CGRect(x: 40, y: currentY, width: pageRect.width - 80, height: 20)
        UIColor.systemGray5.setFill()
        UIRectFill(headerRect)

        let headers = [
            (colDatum, "Datum"),
            (colTijd, "Tijd"),
            (colAuto, "Kenteken"),
            (colVan, "Vertrekadres"),
            (colNaar, "Aankomstadres"),
            (colType, "Type"),
            (colKm, "KM"),
            (colDoel, "Doel/Omschrijving")
        ]

        for (x, hText) in headers {
            let nsText = hText as NSString
            nsText.draw(at: CGPoint(x: x, y: currentY + 4), withAttributes: [
                .font: UIFont.boldSystemFont(ofSize: 9),
                .foregroundColor: UIColor.black
            ])
        }

        currentY += 22

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yy"

        for (idx, trip) in trips.enumerated() {
            let rowRect = CGRect(x: 40, y: currentY, width: pageRect.width - 80, height: rowHeight)
            if idx % 2 == 1 {
                UIColor.systemGray6.withAlphaComponent(0.5).setFill()
                UIRectFill(rowRect)
            }

            let dStr = dateFormatter.string(from: trip.startTime) as NSString
            let tStr = "\(timeFormatter.string(from: trip.startTime)) - \(timeFormatter.string(from: trip.endTime))" as NSString
            let autoStr = trip.vehicleLicensePlate as NSString
            let vanStr = trip.startAddress as NSString
            let naarStr = trip.endAddress as NSString
            let typeStr = trip.tripType.shortLabel as NSString
            let kmStr = String(format: "%.1f", trip.distanceInKm) as NSString
            let doelStr = (trip.purposeDescription.isEmpty ? "-" : trip.purposeDescription) as NSString

            let rowFont = UIFont.systemFont(ofSize: 8)
            let attr: [NSAttributedString.Key: Any] = [.font: rowFont, .foregroundColor: UIColor.black]

            dStr.draw(at: CGPoint(x: colDatum, y: currentY + 6), withAttributes: attr)
            tStr.draw(at: CGPoint(x: colTijd, y: currentY + 6), withAttributes: attr)
            autoStr.draw(at: CGPoint(x: colAuto, y: currentY + 6), withAttributes: attr)
            vanStr.draw(in: CGRect(x: colVan, y: currentY + 6, width: 170, height: 16), withAttributes: attr)
            naarStr.draw(in: CGRect(x: colNaar, y: currentY + 6, width: 170, height: 16), withAttributes: attr)
            typeStr.draw(at: CGPoint(x: colType, y: currentY + 6), withAttributes: attr)
            kmStr.draw(at: CGPoint(x: colKm, y: currentY + 6), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 8), .foregroundColor: UIColor.black])
            doelStr.draw(in: CGRect(x: colDoel, y: currentY + 6, width: 70, height: 16), withAttributes: attr)

            currentY += rowHeight
        }

        return currentY
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
