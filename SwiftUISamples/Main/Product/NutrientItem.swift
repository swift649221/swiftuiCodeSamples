//
//  NutrientItem.swift
//  LifeMart
//
//  Created by Andrey on 15.03.2022.
//

import SwiftUI

struct NutrientItem: View {
    
    let name: String
    let value: String
    
    var body: some View {
        VStack {
            Text(name)
                .foregroundColor(Color.appDarkGrey.opacity(0.7))
                .font(.appSmallBoldText)
                .frame(maxWidth: .infinity)
            
            Spacer()
            
            Text(value)
                .foregroundColor(Color.appGrey.opacity(0.7))
                .font(.appText)
                .frame(maxWidth: .infinity)
        }
    }
}
