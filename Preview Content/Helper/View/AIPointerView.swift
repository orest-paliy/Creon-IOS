import SwiftUI

import SwiftUI

struct AIPointerView: View {
    let confidence: Int
    let scale: CGFloat

    var body: some View {
        HStack(alignment: .bottom){
            ZStack{
                Circle()
                    .trim(from: 0.02, to: 0.48)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [Color("primaryColor"), Color("BackgroundColor")]),
                            center: .center,
                            startAngle: .degrees(180),
                            endAngle: .degrees(0)
                        ),
                        style: StrokeStyle(lineWidth: 20 * scale, lineCap: .round)
                    )
                    .rotationEffect(.degrees(180))
                    .frame(width: 200 * scale, height: 200 * scale)
                    .shadow(radius: 1)

                HalfCircle()
                    .fill(.card)
                    .frame(width: 160 * scale, height: 160 * scale)
                
                Image(systemName: "arrowtriangle.up.fill")
                    .resizable()
                    .frame(width: 20 * scale, height: 20 * scale)
                    .foregroundColor(.card)
                    .offset(y: -90 * scale)
                    .rotationEffect(angleForConfidence(confidence))
                
                VStack {
                    Text("AI")
                        .font(.system(size: 24 * scale, weight: .bold))
                    
                    Text("\(confidence)%")
                        .font(.system(size: 24 * scale, weight: .bold))
                }
                .foregroundStyle(Color("primaryColor"))
                .offset(y: -17.5)
            }
            .frame(maxWidth: 200 * scale, maxHeight: 10 * scale)
        }
    }

    private func angleForConfidence(_ confidence: Int) -> Angle {
        // Кут у діапазоні [-90°, +90°]
        let percent = Double(confidence) / 100
        var degrees = -90 + (percent * 180)
        degrees *= 0.9
        return .degrees(degrees)
    }
}

// MARK: - Напівколо

struct HalfCircle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let radius = min(rect.width, rect.height) / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)

        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )

        path.addLine(to: CGPoint(x: center.x + radius, y: center.y))
        path.addLine(to: CGPoint(x: center.x - radius, y: center.y))
        path.closeSubpath()

        return path
    }
}



#Preview {
    AIPointerView(confidence: 90, scale: 0.5)
}
