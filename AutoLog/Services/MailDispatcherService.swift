import Foundation
import Network

public final class MailDispatcherService {
    public static let shared = MailDispatcherService()

    private init() {}

    public func sendMonthlyReportEmail(
        pdfData: Data,
        recipientEmail: String,
        monthName: String,
        driverName: String,
        settings: UserSettings
    ) async throws {
        guard !recipientEmail.isEmpty else {
            throw NSError(domain: "MailDispatcher", code: 400, userInfo: [NSLocalizedDescriptionKey: "Geen ontvangend e-mailadres ingesteld in Instellingen."])
        }

        if settings.sendViaGmailSmtp && !settings.gmailAddress.isEmpty && !settings.gmailAppPassword.isEmpty {
            try await sendViaGmailSmtp(
                pdfData: pdfData,
                toEmail: recipientEmail,
                monthName: monthName,
                driverName: driverName.isEmpty ? "Bestuurder" : driverName,
                gmailUser: settings.gmailAddress,
                gmailPassword: settings.gmailAppPassword
            )
        } else {
            print("Directe Gmail verzending niet geconfigureerd.")
        }
    }

    private func sendViaGmailSmtp(
        pdfData: Data,
        toEmail: String,
        monthName: String,
        driverName: String,
        gmailUser: String,
        gmailPassword: String
    ) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            let host = NWEndpoint.Host("smtp.gmail.com")
            let port = NWEndpoint.Port(integerLiteral: 465)

            let tlsOptions = NWProtocolTLS.Options()
            let tcpOptions = NWProtocolTCP.Options()
            let params = NWParameters(tls: tlsOptions, tcp: tcpOptions)

            let connection = NWConnection(host: host, port: port, using: params)
            let queue = DispatchQueue(label: "nl.ivoozz.autolog.smtp")

            var hasResponded = false
            func finish(with error: Error?) {
                guard !hasResponded else { return }
                hasResponded = true
                connection.cancel()
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }

            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    self.executeSmtpHandshake(
                        connection: connection,
                        toEmail: toEmail,
                        monthName: monthName,
                        driverName: driverName,
                        gmailUser: gmailUser,
                        gmailPassword: gmailPassword,
                        pdfData: pdfData,
                        completion: finish
                    )
                case .failed(let err):
                    finish(with: NSError(domain: "SMTP", code: 500, userInfo: [NSLocalizedDescriptionKey: "Verbinding met Gmail mislukt: \(err.localizedDescription)"]))
                case .cancelled:
                    break
                default:
                    break
                }
            }

            connection.start(queue: queue)
        }
    }

    private func executeSmtpHandshake(
        connection: NWConnection,
        toEmail: String,
        monthName: String,
        driverName: String,
        gmailUser: String,
        gmailPassword: String,
        pdfData: Data,
        completion: @escaping (Error?) -> Void
    ) {
        let cleanPassword = gmailPassword.replacingOccurrences(of: " ", with: "")
        let userB64 = gmailUser.data(using: .utf8)?.base64EncodedString() ?? ""
        let passB64 = cleanPassword.data(using: .utf8)?.base64EncodedString() ?? ""

        let boundary = "----=_AutoLog_\(UUID().uuidString)"
        let pdfB64 = pdfData.base64EncodedString(options: .lineLength64Characters)
        let filename = "Rittenregistratie_\(monthName.replacingOccurrences(of: " ", with: "_")).pdf"

        var messageData = ""
        messageData += "From: AutoLog <\(gmailUser)>\r\n"
        messageData += "To: <\(toEmail)>\r\n"
        messageData += "Subject: Rittenregistratie \(monthName) - \(driverName)\r\n"
        messageData += "MIME-Version: 1.0\r\n"
        messageData += "Content-Type: multipart/mixed; boundary=\"\(boundary)\"\r\n\r\n"

        // Body
        messageData += "--\(boundary)\r\n"
        messageData += "Content-Type: text/plain; charset=UTF-8\r\n\r\n"
        messageData += "Beste \(driverName),\r\n\r\n"
        messageData += "Hierbij ontvang je het automatische rittenoverzicht voor de periode \(monthName).\r\n"
        messageData += "Het bijgevoegde PDF-document is opgesteld conform de richtlijnen van de Belastingdienst.\r\n\r\n"
        messageData += "Met vriendelijke groet,\r\nAutoLog\r\n\r\n"

        // Attachment
        messageData += "--\(boundary)\r\n"
        messageData += "Content-Type: application/pdf; name=\"\(filename)\"\r\n"
        messageData += "Content-Disposition: attachment; filename=\"\(filename)\"\r\n"
        messageData += "Content-Transfer-Encoding: base64\r\n\r\n"
        messageData += "\(pdfB64)\r\n\r\n"
        messageData += "--\(boundary)--\r\n"

        let steps: [String] = [
            "EHLO localhost\r\n",
            "AUTH LOGIN\r\n",
            "\(userB64)\r\n",
            "\(passB64)\r\n",
            "MAIL FROM: <\(gmailUser)>\r\n",
            "RCPT TO: <\(toEmail)>\r\n",
            "DATA\r\n",
            "\(messageData)\r\n.\r\n",
            "QUIT\r\n"
        ]

        var currentStep = 0

        func sendNext() {
            if currentStep >= steps.count {
                completion(nil)
                return
            }

            let cmd = steps[currentStep]
            currentStep += 1

            let data = cmd.data(using: .utf8)!
            connection.send(content: data, completion: .contentProcessed { error in
                if let error = error {
                    completion(error)
                    return
                }

                // Read server response
                connection.receive(minimumIncompleteLength: 1, maximumLength: 1024) { responseData, _, _, recError in
                    if let recError = recError {
                        completion(recError)
                        return
                    }
                    if let resp = responseData, let text = String(data: resp, encoding: .utf8) {
                        let statusCode = text.prefix(3)
                        if statusCode.starts(with: "4") || statusCode.starts(with: "5") {
                            completion(NSError(domain: "GmailSMTP", code: 500, userInfo: [NSLocalizedDescriptionKey: "Gmail SMTP fout: \(text.trimmingCharacters(in: .whitespacesAndNewlines))"]))
                            return
                        }
                    }
                    sendNext()
                }
            })
        }

        // Read initial 220 banner first
        connection.receive(minimumIncompleteLength: 1, maximumLength: 1024) { _, _, _, error in
            if let error = error {
                completion(error)
            } else {
                sendNext()
            }
        }
    }
}
