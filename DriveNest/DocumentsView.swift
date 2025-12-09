import SwiftUI

struct DocumentsView: View {
    var body: some View {
        ZStack {
            BackgroundView()
                .overlay(
                    Image(systemName: "feather.fill")
                        .font(.system(size: 200))
                        .foregroundColor(.goldNeon.opacity(0.07))
                        .offset(x: 100, y: 200)
                )
            
            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach(sampleDocuments) { doc in
                        DocumentRow(doc: doc)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Documents")
    }
}

struct DocumentRow: View {
    let doc: Document
    
    var body: some View {
        HStack {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 32))
                .foregroundColor(.goldNeon)
                .frame(width: 60)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(doc.name)
                    .font(.title3.bold())
                    .foregroundColor(.white)
                
                Text("Expires \(doc.expirationDate, format: .dateTime.day().month().year())")
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                Circle().fill(statusColor).frame(width: 20)
                Button("Remind") {
                    // remind
                }
                .font(.caption.bold())
                .foregroundColor(.goldNeon)
            }
        }
        .padding(24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(statusColor.opacity(0.4), lineWidth: 2))
    }
    
    var statusColor: Color {
        switch doc.status {
        case .green: return .green
        case .yellow: return .yellow
        case .red: return .red
        }
    }
}

#Preview {
    DocumentsView()
}
