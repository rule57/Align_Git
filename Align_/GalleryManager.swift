//
//  GalleryManager.swift
//  AlignV4
//
//  Created by William Rule on 12/4/23.
//  TimeCheck (written on January 25th, 8:55PM)
//

import Foundation
import UIKit

class GalleryManager {
    //    static let shared = GalleryManager()
    //    weak var delegate: GalleryViewControllerDelegate?
    //
    //    private init() {}
    //
    //    func clearAllPhotos() {
    //        delegate?.clearAllPhotos()
    //    }
    //    GPT Below
    
    static let shared = GalleryManager()
    weak var delegate: GalleryViewControllerDelegate?
    private let fileURL: URL
    
    private init() {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        fileURL = documentsDirectory.appendingPathComponent("videoURLs.txt")
        videoURLs = loadVideoURLs() ?? []
    }
    
    func clearAllPhotos() {
            delegate?.clearAllPhotos()
        }
    
    
    var videoURLs: [URL] = []
    
    
    func addVideoURL(_ url: URL) {
        videoURLs.append(url)
        saveVideoURLs()
    }
    
    func clearAllVideos() {
        videoURLs.removeAll()
        // Optionally, delete the files from the filesystem
    }
    
    // Call this function from your GalleryViewController when a video is saved
    func videoSaved(at url: URL) {
        addVideoURL(url)
        // Any other logic you need after saving a video
    }
    
    private func saveVideoURLs() {
           do {
               let data = try NSKeyedArchiver.archivedData(withRootObject: videoURLs, requiringSecureCoding: false)
               try data.write(to: fileURL)
           } catch {
               print("Failed to save video URLs: \(error)")
           }
       }
    
    private func loadVideoURLs() -> [URL]? {
        do {
            let data = try Data(contentsOf: fileURL)
            let urls = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSArray.self, NSURL.self], from: data) as? [URL]
            return urls
        } catch {
            print("Failed to load video URLs: \(error)")
            return nil
        }
    }

    
}
