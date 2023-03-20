//
//  FavoriteCategoryView.swift
//  LifeMart
//
//  Created by Andrey on 18.07.2022.
//

import SwiftUI

struct FavoriteCategoryView: View {
    
    let tapAction: () -> Void
    
    var body: some View {
        VStack {
            
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Все любимые блюда рядом")
                        .foregroundColor(.appDarkGrey)
                        .font(.appFont(size: 20, weight: .bold))
                    Text("Мы собрали все ваши покупки в одну категорию.")
                        .foregroundColor(.appLiver)
                        .font(.appFont(size: 12, weight: .regular))
                }
                .frame(maxHeight: .infinity, alignment: .topLeading)
                Spacer()
                Image("my_purchases")
            }
            
            Spacer()
            SubmitButton(text: "Мои покупки", enable: true) {
                tapAction()
            }
        }
        .padding(.horizontal, 21)
        .padding(.vertical, 22)
        .frame(height: 200)
        .background(Color.white)
        .cornerRadius(5)
        .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0.0, y: 0.0)
    }
}
