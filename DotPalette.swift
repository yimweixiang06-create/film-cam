import SwiftUI

struct DotPalette: View {
    @Binding var point: CGPoint
    private let columns = 11
    private let rows = 11

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(colors: [
                            Color(red: 0.68, green: 0.78, blue: 0.76),
                            Color(red: 0.30, green: 0.42, blue: 0.45),
                            Color(red: 0.88, green: 0.24, blue: 0.34)
                        ], startPoint: .topLeading, endPoint: .topTrailing)
                    )
                    .overlay(alignment: .bottom) {
                        LinearGradient(colors: [.clear, .black.opacity(0.78)], startPoint: .center, endPoint: .bottom)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                    }
                    .frame(width: side, height: side)
                Canvas { context, size in
                    let inset: CGFloat = 12
                    for row in 0..<rows {
                        for col in 0..<columns {
                            let x = inset + CGFloat(col) * (size.width - inset * 2) / CGFloat(columns - 1)
                            let y = inset + CGFloat(row) * (size.height - inset * 2) / CGFloat(rows - 1)
                            let rect = CGRect(x: x - 1.5, y: y - 1.5, width: 3, height: 3)
                            context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(0.82)))
                        }
                    }
                }
                .frame(width: side, height: side)
                Circle()
                    .fill(.white)
                    .frame(width: 13, height: 13)
                    .overlay(Circle().stroke(.black.opacity(0.12), lineWidth: 1))
                    .shadow(color: .black.opacity(0.35), radius: 4, y: 2)
                    .position(x: 12 + point.x * (side - 24), y: 12 + point.y * (side - 24))
                .gesture(DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        point = CGPoint(
                            x: min(1, max(0, (value.location.x - 12) / max(1, side - 24))),
                            y: min(1, max(0, (value.location.y - 12) / max(1, side - 24)))
                        )
                        UISelectionFeedbackGenerator().selectionChanged()
                    })
                .frame(width: side, height: side)
                .contentShape(RoundedRectangle(cornerRadius: 24))
                .onTapGesture { location in
                    point = CGPoint(x: min(1, max(0, (location.x - 12) / max(1, side - 24))),
                                    y: min(1, max(0, (location.y - 12) / max(1, side - 24)))
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
