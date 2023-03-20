//
//  ModifierItem.swift
//  LifeMart
//
//  Created by Andrey on 11.03.2022.
//

import SwiftUI

struct ModifierItem: View {
    
    let modifierM: ModifierModel
    var tagTapAction: () -> Void
    
    var body: some View {
        Text(modifierM.title)
            .foregroundColor(modifierM.selected ? .appWhite : .appGrey)
            .font(.appText)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(modifierM.selected ? Color.appGreen.cornerRadius(5) : Color.appGhostWhite.cornerRadius(5))
            .shadow(color: modifierM.selected ? Color.appGreen.opacity(0.35) : .clear, radius: 8, x: 0, y: 4)
            .onTapGesture {
                tagTapAction()
            }
    }
}
