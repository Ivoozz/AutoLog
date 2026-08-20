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
            ScrollView {
                VStack(spacing: 20) {
                    // Month Picker Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Selecteer Periode")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        DatePicker(
                            "Maand & Jaar",
                            selection: $selectedDate,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.compact)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(UIColor.secondarySystemGroupedBackground))
                    )

                    // Summary Stats Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Overzicht \(monthName)")
                                .font(.headline)
                                .fontWeight(.bold)
                            Spacer()
                            Text("\(tripsInSelectedMonth.count) ritten")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.12))
                                .foregroundColor(.blue)
                                .cornerRadius(6)
                        }

                        Divider()

                        VStack(spacing: 12) {
                            summaryRow(title: "Totaal Gereden", value: String(format: "%.1f km", totalKm), color: .blue)
                            summaryRow(title: "Zakelijk (Werkauto)", value: String(format: "%.1f km", workBizKm), color: .teal)
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
                                    .foregroundColor(.red)
                            }
                            .padding(8)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(UIColor.secondarySystemGroupedBackground))
                    )

                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: openPdfPreview) {
                            HStack {
                                Image(systemName: "doc.text.fill")
                                Text("Bekijk Belastingdienst PDF")
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }

                        Button(action: sendEmailReport) {
                            HStack {
                                if isSendingEmail {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "envelope.fill")
                                }
                                Text(isSendingEmail ? "Verzenden..." : "Verstuur naar Inbox (\(storage.settings.recipientEmail.isEmpty ? "Stel e-mail in" : storage.settings.recipientEmail))")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(storage.settings.recipientEmail.isEmpty ? Color.gray : Color.indigo)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(isSendingEmail || storage.settings.recipientEmail.isEmpty)

                        Button(action: sharePdf) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Deel / Exporteer PDF...")
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Rapportages")
            .background(Color(UIColor.systemGroupedBackground))
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
                    apiKey: storage.settings.resendApiKey
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
