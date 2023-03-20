//
//  ProductsViewModel.swift
//  LifeMart
//
//  Created by Andrey on 11.03.2022.
//

import SwiftUI
import Combine

enum ProductsActiveSheet: Identifiable {
    case Sorting, Product
    var id: ProductsActiveSheet { self }
}

final class ProductsViewModel: ObservableObject {
            
    // MARK: Dependence injection vars
    
    final let catalogRouter: CatalogRouter
    private final let getSortingTypeUseCase: GetSortingTypeUseCase
    private final let getCatalogUseCase: GetCatalogUseCase
    private final let getCartUseCase: GetCartUseCase
    private final let addProductToCartUseCase: AddProductToCartUseCase
    private var parentCategory: ProductCategory?
    private var category: ProductCategory?
    
    // MARK: User Interaction vars
    
    @Published var loading = false
    @Published var errorMessage: ErrorMessage?
    
    // MARK: Public vars
    
    @Published var products: [Product] = [Product]()
    @Published var tags = [TagModel]()
    @Published var selectedTag: TagModel?
    @Published var tagToScroll: TagModel?
    @Published var selectedTagForTagLine: TagModel?
    @Published var categoryModels = [CategoryModel]()
    @Published var selectedProduct: Product?
    var tagViewHeight: CGFloat = .zero
    var currentCenterSectionId: Int = 0
    @Published var activeSheet: ProductsActiveSheet?
//    @Published var isLoadWithCategory: Bool?

    // MARK: Private vars
    
    @Published private var cart: Cart?
    private var cancellables = [AnyCancellable]()

    // MARK: - Init
    
    init(catalogRouter: CatalogRouter, getCatalogUseCase: GetCatalogUseCase, getCartUseCase: GetCartUseCase, getSortingTypeUseCase: GetSortingTypeUseCase, addProductToCartUseCase: AddProductToCartUseCase, parentCategory: ProductCategory?, category: ProductCategory?) {
        self.catalogRouter = catalogRouter
        self.getCatalogUseCase = getCatalogUseCase
        self.getCartUseCase = getCartUseCase
        self.getSortingTypeUseCase = getSortingTypeUseCase
        self.addProductToCartUseCase = addProductToCartUseCase
        self.parentCategory = parentCategory
        self.category = category
//        isLoadWithCategory = category != nil
        self.getCartUseCase.fetch()
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [weak self] cart in
                self?.cart = cart
                self?.configeDefaultProductQuantities()
            })
            .store(in: &cancellables)

        getCatalogUseCase.fetch()
            .receive(on: RunLoop.main)
            .sink { [weak self] catalog in
                guard let self = self else { return }
                self.tags.removeAll()
                let categories = catalog?.categories?.filter({ $0.parentId == parentCategory?.id }) ?? [ProductCategory]()
                categories.forEach { category in
                    if let products = catalog?.products?.filter({ $0.categoriesIds?.contains(category.id) ?? false }) {
                        if let cart = self.cart, let cartProducts = cart.products {
                            for cartProduct in cartProducts {
                                if let index = products.firstIndex(where: { $0.productId == cartProduct.productId }) {
                                    products[index].quantity = cartProduct.quantity
                                }
                            }
                        }
                        let categoryModel = CategoryModel(title: category.title ?? "", category: category, products: products)
                        self.categoryModels.append(categoryModel)
                        
                        let tag = TagModel(categoryId: category.id, categoryName: category.title ?? "")
                        self.tags.append(tag)
                    }
                }
                self.sortCategories()
            }
            .store(in: &cancellables)
    }
            
    // MARK: - Public Helpers
    
    func navBarTitle() -> String {
        return parentCategory?.title ?? ""
    }

    func select(tag: TagModel) {
        selectedTag = tag
        for index in 0..<self.tags.count {
            if self.tags[index].categoryId == tag.categoryId {
                self.tags[index].selected = true
            } else {
                self.tags[index].selected = false
            }
        }
    }
    
    func scrollToCategory(id: Int) {
        for index in 0..<self.tags.count {
            if self.tags[index].categoryId == id {
                self.tags[index].selected = true
                self.tagToScroll = self.tags[index]
            } else {
                self.tags[index].selected = false
            }
        }
        if let category = category {
            if let index = self.tags.firstIndex(where: { $0.categoryId == category.id }) {
                self.category = nil
                self.tags[index].selected = true
                self.selectedTag = self.tags[index]
            }
            self.category = nil
        }
    }

    func sortCategories() {
        let sortingType = getSortingTypeUseCase.getSortingType()
        switch sortingType {
        case .decreasePrice:
            for index in 0..<categoryModels.count {
                categoryModels[index].products.sort(by: { $0.price ?? 0 > $1.price ?? 0 })
            }
        case .increasePrice:
            for index in 0..<categoryModels.count {
                categoryModels[index].products.sort(by: { $0.price ?? 0 < $1.price ?? 0 })
            }
        case .likes:
            for index in 0..<categoryModels.count {
                categoryModels[index].products.sort(by: { $0.rating ?? 0 > $1.rating ?? 0 })
            }
        case .stars:
            for index in 0..<categoryModels.count {
                categoryModels[index].products.sort(by: { $0.scoresCount ?? 0 > $1.scoresCount ?? 0 })
            }
        case .alphabet:
            for index in 0..<categoryModels.count {
                categoryModels[index].products.sort(by: { $0.name?.lowercased() ?? "" < $1.name?.lowercased() ?? "" })
            }
        case .none:
            for index in 0..<categoryModels.count {
                categoryModels[index].products.sort(by: { $0.sortOrder ?? 0 < $1.sortOrder ?? 0 })
            }
        }
    }
    
    func addProduct(_ product: Product) {
        changeProductInCart(product: product, changeProductAction: .add)
    }
    
    func removeProduct(_ product: Product) {
        changeProductInCart(product: product, changeProductAction: .remove)
    }
    
    func configeDefaultProductQuantities() {
        for index in categoryModels.indices {
            let categoryModel = categoryModels[index]
            for productIndex in categoryModel.products.indices {
                let product = categoryModel.products[productIndex]
                categoryModels[index].products[productIndex].quantity = 0
                if let cart = self.cart, let cartProducts = cart.products {
                    if let cartProduct = cartProducts.first(where: { $0.productId == product.productId }) {
                        categoryModels[index].products[productIndex].quantity = cartProduct.quantity
                    }
                }
            }
        }
    }
        
    // MARK: - API
    
    func changeProductInCart(product: Product, changeProductAction: ChangeProductAction) {
        let id = product.productId
        let newQuantity = product.calculateNewQuantity(changeProductType: changeProductAction)
        let modifiers = [[String : Any]]()
        self.loading = true
        addProductToCartUseCase.fetch(id: id, quantity: newQuantity, modifiers: modifiers)
            .receive(on: RunLoop.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.loading = false
                switch completion {
                case .failure(let error):
                    print(error.localizedDescription)
                    self.errorMessage = ErrorMessage(networkRequestError: error)
                case .finished: break
                }
            } receiveValue: { [weak self] cart in
                guard let self = self else { return }
                
                for categoryModel in self.categoryModels {
                    if let index = categoryModel.products.firstIndex(where: { $0.productId == product.productId }) {
                        categoryModel.products[index].quantity = newQuantity
                    }
                }
            }
            .store(in: &cancellables)
    }

}
