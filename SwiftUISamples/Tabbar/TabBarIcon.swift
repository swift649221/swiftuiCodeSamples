//
//  TabBarIcon.swift
//  LifeMart
//
//  Created by Andrey on 05.03.2022.
//

import SwiftUI

struct TabBarIcon: View {
    
    @Binding var currentPage: Page
    let assignedPage: Page
    @Binding var showChatView: Bool
    let width: CGFloat
    let iconName, selectedIconName: String
    let badgeText: String?
    
    init(currentPage: Binding<Page>, assignedPage: Page, showChatView: Binding<Bool>, width: CGFloat, iconName: String, selectedIconName: String, badgeText: String? = nil) {
        self._currentPage = currentPage
        self.assignedPage = assignedPage
        self._showChatView = showChatView
        self.width = width
        self.iconName = iconName
        self.selectedIconName = selectedIconName
        self.badgeText = badgeText
    }
    
    var body: some View {
        VStack {
            ZStack {
                Image(assignedPage == currentPage ? selectedIconName : iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                
                if let badgeText = badgeText, badgeText.count > 0 {
                    Text(badgeText)
                        .foregroundColor(.white)
                        .font(.appFont(size: 12, weight: .bold))
                        .padding(.horizontal, 5)
                        .frame(height: 16, alignment: .center)
                        .background(assignedPage == currentPage ? Color.appGreen : Color.appDarkGrey)
                        .cornerRadius(8)
                        .offset(y: 0)
                }
            }
        }
        .onTapGesture {
            if assignedPage != .chat {
                currentPage = assignedPage
                showChatView = false
            } else {
                withAnimation {
                    showChatView = true
                }
            }
            
        }
    }
}
