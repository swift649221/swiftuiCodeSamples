//
//  ProductsView.swift
//  LifeMart
//
//  Created by Andrey on 05.03.2022.
//

import SwiftUI
import SDWebImageSwiftUI

//struct ViewOffsetKey: PreferenceKey {
//    typealias Value = CGFloat
//    static var defaultValue = CGFloat.zero
//    static func reduce(value: inout Value, nextValue: () -> Value) {
//        value += nextValue()
//    }
//}

private struct SectionViewOffsetsKey: PreferenceKey {
    static var defaultValue: [Int: CGFloat] = [:]
    static func reduce(value: inout [Int: CGFloat], nextValue: () -> [Int: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

struct ProductsView: View {
        
    @ObservedObject var model: ProductsViewModel
    
    //@State private var activeSheet: ActiveSheet?
    @State private var tagLineOpacity: Double = 0
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    init(viewModel: ProductsViewModel) {
        self.model = viewModel
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                VStack(spacing: 0) {
                    NavBarView(title: model.navBarTitle(), rightButton: RightNavBarButton(imageName: "icon_sorting", action: {
                        self.model.activeSheet = ProductsActiveSheet.Sorting
                    }))
                    ZStack(alignment: .topLeading) {
                    ScrollViewReader { sp in
                        GeometryReader { geo2 in
                            ScrollView(.vertical, showsIndicators: true) {
                                
                                GeometryReader { proxy in
                                    Color.clear
                                        .preference(
                                            key: OffsetPreferenceKey.self,
                                            value: proxy.frame(in: .named("frameLayer")).minY
                                        )
                                }
                                .frame(height: 0)
                                
                                tagListView
                                    .id(-1)
                                    .readSize { size in
                                        print("tagViewHeight = \(size.height)")
                                        model.tagViewHeight = size.height
                                    }
                                
                                LazyVGrid(columns: [GridItem(.fixed(geo.size.width / 2 - 16 - 5), spacing: 10), GridItem(.fixed(geo.size.width / 2 - 16 - 5))], alignment: .leading, spacing: 0, pinnedViews: [/*.sectionHeaders*/]) {
                                    
                                    ForEach(model.categoryModels, id: \.self) { categoryModel in
                                        Section {
                                            //let f: () = print("REFRESH")
                                            ForEach(categoryModel.products, id: \.self) { product in
                                                ProductItem(product: product, width: geo.size.width / 2 - 16 - 5, addAction: {
                                                    if !(product.hasModifiers ?? true) {
                                                        model.addProduct(product)
                                                    } else {
                                                        openProduct(product)
                                                    }
                                                }, removeAction: {
                                                    model.removeProduct(product)
                                                })
                                                    .id(UUID())
                                                    .onTapGesture {
                                                        openProduct(product)
                                                    }
                                            }
                                        } header: {
                                            Divider()
                                                .padding(.bottom, 26)
                                                .padding(.top, 32)
                                        }
                                        .id(UUID())
                                        .background(
                                            GeometryReader { geo in
                                                Color.clear
                                                    .preference(
                                                        key: SectionViewOffsetsKey.self,
                                                        value: [categoryModel.category.id: geo.frame(in: .named("scrollView")).origin.y])
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal, 16)
                                .background(Color.appGhostWhite)
                                .onPreferenceChange(SectionViewOffsetsKey.self) { prefs in
                                    DispatchQueue.global(qos: .userInitiated).async {
                                        let filteredPrefs = prefs.filter { $1 > 0 && $1 <= geo2.size.height / 2 - 50 }
                                        var centerSectionId: Int?
                                        if filteredPrefs.count == 1 {
                                            centerSectionId = filteredPrefs.first?.key ?? 0
                                        } else if let id = filteredPrefs.sorted(by: { $0 < $1 }).first(where: { $1 >= geo2.size.height / 2 - 50 })?.key {
                                            centerSectionId = id
                                        }
                                        if let centerSectionId = centerSectionId, centerSectionId != model.currentCenterSectionId {
                                            model.currentCenterSectionId = centerSectionId
                                            DispatchQueue.main.async {
                                                model.scrollToCategory(id: centerSectionId)
                                            }
                                        }
                                    }
                                }
                                .onReceive(model.$selectedTag) { item in
                                    guard !model.categoryModels.isEmpty else { return }
                                    DispatchQueue.global(qos: .userInitiated).async {
                                        if let index = model.categoryModels.firstIndex(where: { $0.category.id == item?.categoryId}) {
                                                DispatchQueue.main.async {
                                                    withAnimation(.linear(duration: .leastNonzeroMagnitude)) {
                                                        if item?.categoryId == model.tags.first?.categoryId {
                                                            sp.scrollTo(-1)
                                                        } else {
                                                            sp.scrollTo(model.categoryModels[index], anchor: .top)
                                                        }
                                                    }
                                                }
                                        }
                                    }
                                }
                            }
                            .coordinateSpace(name: "frameLayer")
                            .coordinateSpace(name: "scroll")
                            .onPreferenceChange(OffsetPreferenceKey.self) { prefs in
                                print("offset_prefs = \(prefs)")
                                updateOpacity(offset: prefs)
                            }
                        }
                    }

                    
                        tagLineView
                    
                }
                }
                .errorView(errorMessage: $model.errorMessage)
                
                if model.loading { LoadingView() }
            }
            .navigationBarHidden(true)
            .sheet(item: $model.activeSheet, onDismiss: {
                print("onDismiss")
                LifeMartApp.dependencyProvider.container.resetObjectScope(.modalView)
                model.sortCategories()
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
            .onReceive(.deliveryChanged) { _ in
                self.presentationMode.wrappedValue.dismiss()
                LifeMartApp.dependencyProvider.container.resetObjectScope(.discardedWhenPopView)
            }
        }
    }
    
    private func openProduct(_ product: Product) {
        self.model.selectedProduct = product
        self.model.activeSheet = ProductsActiveSheet.Product
    }
    
    private func updateOpacity(offset: CGFloat) {
        DispatchQueue.global(qos: .background).async {
            var tempOffset: Double = 0
            if  -offset > model.tagViewHeight {
                if -offset > model.tagViewHeight + 50 {
                    tempOffset = 1
                } else {
                    //self.tagLineOpacity = Double(-offset - model.tagViewHeight)/100
                    tempOffset = 0
                }
            } else {
                tempOffset = 0
            }
            DispatchQueue.main.async {
                self.tagLineOpacity = tempOffset
            }
        }
    }
}

extension ProductsView {
    
    private var tagListView: some View {
        
        FlexibleView(
            data: model.tags,
            spacing: 8,
            alignment: .leading
        ) { tag in
            TagItem(tag: tag) {
                model.select(tag: tag)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(Color.white)
    }
    
    private var tagLineView: some View {
        ScrollViewReader { sp in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack {
                    ForEach(model.tags, id: \.self) { tag in
                        TagItem(tag: tag) {
                            model.select(tag: tag)
                        }
                        .id(UUID())
                        .padding(.leading, model.tags.first == tag ? 16 : 0)
                        .padding(.trailing, model.tags.last == tag ? 16 : 0)
                    }
                }
                .onReceive(model.$tagToScroll) { item in
                    guard !model.tags.isEmpty else { return }
                    DispatchQueue.global(qos: .userInitiated).async {
                        if let index = model.tags.firstIndex(where: { $0.categoryId == item?.categoryId}) {
                            print("index_scroll_tags = \(index)")
                            DispatchQueue.main.async {
                                withAnimation(.linear(duration: .leastNonzeroMagnitude)) {
                                    sp.scrollTo(model.tags[index], anchor: .center)
                                }
                            }
                        }
                    }
                }
            }
            .frame(height: 58)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .background(Color.white)
        }
        .opacity(tagLineOpacity)
    }
}

extension ProductsView {
    
    func productView(product: Product) -> some View {
        LazyView(model.catalogRouter.productView(sourceScreen: .catalog, product: product))
    }
    
    func sortingView() -> some View {
        LazyView(model.catalogRouter.sortingView())
    }
}

struct ProductsView_Previews: PreviewProvider {
    static var previews: some View {
        PreviewWrapper()
    }

    struct PreviewWrapper: View {

        //@State(initialValue: Parser.shared.catalog()) var catalog: Catalog?
        @State(initialValue: Parser.shared.parenCategory()) var parenCategory: ProductCategory?

        var body: some View {
            LifeMartApp.dependencyProvider.assembler.resolver.resolve(ProductsView.self, argument: $parenCategory)!
        }
    }
}
