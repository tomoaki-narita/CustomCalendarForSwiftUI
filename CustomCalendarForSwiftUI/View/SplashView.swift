//
//  SplashView.swift
//  CustomCalendarForSwiftUI
//
//  Created by output. on 2025/02/04.
//

import SwiftUI

struct SplashView: View {
    
    @State private var isVisible: Bool = false
    @State private var trigger: Bool = false
    @State private var isActive = false
    
    var body: some View {
        if isActive {
            ContentView()
        } else {
            VStack(spacing: 0) {
                Image("appIconImage")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                SplashScreenView(" MiniCal ", trigger: glitctTrigger())
                    .font(.custom("Pacifico-Regular", size: 50))
                
            }
            .opacity(isVisible ? 1 : 0)
            .animation(.easeInOut(duration: 1.0), value: isVisible)
            .onAppear {
                isVisible = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                    withAnimation {
                        self.isActive = true
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    func SplashScreenView(_ text: String, trigger: Bool) -> some View {
        ZStack {
            SplashScreen(text: text, trigger: trigger) {
                LinearKeyframe(SplashScreenFrame(top: -5, center: 0, bottom: 0, shadowOpacity: 0.2), duration: 0.1
                )
                LinearKeyframe(SplashScreenFrame(top: -5, center: -5, bottom: -5, shadowOpacity: 0.6), duration: 0.1
                )
                LinearKeyframe(SplashScreenFrame(top: -5, center: -5, bottom: 5, shadowOpacity: 0.8), duration: 0.1
                )
                LinearKeyframe(SplashScreenFrame(top: 5, center: 5, bottom: 5, shadowOpacity: 0.4), duration: 0.1
                )
                LinearKeyframe(SplashScreenFrame(top: 5, center: 0, bottom: 5, shadowOpacity: 0.1), duration: 0.1
                )
                LinearKeyframe(SplashScreenFrame(),
                               duration: 0.1
                )
            }
            
            SplashScreen(text: " MiniCal ", trigger: trigger, shadow: .green) {
                LinearKeyframe(SplashScreenFrame(top: 0, center: 5, bottom: 0, shadowOpacity: 0.2), duration: 0.1
                )
                LinearKeyframe(SplashScreenFrame(top: 5, center: 5, bottom: 5, shadowOpacity: 0.3), duration: 0.1
                )
                LinearKeyframe(SplashScreenFrame(top: 5, center: 5, bottom: -5, shadowOpacity: 0.5), duration: 0.1
                )
                LinearKeyframe(SplashScreenFrame(top: 0, center: 5, bottom: -5, shadowOpacity: 0.6), duration: 0.1
                )
                LinearKeyframe(SplashScreenFrame(top: 0, center: -5, bottom: 0, shadowOpacity: 0.3), duration: 0.1
                )
                LinearKeyframe(SplashScreenFrame(),
                               duration: 0.1
                )
            }
        }
    }
    
    private func glitctTrigger() -> Bool {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            trigger = true
        }
        return trigger
    }
}

struct SplashScreen: View {
    var text: String
    var trigger: Bool
    var shadow: Color
    var radius: CGFloat
    var frames: [LinearKeyframe<SplashScreenFrame>]
    
    init(text: String, trigger: Bool, shadow: Color = .red, radius: CGFloat = 1, @SplashFrameBuilder frames: @escaping () -> [LinearKeyframe<SplashScreenFrame>]) {
        self.text = text
        self.trigger = trigger
        self.shadow = shadow
        self.radius = radius
        self.frames = frames()
    }
    
    var body: some View {
        KeyframeAnimator(initialValue: SplashScreenFrame(), trigger: trigger) { value in
            ZStack {
                TextView(.top, offset: value.top, opacity: value.shadowOpacity)
                TextView(.center, offset: value.center, opacity: value.shadowOpacity)
                TextView(.bottom, offset: value.bottom, opacity: value.shadowOpacity)
            }
            .compositingGroup()
        } keyframes: { _ in
            for frame in frames {
                frame
            }
        }
        
    }
    
    @ViewBuilder
    func TextView(_ alignment: Alignment, offset: CGFloat, opacity: CGFloat) -> some View {
        Text(text)
            
            
            .mask {
                if alignment == .top {
                    VStack(spacing: 0) {
                        Rectangle()
                        ExtendedSpacer()
                        ExtendedSpacer()
                    }
                } else if alignment == .center {
                    VStack(spacing: 0) {
                        ExtendedSpacer()
                        Rectangle()
                        ExtendedSpacer()
                    }
                } else {
                    VStack(spacing: 0) {
                        ExtendedSpacer()
                        ExtendedSpacer()
                        Rectangle()
                    }
                }
            }
            .offset(x: offset)
            .shadow(color: shadow.opacity(opacity), radius: radius, x: offset, y: offset / 2)
    }
    
    @ViewBuilder
    func ExtendedSpacer() -> some View {
        Spacer(minLength: 0)
            .frame(maxHeight: .infinity)
    }
}

@resultBuilder
struct SplashFrameBuilder {
    static func buildBlock(_ components: LinearKeyframe<SplashScreenFrame>...) -> [LinearKeyframe<SplashScreenFrame>] {
        return components
    }
    
}

struct SplashScreenFrame: Animatable {
    var animatableData: AnimatablePair<CGFloat, AnimatablePair<CGFloat,AnimatablePair<CGFloat, CGFloat>>> {
        get {
            return .init(top, .init(center, .init(bottom, shadowOpacity)))
        }
        set {
            top = newValue.first
            center = newValue.second.first
            bottom = newValue.second.second.first
            shadowOpacity = newValue.second.second.second
        }
    }
    var top: CGFloat = 0
    var center: CGFloat = 0
    var bottom: CGFloat = 0
    var shadowOpacity: CGFloat = 0
}

#Preview {
    SplashView()
}
