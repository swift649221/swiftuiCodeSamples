//
//  ProductViewModel.swift
//  LifeMart
//
//  Created by Andrey on 14.07.2022.
//

import SwiftUI
import Combine

enum ProgressType {
    case green
    case yellow
    case red
}

final class ProductViewModel: ObservableObject {
 
    // MARK: Dependence injection vars
    
    private final let downloadProductUseCase: DownloadProductUseCase
    private final let getCartUseCase: GetCartUseCase
    private final let addProductToCartUseCase: AddProductToCartUseCase
    private final let getCatalogUseCase: GetCatalogUseCase
    //private var productId: Int
    private var orderProduct: Product?
    private var sourceScreen: SourceScreen

    // MARK: User Interaction vars
    
    @Published var loading = false
    @Published var errorMessage: ErrorMessage?
    
    // MARK: Public vars
    
   // @Published var orderProduct: Product?
    @Published var product: Product?
    @Published var modifierGroupModels = [ModifierGroupModel]()
    @Published var price: Float?
    @Published var quantity: Float = 0
    @Published var dismissView = false
    var showNutrients = false
    var showConsist = false
    var showScore = false
    var showDescription = false
    var showModifiers = false
      
    // MARK: Private vars
    
    @Published private var cart: Cart?
    @Published private var catalog: Catalog?
    private var modifiersServerParams = [[String: Any]]()
    private var cancellables = [AnyCancellable]()
    
    // MARK: - Init
    
    init(downloadProductUseCase: DownloadProductUseCase, getCartUseCase: GetCartUseCase, addProductToCartUseCase: AddProductToCartUseCase, getCatalogUseCase: GetCatalogUseCase, product: Product, sourceScreen: SourceScreen) {
        print("ProductViewModel_init")
        self.downloadProductUseCase = downloadProductUseCase
        self.getCartUseCase = getCartUseCase
        self.addProductToCartUseCase = addProductToCartUseCase
        self.getCatalogUseCase = getCatalogUseCase
        //self.product = product
        if sourceScreen == .takeOrder || sourceScreen == .orders {
            self.orderProduct = product
        }
        //self.productId = productId
        self.sourceScreen = sourceScreen
        
        self.downloadProduct(productId: product.productId)
        
       // self.price = product.price
        
        //self.setupProperties()
                        
//        if self.sourceScreen == .catalog {
//            self.setupModifiers(product: self.product)
//        }
        
        self.getCartUseCase.fetch()
            .receive(on: RunLoop.main)
            .weakAssign(to: \.cart, on: self)
            .store(in: &cancellables)

        
        if self.sourceScreen == .takeOrder {
            self.getCatalogUseCase.fetch()
                .receive(on: RunLoop.main)
                .weakAssign(to: \.catalog, on: self)
                .store(in: &cancellables)
        }
        
        $product
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [weak self] product in
                guard let self  = self else { return }
                guard let product = product else { return }
                self.price = product.price
                
                self.setupProperties()
//                if self.sourceScreen == .catalog {
//                    self.setupModifiers(product: self.product)
//                }
                
                self.setupModifiers()
                self.setupDefaulCartSelModifiers()
                self.setModifiersServerParams()
                self.setupQuantity()
                self.calculateTotalPrice()
            })
            .store(in: &cancellables)
        
        $cart
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [weak self] cart in
                guard let self  = self else { return }
                self.setupQuantity()
            })
            .store(in: &cancellables)
        
