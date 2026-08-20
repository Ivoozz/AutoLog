import SwiftUI
import PDFKit

public struct PDFKitRepresentedView: UIViewRepresentable {
    let pdfData: Data

    public func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.document = PDFDocument(data: pdfData)
        return pdfView
    }

    public func updateUIView(_ uiView: PDFView, context: Context) {
        if uiView.document == nil {
            uiView.document = PDFDocument(data: pdfData)
        }
    }
}

public struct PDFViewerSheet: View {
    let pdfData: Data
    let title: String
    @Environment(\.dismiss) private var dismiss
    @State private var showingShareSheet = false

    public var body: some View {
        NavigationStack {
            PDFKitRepresentedView(pdfData: pdfData)
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Sluiten") { dismiss() }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: { showingShareSheet = true }) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
                .sheet(isPresented: $showingShareSheet) {
                    ShareActivityView(activityItems: [pdfData])
                }
        }
    }
}

public struct ShareActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    public func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }

    public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
