//
//  OnboardingViewModel.swift
//  LifeMart
//
//  Created by Andrey on 11.03.2022.
//

import Foundation

enum OnboardingPage: Int {
    case first, second, third
}

final class OnboardingViewModel: ObservableObject {
    
    // MARK: Dependence injection vars
    
    private final let setShownOnboardingUseCase: SetShownOnboardingUseCase
    
    // MARK: - Public vars
    
    @Published var currentPage = 0
    let pages: [OnboardingPage] = [.first, .second, .third]
    
    // MARK: - Init
    
    init(setShownOnboardingUseCase: SetShownOnboardingUseCase) {
        self.setShownOnboardingUseCase = setShownOnboardingUseCase
    }
    
    // MARK: - Public helpers
    
    func setShownOnboarding() {
        setShownOnboardingUseCase.fetch(value: true)
    }
}
