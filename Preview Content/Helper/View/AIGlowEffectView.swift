//
//  AIGlowEffectView.swift
//  Diploma
//
//  Created by Orest Palii on 11.04.2025.
//

import SwiftUI

struct AIGlowEffectView: View {
    @State private var gradientStops: [Gradient.Stop] = GlowEffect.generateGradientStops()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                EffectNoBlur(gradientStops: gradientStops, width: 5, size: geometry.size)
                Effect(gradientStops: gradientStops, width: 10, blur: 6, size: geometry.size)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .onAppear {
                Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in
                    withAnimation(.easeInOut(duration: 0.5)) {
                        gradientStops = GlowEffect.generateGradientStops()
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    AIGlowEffectView()
}
