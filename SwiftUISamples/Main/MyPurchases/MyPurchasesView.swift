//
//  MyPurchasesView.swift
//  LifeMart
//
//  Created by Andrey on 15.05.2022.
//

import SwiftUI

struct MyPurchasesView: View {
    
    @ObservedObject var model: MyPurchasesViewModel
    
    private enum ActiveSheet: Identifiable {
        case Sorting, Product
        var id: ActiveSheet { self }
    }
    
//    @State private var activeSheet: ActiveSheet?
    
    init(viewModel: MyPurchasesViewModel) {
        self.model = viewModel
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                VStack(spacing: 0) {
                    NavBarView(title: "Мои покупки", rightButton: RightNavBarButton(imageName: "icon_sorting", action: {
                        self.model.activeSheet = ProductsActiveSheet.Sorting
                    }))
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.fixed(geo.size.width / 2 - 16 - 5), spacing: 10), GridItem(.fixed(geo.size.width / 2 - 16 - 5))], alignment: .leading, spacing: 0, pinnedViews: [/*.sectionHeaders*/]) {
                            ForEach(model.products, id: \.self) { product in
                                ProductItem(product: product, width: geo.size.width / 2 - 16 - 5, addAction: {
                                    if !(product.hasModifiers ?? true) {
                                        model.addProduct(product)
                                    } else {
                                        openProduct(product)
                                    }
                                }, removeAction: {
                                    model.removeProduct(product)
                                })
                                    .onTapGesture {
                                        openProduct(product)
                                    }
                            }
                            
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    }
                    .background(Color.appGhostWhite)
                }
                .navigationBarHidden(true)
                
                if model.loading { LoadingView() }
            }
            .sheet(item: $model.activeSheet, onDismiss: {
                LifeMartApp.dependencyProvider.container.resetObjectScope(.modalView)
                model.sortItems()
            }) { sheet in
                switch sheet {
                case .Sorting:
                    sortingView()
                case .Product:
                    if let product = model.selectedProduct {
                        self.productView(product: product)
                    }
                }
            }
        }
    }
    
    func sortingView() -> some View {
        LazyView(model.catalogRouter.sortingView())
    }
    
    private func openProduct(_ product: Product) {
        self.model.selectedProduct = product
        self.model.activeSheet = ProductsActiveSheet.Product
    }
}

extension MyPurchasesView {
    func productView(product: Product) -> some View {
        LazyView(model.catalogRouter.productView(sourceScreen: .catalog, product: product))
    }
}

struct MyMurchasesView_Previews: PreviewProvider {
    static var previews: some View {
        LifeMartApp.dependencyProvider.assembler.resolver.resolve(MyPurchasesView.self)!
    }
}