//        $catalog
//            .receive(on: RunLoop.main)
//            .sink { [weak self] catalog in
//                guard let self = self else { return }
//                if let catalogProduct = catalog?.products?.first(where: { $0.productId == self.product?.productId }) {
//                    self.setupModifiers(product: catalogProduct)
//                    self.setupDefaulCartSelModifiers()
//                    self.setModifiersServerParams()
//                    self.setupQuantity()
//                    self.calculateTotalPrice()
//                }
//            }
//            .store(in: &cancellables)
    }
        
    // MARK: - Public Helpers
        
    func select(modifierModel: ModifierModel, modifierGroupModel: ModifierGroupModel) {
        print("select(modifierModel")
        self.modifierGroupModels = self.modifierGroupModels.map { group -> ModifierGroupModel in
            var group = group
            if group.modifierGroupId == modifierGroupModel.modifierGroupId {
                var selectedCount = 0
                group.modifiers = group.modifiers
                    .map { modifier -> ModifierModel in
                        var modifier = modifier
                        if !modifierModel.isDefault {
                            if modifier.modifierId == modifierModel.modifierId {
                                modifier.selected.toggle()
                            } else {
                                if !group.modifierGroup.isMultipleChoice || !group.modifierGroup.isComplement {
                                    modifier.selected = false
                                }
                            }
                            if modifier.selected {
                                selectedCount += 1
                            }
                        } else {
                            modifier.selected = false
                        }
                        return modifier
                    }
                    .map { modifier -> ModifierModel in
                        var modifier = modifier
                        if modifier.isDefault {
                            modifier.selected = selectedCount == 0
                        }
                        return modifier
                    }
            }
            return group
        }
        
        setModifiersServerParams()
        calculateTotalPrice()
        setupQuantity()
    }
    
    func checkValidModifiersAndAddToCart() {
        var requiredGroupModifierModels = [ModifierGroupModel]()
        if showModifiers {
            modifierGroupModels.forEach { group in
                print("group = \(group.title), isChoiceRequired = \(group.modifierGroup.isChoiceRequired), isComplement = \(group.modifierGroup.isComplement)")
                if group.modifierGroup.isChoiceRequired || !group.modifierGroup.isComplement {
                    group.modifiers.forEach { modifier in
                        print("modifier.title = \(modifier.title), modifier.selected = \(modifier.selected)")
                    }
                    
                    if group.modifiers.first(where: { $0.selected }) == nil {
                        print("NEED MODIFIER")
                        requiredGroupModifierModels.append(group)
                    }
                }
            }
        }
        if requiredGroupModifierModels.count > 0 {
            let text = requiredGroupModifierModels.map({ $0.title }).joined(separator: ", ")
            self.errorMessage = ErrorMessage(title: "Заполните обязательные модификаторы: \(text)")
        } else {
            changeProductInCart(changeProductAction: .add)
        }
    }
    
    func progress(type: ProgressType) -> Float {
        guard let scores = product?.scores, scores.count > 2, let scoresCount = product?.scoresCount else { return 0 }
        var score: Int
        switch type {
        case .green:
            score = scores[2]
        case .yellow:
            score = scores[1]
        case .red:
            score = scores[0]
        }
        let progress = Float(score) / Float(scoresCount) * 100
        return progress.rounded()
    }
    
    func enableAddProductAction() -> Bool {
        return sourceScreen != .orders
    }
    
    func quantityStr() -> String {
        //return "\(quantity.clean) \(product?.dimensionStr ?? "")"
        return product?.dimensionStr(quantity: quantity) ?? ""
    }
    
    func priceStr() -> String {
//        return product?.priceStr(quantity: quantity)
        if product?.isCountable == true {
            if quantity == 0 {
                return "\(price?.clean(numbers: 0).addCurrency ?? "")"
            } else {product
                return "по \(price?.clean(numbers: 0).addCurrency ?? "")"
            }
        } else {
            if quantity == 0 {
                let price = (price ?? 0) * (product?.countStep ?? 0)
                return "\(price.clean(numbers: 0).addCurrency)"
            } else {
                let price = (price ?? 0) * quantity
                return "за \(price.clean(numbers: 0).addCurrency)"
            }
        }
    }
    
    // MARK: - Private Helpers
    
    private func modifierTitle(group: ModifierGroup, modifier: Product) -> String {
        var title = modifier.name ?? ""
        //orderProduct ?
        let productPrice = product?.price ?? 0
        let modifierPrice = modifier.price ?? 0

        if group.isComplement, modifierPrice > 0 {
            title.append(" ")
            title.append("+")
            title.append(modifier.priceStr)
        } else if !group.isComplement {
            let diffPrice = modifierPrice - productPrice
            if diffPrice == 0 { return title }
            title.append(" ")
            if diffPrice > 0 {
                title.append("+")
                title.append(modifier.addCurrency(to: diffPrice))
            } else {
                title.append("-")
                title.append(modifier.addCurrency(to: diffPrice))
            }
        }

        return title
    }
    
    private func setupModifiers() {
        guard let product = product else { return }
        if let modifierGroups = product.modifierGroups, modifierGroups.count > 0 {
            self.showModifiers = true
            modifierGroupModels = modifierGroups
                .sorted(by: { $0.sortOrder < $1.sortOrder })
                .compactMap({ group in
                    var modifiersM: [ModifierModel] = product.availableModifiers?
                        .filter({ $0.groupId == group.id })
                        .compactMap({ modifier in
                            return ModifierModel(modifierId: modifier.productId, title: self.modifierTitle(group: group, modifier: modifier), price: modifier.price ?? 0, isDefault: modifier.isDefaultModifier)
                        }) ?? [ModifierModel]()
                    
                    if (group.emptyValue?.count ?? 0) > 0 {
                        let modifierM = ModifierModel(modifierId: 0, title: group.emptyValue ?? "", price: 0, isDefault: true)
                        modifiersM.insert(modifierM, at: 0)
                    }
                    
                    if modifiersM.count > 0 {
                        return ModifierGroupModel(modifierGroupId: group.id, title: group.title ?? "", modifierGroup: group, modifiers: modifiersM)
                    }
                    return nil
                })
        }
        print("finish setup modifiers")
    }
    
    private func setupProperties() {
        if let calories100 = self.product?.info?.calories100, calories100.count > 0, let proteins100 = self.product?.info?.proteins100, proteins100.count > 0, let carbohydrates100 = self.product?.info?.carbohydrates100, carbohydrates100.count > 0, let fats100 = self.product?.info?.fats100, fats100.count > 0 {
            self.showNutrients = true
        }
        
        if let consist = self.product?.consist, consist.count > 0 {
            self.showConsist = true
        }
        
        if let description = self.product?.description, description.count > 0 {
            self.showDescription = true
        }
        if let scores = self.product?.scores, scores.count > 0 {
            self.showScore = true
        }
    }
    
    private func setupDefaulCartSelModifiers() {
        guard self.sourceScreen == .takeOrder else { return }
        self.modifierGroupModels = modifierGroupModels.map { group -> ModifierGroupModel in
            var group = group
            group.modifiers = group.modifiers.map { modifier -> ModifierModel in
                var modifier = modifier
                if orderProduct?.selModifiers?.first(where: { $0.productId == modifier.modifierId}) != nil {
                    modifier.selected = true
                }
                return modifier
            }
            
            return group
        }
        removeGroupModifiersSelections()
    }
    
    private func removeGroupModifiersSelections() {
        self.modifierGroupModels = modifierGroupModels.map { group -> ModifierGroupModel in
            var group = group
            let selectedInGroupCount = group.modifiers.filter({ $0.selected == true }).count
            if selectedInGroupCount > 1,
               let defaultModifierTitle = group.modifierGroup.emptyValue,
               let defaultModifierIdx = group.modifiers.firstIndex(where: { $0.title == defaultModifierTitle && $0.modifierId == 0 }) {

                group.modifiers[defaultModifierIdx].selected = false
            }
            return group
        }
    }
    
    private func calculateTotalPrice() {
        var additionalPrice: Float = 0
        var defaultPrice: Float = product?.price ?? 0

        self.modifierGroupModels.forEach { group in
            group.modifiers.forEach { modifier in
                if modifier.selected {
                    if group.modifierGroup.isComplement {
                        additionalPrice += modifier.price
                    } else {
                        defaultPrice = modifier.price
                    }
                }
            }
        }
        self.price = defaultPrice + additionalPrice
    }
    
    private func setModifiersServerParams() {
        modifiersServerParams.removeAll()
        self.modifierGroupModels.forEach { group in
            group.modifiers.forEach { modifier in
                if modifier.selected && modifier.modifierId != 0 {
                    let quantity = 1
                    let obj = ["id": modifier.modifierId, "quantity": quantity]
                    modifiersServerParams.append(obj)
                }
            }
        }
        print("0_self.modifiersServerParams = \(self.modifiersServerParams)")
    }
    
    private func setupQuantity() {
        if showModifiers {
            if sourceScreen == .orders {
                self.quantity = orderProduct?.quantity ?? 0
            } else {
                self.quantity = 0//orderProduct?.quantity ?? 0
                let currentProductModifiersIds = modifierGroupModels.compactMap({ $0.modifiers.filter({ $0.selected && $0.modifierId != 0 }).compactMap({ $0.modifierId })}).reduce([], +)
                cart?.products?.forEach({ cartProduct in
                    guard cartProduct.productId == self.product?.productId else { return }
                    if let ids = cartProduct.selModifiers?.compactMap({ $0.productId}), ids.count > 0 {
                        if ids.containsSameElements(as: currentProductModifiersIds) {
                            self.quantity = cartProduct.quantity ?? 0
                            return
                        }
                    } else {
                        if currentProductModifiersIds.count == 0 {
                            self.quantity = cartProduct.quantity ?? 0
                            return
                        }
                    }
                })
            }
        } else {
            if sourceScreen == .orders {
                self.quantity = orderProduct?.quantity ?? 0
            } else {
                self.quantity = self.cart?.products?.first(where: { $0.productId == self.product?.productId })?.quantity ?? 0
            }
        }
    }

    // MARK: - API
        
    func downloadProduct(productId: Int) {
        self.loading = true
        downloadProductUseCase.fetch(productId: productId)
            .receive(on: RunLoop.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.loading = false
                switch completion {
                case .failure(let error):
                    print("11111")
                    print(error.localizedDescription)
                    self.errorMessage = ErrorMessage(networkRequestError: error)
                case .finished: break
                }
            } receiveValue: { product in
                self.product = product
            }
            .store(in: &cancellables)
    }
    
    func changeProductInCart(changeProductAction: ChangeProductAction) {
        print("self.modifiersServerParams = \(self.modifiersServerParams)")
        let changedProduct = orderProduct ?? product
        guard let product = changedProduct else { return }
//        let newQuantity = changeProductType == .add ? (quantity + 1) : (quantity - 1)
        let newQuantity = product.calculateNewQuantity(changeProductType: changeProductAction, oldQuantity: quantity)
        self.loading = true
        addProductToCartUseCase.fetch(id: product.productId, quantity: newQuantity, modifiers: self.modifiersServerParams)
            .receive(on: RunLoop.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.loading = false
                switch completion {
                case .failure(let error):
                    print("11111")
                    print(error.localizedDescription)
                    self.errorMessage = ErrorMessage(networkRequestError: error)
                case .finished: break
                }
            } receiveValue: { [weak self] cart in
                guard let self = self else { return }
                if newQuantity == 0 && self.sourceScreen == .takeOrder {
                    self.dismissView = true
                }
            }
            .store(in: &cancellables)
    }
}
