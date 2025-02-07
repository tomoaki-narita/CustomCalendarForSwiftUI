//
//  ThemeSelectionView.swift
//  CustomCalendarForSwiftUI
//
//  Created by output. on 2025/02/12.
//

import SwiftUI

struct ThemeSelectionView: View {
    
    @EnvironmentObject var themeManager: AppThemeManager
    let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 3)
    let iconSize: CGFloat = 60
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(themeManager.currentTheme.primaryColor).ignoresSafeArea()
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
                                            RoundedRectangle(cornerRadius: 15)
                                                .fill(Color(UIColor.label))
                                                .frame(width: iconSize * 1.15, height: iconSize * 1.15)
                                                .shadow(radius: 5)
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(theme.primaryColor)
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
                                                .fill(themeManager.currentTheme == theme ? Color.gray.opacity(0.3) : Color.clear)
                                        )
                                    }
                                    Text("\(theme)")
                                        .textCase(.uppercase)
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundStyle(Color(themeManager.currentTheme.tertiaryColor))
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
