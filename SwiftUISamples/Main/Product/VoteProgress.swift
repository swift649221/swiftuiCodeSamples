//
//  VoteProgress.swift
//  LifeMart
//
//  Created by Andrey on 05.03.2022.
//

import SwiftUI

struct VoteProgress: View {
    let imageName: String
    let color: Color
    let progress: Float
    
    var body: some View {
        HStack(alignment: .center, spacing: 5) {
            Image(imageName)
                .frame(width: 25, height: 25)
            
            ProgressView(value: progress, total: 100)
                .frame(height: 5.0)
                .accentColor(color)
                .scaleEffect(x: 1, y: 1, anchor: .center)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(red: 0.314, green: 0.314, blue: 0.314, opacity: 1), lineWidth: 1)
                )
            
            Text("\(progress.clean(numbers: 0))%")
                .foregroundColor(.appGrey)
                .font(.appSmallText)
                .frame(width: 30, height: 14, alignment: .trailing)
        }
    }
}
