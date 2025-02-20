//
//  ThemeSelectionView.swift
//  CustomCalendarForSwiftUI
//
//  Created by output. on 2025/02/12.
//

import SwiftUI

struct ThemeSelectionView: View {
    
    @EnvironmentObject var themeManager: AppThemeManager
    let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 4)
    let iconSize: CGFloat = 60
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(gradient: Gradient(stops: [.init(color: themeManager.currentTheme.primaryColor, location: 0.25), .init(color: themeManager.currentTheme.gradientColor, location: 0.7)]), startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
                ScrollView {
                    VStack {
                        LazyVGrid(columns: columns) {
                            ForEach(AppColorTheme.allCases) { theme in
                                VStack(spacing: 0) {
                                    Button(action: {
                                        withAnimation {
                                            themeManager.changeTheme(to: theme)
                                        }
                                    }) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(Color(UIColor.label))
                                                .frame(width: iconSize * 1.15, height: iconSize * 1.15)
                                                .shadow(radius: 5)
                                            RoundedRectangle(cornerRadius: 15)
                                                .fill(
                                                    LinearGradient(gradient: Gradient(stops: [.init(color: theme.primaryColor, location: 0.0), .init(color: theme.gradientColor, location: 0.6)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                                                )
                                            
                                                .frame(width: iconSize, height: iconSize)
                                            VStack {
                                                Text("123")
                                                    .fontWeight(.bold)
                                                    .foregroundStyle(theme.tertiaryColor)
                                            }
                                        }
                                        .padding(10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(themeManager.currentTheme == theme ? Color.black.opacity(0.2) : Color.clear)
                                        )
                                    }
                                    Text("\(theme)")
                                        .textCase(.uppercase)
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor))
                                        .frame(width: iconSize * 1.1 ,height: iconSize * 0.6)
                                }
                            }
                        }
                        .padding(.top)
                    }
                    .padding()
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Theme")
                        .font(.headline)
                        .fontWeight(.heavy)
                        .foregroundColor(themeManager.currentTheme.tertiaryColor)
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color(themeManager.currentTheme.primaryColor), for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonTextHidden()
        }
    }
}


#Preview {
    ThemeSelectionView()
        .environmentObject(AppThemeManager())
}
