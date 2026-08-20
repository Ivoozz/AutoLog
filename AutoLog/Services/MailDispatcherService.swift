import Foundation

public final class MailDispatcherService {
    public static let shared = MailDispatcherService()

    private init() {}

    public func sendMonthlyReportEmail(
        pdfData: Data,
        recipientEmail: String,
        monthName: String,
        driverName: String,
        apiKey: String
    ) async throws {
        guard !recipientEmail.isEmpty else {
            throw NSError(domain: "MailDispatcher", code: 400, userInfo: [NSLocalizedDescriptionKey: "Geen ontvangend e-mailadres ingesteld."])
        }

        // If Resend API key is provided, send automatically in background
        if !apiKey.isEmpty {
            try await sendViaResend(
                pdfData: pdfData,
                toEmail: recipientEmail,
                monthName: monthName,
                driverName: driverName,
                apiKey: apiKey
            )
        } else {
            print("Geen Resend API sleutel gevonden. Gebruik lokaal delen of stel API in.")
        }
    }

    private func sendViaResend(
        pdfData: Data,
        toEmail: String,
        monthName: String,
        driverName: String,
        apiKey: String
    ) async throws {
        let url = URL(string: "https://api.resend.com/emails")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let base64Pdf = pdfData.base64EncodedString()
        let filename = "Rittenregistratie_\(monthName.replacingOccurrences(of: " ", with: "_")).pdf"

        let body: [String: Any] = [
            "from": "AutoLog <noreply@resend.dev>",
            "to": [toEmail],
            "subject": "📊 Rittenregistratie \(monthName) - \(driverName)",
            "html": """
            <h2>Beste \(driverName),</h2>
            <p>Hierbij ontvang je het automatische rittenoverzicht voor de periode <strong>\(monthName)</strong>.</p>
            <p>Het bijgevoegde PDF-document is opgesteld conform de richtlijnen van de Belastingdienst.</p>
            <hr/>
            <p><small>Automatisch gegenereerd door AutoLog.</small></p>
            """,
            "attachments": [
                [
                    "filename": filename,
                    "content": base64Pdf
                ]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let errorText = String(data: data, encoding: .utf8) ?? "Onbekende fout"
            throw NSError(domain: "MailDispatcher", code: 500, userInfo: [NSLocalizedDescriptionKey: "Verzenden mislukt: \(errorText)"])
        }
    }
}
