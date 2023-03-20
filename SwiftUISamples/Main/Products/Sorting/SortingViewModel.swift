//
//  SortingViewModel.swift
//  LifeMart
//
//  Created by Andrey on 11.03.2022.
//

import SwiftUI

final class SortingViewModel: ObservableObject {
        
    // MARK: Dependence injection vars
    
    private final let getSortingTypeUseCase: GetSortingTypeUseCase
    private final let setSortingTypeUseCase: SetSortingTypeUseCase
    
    // MARK: Public vars
    
    @Published var sortingItems: [SortingModel] = [SortingModel]()
    
    // MARK: - Init
    
    init(getSortingTypeUseCase: GetSortingTypeUseCase, setSortingTypeUseCase: SetSortingTypeUseCase) {
        self.getSortingTypeUseCase = getSortingTypeUseCase
        self.setSortingTypeUseCase = setSortingTypeUseCase
        
        sortingItems = [SortingModel(type: .decreasePrice, imageName: "sort_decrease_price", title: "Сортировать по цене", subTitle: "(по убыванию)"),
                     SortingModel(type: .increasePrice, imageName: "sort_increase_price", title: "Сортировать по цене", subTitle: "(по возрастанию)"),
                     SortingModel(type: .stars, imageName: "sort_stars", title: "Сортировать по оценкам", subTitle: nil),
                     SortingModel(type: .likes, imageName: "sort_likes", title: "Сортировать по популярности", subTitle: nil),
                     SortingModel(type: .alphabet, imageName: "sort_alphabet", title: "Сортировать по алфавиту", subTitle: nil)]
        
        setupSelectedSorting()
    }
    
    // MARK: - Public helpers
    
    func setupSelectedSorting() {
        let sortingType = getSortingTypeUseCase.getSortingType()
        if let index = sortingItems.firstIndex(where: {$0.type == sortingType}) {
            sortingItems[index].selected = true
        }
    }
    
    func select(sorting: SortingModel) {
        sortingItems.indices.forEach { sortingItems[$0].selected = false }
        if let index = sortingItems.firstIndex(where: {$0.type == sorting.type}) {
            sortingItems[index].selected = true
            setSortingTypeUseCase.setSortingType(sorting.type)
        }
    }
    
}
