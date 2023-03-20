//
//  SortingView.swift
//  LifeMart
//
//  Created by Andrey on 11.03.2022.
//

import SwiftUI

struct SortingView: View {
    
    @ObservedObject var model: SortingViewModel
        
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
        
    init(viewModel: SortingViewModel) {
        self.model = viewModel
    }
    
    var body: some View {
        ZStack {
            Color.appDarkGrey
                .ignoresSafeArea()
                .opacity(0.7)

            LazyVStack(spacing: 0) {
                ForEach(model.sortingItems, id: \.self) { item in
                    SortingRow(sort: item) {
                        model.select(sorting: item)
                        back()
                    }
                }
            }
            //.frame(height: 252, alignment: .leading)
            .frame(maxWidth: .infinity)
            .padding(.top, 16)
            .padding(.bottom, 8)
            .background(Color.white.cornerRadius(5))
            .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color(red: 0.851, green: 0.856, blue: 0.902, opacity: 1), lineWidth: 0.5)
            )
            .padding(.horizontal, 16)
        }
        .clearModalBackground()
        .onTapGesture {
            presentationMode.wrappedValue.dismiss()
        }
        .animation(.none)
    }
}

extension SortingView {
    
    func back() {
        presentationMode.wrappedValue.dismiss()
        LifeMartApp.dependencyProvider.container.resetObjectScope(.discardedWhenPopView)
    }
}

struct SortingView_Previews: PreviewProvider {
    static var previews: some View {
        LifeMartApp.dependencyProvider.assembler.resolver.resolve(SortingView.self)!
    }
}
