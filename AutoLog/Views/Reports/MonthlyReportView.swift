import SwiftUI

public struct MonthlyReportView: View {
    @ObservedObject var storage = StorageManager.shared
    @State private var selectedDate = Date()
    @State private var generatedPdfData: Data?
    @State private var showingPdfSheet = false
    @State private var showingShareSheet = false
    @State private var isSendingEmail = false
    @State private var alertMessage: String?
    @State private var showingAlert = false

    private var monthName: String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "nl_NL")
        df.dateFormat = "LLLL yyyy"
        return df.string(from: selectedDate).capitalized
    }

    private var tripsInSelectedMonth: [Trip] {
        let calendar = Calendar.current
        let targetYear = calendar.component(.year, from: selectedDate)
        let targetMonth = calendar.component(.month, from: selectedDate)
        return storage.trips.filter {
            let y = calendar.component(.year, from: $0.startTime)
            let m = calendar.component(.month, from: $0.startTime)
            return y == targetYear && m == targetMonth
        }
    }

    private var totalKm: Double { tripsInSelectedMonth.reduce(0) { $0 + $1.distanceInKm } }
    private var workBizKm: Double { tripsInSelectedMonth.filter { $0.tripType == .workBusiness }.reduce(0) { $0 + $1.distanceInKm } }
    private var workPrivKm: Double { tripsInSelectedMonth.filter { $0.tripType == .workPrivate }.reduce(0) { $0 + $1.distanceInKm } }
    private var privPrivKm: Double { tripsInSelectedMonth.filter { $0.tripType == .privatePrivate }.reduce(0) { $0 + $1.distanceInKm } }

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidBackground()

                ScrollView {
                    VStack(spacing: 20) {
                        // Month Picker Card
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Selecteer Periode")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)

                            DatePicker(
                                "Maand & Jaar",
                                selection: $selectedDate,
                                displayedComponents: [.date]
                            )
                            .datePickerStyle(.compact)
                        }
                        .padding(18)
                        .liquidGlass(cornerRadius: 22, borderOpacity: 0.3)

                        // Summary Stats Card
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Overzicht \(monthName)")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                Spacer()
                                Text("\(tripsInSelectedMonth.count) ritten")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.2))
                                    .foregroundColor(.blue)
                                    .clipShape(Capsule())
                            }

                            Divider()
                                .background(Color.white.opacity(0.15))

                            VStack(spacing: 12) {
                                summaryRow(title: "Totaal Gereden", value: String(format: "%.1f km", totalKm), color: .blue)
                                summaryRow(title: "Zakelijk (Werkauto)", value: String(format: "%.1f km", workBizKm), color: .cyan)
                                summaryRow(
                                    title: "Privé (Werkauto)",
                                    value: String(format: "%.1f km", workPrivKm),
                                    color: workPrivKm > storage.settings.maxTaxFreePrivateKm ? .red : .orange
                                )
                                summaryRow(title: "Privé (Privéauto)", value: String(format: "%.1f km", privPrivKm), color: .green)
                            }

                            if workPrivKm > storage.settings.maxTaxFreePrivateKm {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.red)
                                    Text("Let op: de 500 km norm voor privégebruik in de werkauto is overschreden!")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.red)
                                }
                                .padding(10)
                                .background(Color.red.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                        }
                        .padding(20)
                        .liquidGlass(cornerRadius: 24, borderOpacity: 0.35)

                        // Action Buttons
                        VStack(spacing: 14) {
                            Button(action: openPdfPreview) {
                                HStack {
                                    Image(systemName: "doc.text.fill")
                                    Text("Bekijk Belastingdienst PDF")
                                        .fontWeight(.bold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    LinearGradient(
                                        colors: [.blue, .cyan],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .shadow(color: .blue.opacity(0.4), radius: 10, y: 4)
                            }

                            Button(action: sendEmailReport) {
                                HStack {
                                    if isSendingEmail {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Image(systemName: "envelope.fill")
                                    }
                                    Text(isSendingEmail ? "Verzenden via Gmail..." : "Verstuur naar Inbox (\(storage.settings.recipientEmail.isEmpty ? "Stel e-mail in" : storage.settings.recipientEmail))")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(storage.settings.recipientEmail.isEmpty ? AnyView(Color.gray.opacity(0.4)) : AnyView(LinearGradient(colors: [.indigo, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)))
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .shadow(color: storage.settings.recipientEmail.isEmpty ? .clear : .indigo.opacity(0.35), radius: 8, y: 3)
                            }
                            .disabled(isSendingEmail || storage.settings.recipientEmail.isEmpty)

                            Button(action: sharePdf) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Deel / Exporteer PDF...")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .liquidGlass(cornerRadius: 16, borderOpacity: 0.25)
                                .foregroundColor(.primary)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Rapportages")
            .sheet(isPresented: $showingPdfSheet) {
                if let data = generatedPdfData {
                    PDFViewerSheet(pdfData: data, title: "Rapport \(monthName)")
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let data = generatedPdfData {
                    ShareActivityView(activityItems: [data])
                }
            }
            .alert("E-mail Verzending", isPresented: $showingAlert) {
                Button("OK") {}
            } message: {
                Text(alertMessage ?? "")
            }
        }
    }

    private func summaryRow(title: String, value: String, color: Color) -> some View {
        HStack {
            HStack(spacing: 8) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
    }

    private func preparePdf() -> Data {
        let data = PDFReportGenerator.shared.generateMonthlyReport(
            for: selectedDate,
            trips: storage.trips,
            settings: storage.settings
        )
        self.generatedPdfData = data
        return data
    }

    private func openPdfPreview() {
        let _ = preparePdf()
        showingPdfSheet = true
    }

    private func sharePdf() {
        let _ = preparePdf()
        showingShareSheet = true
    }

    private func sendEmailReport() {
        let pdf = preparePdf()
        isSendingEmail = true

        Task {
            do {
                try await MailDispatcherService.shared.sendMonthlyReportEmail(
                    pdfData: pdf,
                    recipientEmail: storage.settings.recipientEmail,
                    monthName: monthName,
                    driverName: storage.settings.driverName,
                    settings: storage.settings
                )
                DispatchQueue.main.async {
                    self.isSendingEmail = false
                    self.alertMessage = "Het rittenoverzicht voor \(monthName) is succesvol verzonden naar \(storage.settings.recipientEmail)!"
                    self.showingAlert = true
                }
            } catch {
                DispatchQueue.main.async {
                    self.isSendingEmail = false
                    self.alertMessage = "Verzenden mislukt: \(error.localizedDescription)"
                    self.showingAlert = true
                }
            }
        }
    }
}
