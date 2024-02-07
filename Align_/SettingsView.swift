//
//  SettingsView.swift
//  AlignV4
//
//  Created by William Rule on 11/21/23.
//  TimeCheck (written on January 25th, 8:55PM)
//

import SwiftUI
import AVKit

//TO DO
//1. Layout for gallery (gonna be a stack with each video being a beveled rectangle that plays the video as you land on it.)
//2.

//var images2DArray: [[String]] = []
//
//func pp(){
//    if let data = UserDefaults.standard.data(forKey: "images2DArrayKey"),
//       let array = try? JSONSerialization.jsonObject(with: data, options: []) as? [[String]] {
//        images2DArray = array
//    }
//}

struct UserDefaultsKeys {
    static let selectedOption = "selectedOption"
}




struct SettingsView: View {
    @ObservedObject var appState = AppState.shared

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                ForEach(0..<min(appState.images2DArray.count + 1, 6), id: \.self) { index in
                    if index < appState.images2DArray.count {
                        // Box with slideshow or image representation
                        Image("AppIcon") // Replace with actual slideshow or image logic
                            .onTapGesture {
                                appState.selectedOption = index
                            }
                    } else {
                        // Box with a plus sign for adding new option
                        Text("+")
                            .font(.largeTitle)
                            .onTapGesture {
                                // Logic to add new option or navigate to camera/gallery
                            }
                    }
                }
            }
            .padding()
        }
    }
}
//
//struct SettingsView: View {
//
//    let coloredNavAppearance = UINavigationBarAppearance()
//    init() {
//        
//        UINavigationBar.appearance().titleTextAttributes = [.font : UIFont(name: "Georgia", size: 30)!]
//        //coloredNavAppearance.backgroundColor = UIColor(named: "black")
//        
//    }
//    
//    @ObservedObject var appState = AppState.shared
//    
//    
//    
//    var templatelist = ["File1", "File2"]
//    
//    let newCan = "New_Canvas"
//    
//    var body: some View {
//
//        ScrollView{
//            VStack{
//                Image("DevRoom1")
//                    .resizable()
//                    .aspectRatio(contentMode: .fit)
//                NavigationView {
//                    
//                    List {
//                        Picker("", selection: $appState.selectedOption) {
//                            ForEach(0..<2, id: \.self) { index in
//                                Text(templatelist[(index)]).tag(index)
//                            }
//                        }
//                        .pickerStyle(.inline)
//                    }
//                }
//                
//                //.navigationBarTitle("Settings", displayMode: .inline)
//                .font(.custom("Georgia", size: 18)) // Apply the Georgia font to all text
//                
//                
//                Image("DevRoom1")
//                    .resizable()
//                    .scaledToFit()
//                    .frame(width: 300)
//                Button(action: {
//                    // Action to perform when button is tapped
//                    GalleryManager.shared.clearAllPhotos()
//                }) {
//                    // Use an image as the button label
//                    Image("New_Canvas")
//                        .resizable() // Make the image resizable
//                        .scaledToFit() // Keep the image's aspect ratio
//                        .frame(width: 350, height: 200) // Specify the frame of the button image
//                }
//            }
//        }
//        
//    }
//
//}
//    
//
//struct VideoThumbnailView: View {
//    let videoURL: URL
//
//    var body: some View {
//        // Generate and display a thumbnail for the video
//        // You need to implement the thumbnail generation logic
//        Image(systemName: "film") // Placeholder image
//            .resizable()
//            .scaledToFit()
//            .frame(width: 100, height: 100)
//        // Add more view modifiers as needed
//    }
//}
//    


#Preview{
    SettingsView()
}
  


