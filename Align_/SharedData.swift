//
//  SharedData.swift
//  AlignV4
//
//  Created by William Rule on 10/26/23.
//

import Foundation

class SharedData {
    static let shared = SharedData()

    var capturedImageFilenames: [String] = []

    var selectedOption: Int = UserDefaults.standard.integer(forKey: "selectedOption")
    
    private init() { }
}
