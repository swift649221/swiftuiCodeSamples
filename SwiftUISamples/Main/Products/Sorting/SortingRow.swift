//
//  SortingRow.swift
//  LifeMart
//
//  Created by Andrey on 11.03.2022.
//

import SwiftUI

struct SortingRow: View {
    
    var sort: SortingModel
    var sortTapAction: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 0) {
                Image(sort.imageName)
                    .renderingMode(.template)
                    .foregroundColor(sort.selected ? .appGreen : .appGrey)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 30, height: 30, alignment: .center)
                    .padding(.leading, 25)

                Text(sort.title)
                    .foregroundColor(.appDarkGrey)
                    .font(sort.selected ? .appBoldText : .appText)
                    .padding(.leading, 22)

                Spacer()

                if sort.selected {
                    Image("sort_checkmark")
                        .padding(.trailing, 24)
                }
            }

            Text(sort.subTitle ?? "")
                .foregroundColor(.appGrey)
                .font(.appText)
                .padding(.leading, 80)
                .padding(.top, -8)
        }
        .frame(height: 50)
        .frame(maxWidth: .infinity, alignment: .leading)
        .onTapGesture {
            print("sort = \(sort)")
            sortTapAction()
        }
    }
}
#if DEBUG
struct SortRow_Previews: PreviewProvider {
    static var previews: some View {
        SortingRow(sort: SortingModel(type: .decreasePrice, imageName: "sort_decrease_price", title: "Сортировать по цене", subTitle: "(по убыванию)", selected: true), sortTapAction: {
            
        })
            .previewLayout(.fixed(width: 300, height: 70))
    }
}
#endif
