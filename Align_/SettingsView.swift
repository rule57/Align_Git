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

struct UserDefaultsKeys {
    static let selectedOption = "selectedOption"
}

struct SettingsView: View {
    
    @State private var videoURLs: [URL] = []
    
    let coloredNavAppearance = UINavigationBarAppearance()
    init() {
        
        UINavigationBar.appearance().titleTextAttributes = [.font : UIFont(name: "Georgia", size: 30)!]
        //coloredNavAppearance.backgroundColor = UIColor(named: "black")
        
    }
    
    @ObservedObject var appState = AppState.shared
    
    
    
    var templatelist = ["Circles", "Windows", "Lamposts", "Trees", "Building Corners", "Its a secret! shhhhh"]
    
    let newCan = "New_Canvas"
    
    var body: some View {
        //_________VideoGalleryView______
        NavigationView {
                    List(videoURLs, id: \.self) { url in
                        NavigationLink(destination: VideoPlayer(player: AVPlayer(url: url)).frame(height: 300)) {
                            VideoThumbnailView(videoURL: url)
                        }
                    }
                    .navigationBarTitle("Video Gallery", displayMode: .inline)
                    .onAppear(perform: loadVideos)
                }
        //_________VideoGalleryView______
        
        
        ScrollView{
            VStack{
                Image("DevRoom1")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                NavigationView {
                    
                    List {
                        Picker("", selection: $appState.selectedOption) {
                            ForEach(0..<6, id: \.self) { index in
                                Text(templatelist[(index)]).tag(index)
                            }
                        }
                        .pickerStyle(.inline)
                    }
                }
                
                //.navigationBarTitle("Settings", displayMode: .inline)
                .font(.custom("Georgia", size: 18)) // Apply the Georgia font to all text
                
                
                Image("DevClear")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300)
                Button(action: {
                    // Action to perform when button is tapped
                    GalleryManager.shared.clearAllPhotos()
                }) {
                    // Use an image as the button label
                    Image("New_Canvas")
                        .resizable() // Make the image resizable
                        .scaledToFit() // Keep the image's aspect ratio
                        .frame(width: 350, height: 200) // Specify the frame of the button image
                }
            }
        }
        
    }
    func loadVideos() {
            videoURLs = GalleryManager.shared.videoURLs
        }
}
    

struct VideoThumbnailView: View {
    let videoURL: URL

    var body: some View {
        // Generate and display a thumbnail for the video
        // You need to implement the thumbnail generation logic
        Image(systemName: "film") // Placeholder image
            .resizable()
            .scaledToFit()
            .frame(width: 100, height: 100)
        // Add more view modifiers as needed
    }
}
    


#Preview{
    SettingsView()
}
  


