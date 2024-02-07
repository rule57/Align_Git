//
//  AppState.swift
//  AlignV4
//
//  Created by William Rule on 11/21/23.
//  TimeCheck (written on January 25th, 8:55PM)



import SwiftUI

class AppState: ObservableObject {
    static let shared = AppState()

    @Published var selectedOption: Int {
        didSet {
            UserDefaults.standard.set(selectedOption, forKey: UserDefaultsKeys.selectedOption)
            // Post a notification when selectedOption changes
            NotificationCenter.default.post(name: .selectedOptionChanged, object: nil)
        }
    }
    
    // Add images2DArray as a Published property
    @Published var images2DArray: [[[String]]] = []


    init() {
        selectedOption = UserDefaults.standard.integer(forKey: UserDefaultsKeys.selectedOption)
    }
}

extension Notification.Name {
    static let selectedOptionChanged = Notification.Name("selectedOptionChanged")
}
