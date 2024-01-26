protocol GalleryViewControllerDelegate: AnyObject {
    func clearAllPhotos()
    func betaOverride()
}

//TO DO LIST
//1. Permissions are not needed with use of the Share Sheet!!  Fuck Yea, so get rid of the clutter that was built to make sure that the user gave permission.  (Also remove from info.plist)
//2. Swipe up needs to be fixed
//3. Possible "CreateGif" to replace "CreateVideo()"  This would ensure looping when viewed.
//4. Filename needs to not be a thousand characters long when exported.  Possible solution could be to use the title of the object of that week if it is being used + Their name or some shit idk.
//WIA
//GIf creation is a thing now. yay
//But i need to replace the infrustructor to make it the primary output (currently everything is based around the output being video)
//  TimeCheck (written on January 25th, 8:55PM)

import UIKit
import AVFoundation
import Photos
import ImageIO
import MobileCoreServices


class GalleryViewController: UIViewController {
    
    
    var currentIndex: Int = 0
    var imageView: UIImageView!
    var timer: Timer?
    var capturedImageFilenames: [String] = []
    weak var delegate: GalleryViewControllerDelegate?
    var canvasButton: UIButton!
    var saveButton: UIButton!
    let swipeUpImageView = UIImageView()
    var isSwipeGestureRecognized = false  // Tracks if the swipe up gesture has been recognized
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        imageView = UIImageView(frame: view.bounds)
        imageView.contentMode = .scaleAspectFill
        view.addSubview(imageView)
        
        // Add swipe down gesture recognizer
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(goBack))
        swipeDown.direction = .down
        view.addGestureRecognizer(swipeDown)
        setupSwipeUpReminder()
        setupCanvasButton()
        setupSaveButton()
        // Add swipe up gesture recognizer to show the canvasButton
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(showCanvasButton))
        swipeUp.direction = .up
        swipeUp.delegate = self // <- Add this line
        view.addGestureRecognizer(swipeUp)
        
        
        
        
        
        startSlideshow()
        
        //  <___________Permission Check Start_____________>
        
        checkPhotoLibraryPermission { [weak self] granted in
            guard let self = self else { return }
            if granted {
                DispatchQueue.main.async {
                    // You can call your save video function here if needed
                }
            } else {
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Permission Denied", message: "Please grant access to Photo Library to use this feature.", preferredStyle: .alert)
                    let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) in
                        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                            return
                        }
                        if UIApplication.shared.canOpenURL(settingsUrl) {
                            UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                                // Do nothing for now
                            })
                        }
                    }
                    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                    alert.addAction(settingsAction)
                    alert.addAction(cancelAction)
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
        
        //<___________Permission Check End_______________>
        
    }
    
    
    //______Permission check functions_____________-
    
    func checkPhotoLibraryPermission(completion: @escaping (Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized:
            completion(true)
        case .denied, .restricted:
            completion(false)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { (status) in
                completion(status == .authorized)
            }
        default:
            completion(false)
        }
    }
    
    func saveVideoToPhotoLibrary(videoUrl: URL) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoUrl)
        }, completionHandler: { success, error in
            if let error = error {
                print("Error saving video: \(error.localizedDescription)")
            } else {
                print("Video saved successfully!")
            }
        })
    }
    
    //________________________________________________________________
    
    
    func setupSwipeUpReminder() {
        swipeUpImageView.image = UIImage(named: "SwipeUp")
        swipeUpImageView.contentMode = .scaleAspectFill
        swipeUpImageView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(swipeUpImageView)
        
        NSLayoutConstraint.activate([
            swipeUpImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            swipeUpImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            swipeUpImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            swipeUpImageView.topAnchor.constraint(equalTo: view.topAnchor)
        ])
        
        swipeUpImageView.isHidden = true  // Initially hidden
        
        // Animate it after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            // Only show the reminder if the swipe up gesture has not yet been recognized
            if self?.isSwipeGestureRecognized == false {
                self?.showSwipeUpReminder()
            }
        }
        
        // Add swipe up gesture recognizer to dismiss the reminder
        let swipeUpGesture = UISwipeGestureRecognizer(target: self, action: #selector(dismissSwipeUpReminder))
        swipeUpGesture.direction = .up
        view.addGestureRecognizer(swipeUpGesture)
        print("swipe up setup")
    }
    
    func showSwipeUpReminder() {
        swipeUpImageView.isHidden = false
        swipeUpImageView.transform = CGAffineTransform(translationX: 0, y: self.view.frame.size.height)
        
        UIView.animate(withDuration: 0.5) {
            self.swipeUpImageView.transform = .identity
            print("5 seconds passed")
        }
    }
    
    @objc func dismissSwipeUpReminder(gesture: UISwipeGestureRecognizer) {
        // Immediately set the flag to true to prevent the reminder from showing
        isSwipeGestureRecognized = true
        
        // Animate the swipeUpImageView off the top of the screen
        UIView.animate(withDuration: 0.5, animations: {
            self.swipeUpImageView.transform = CGAffineTransform(translationX: 0, y: -self.view.frame.size.height)
        }) { _ in
            self.swipeUpImageView.isHidden = true
            print("swipe should be gone?")
        }
    }
    
    
    func pixelBuffer(from image: UIImage, size: CGSize) -> CVPixelBuffer? {
        let attrs: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue
        ]
        var pixelBuffer: CVPixelBuffer? = nil
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         Int(size.width),
                                         Int(size.height),
                                         kCVPixelFormatType_32ARGB,
                                         attrs as CFDictionary,
                                         &pixelBuffer)
        guard status == kCVReturnSuccess else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData,
                                width: Int(size.width),
                                height: Int(size.height),
                                bitsPerComponent: 8,
                                bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!),
                                space: rgbColorSpace,
                                bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        
        context?.translateBy(x: 0, y: size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context!)
        image.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        UIGraphicsPopContext()
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        return pixelBuffer
    }
    
    func writeImagesAsVideo(images: [UIImage], to outputPath: String, withSize size: CGSize, framesPerSecond: Int32, completion: @escaping (Bool) -> Void) {
        guard !images.isEmpty else {
            completion(false)
            return
        }
        
        let outputURL = URL(fileURLWithPath: outputPath)
        try? FileManager.default.removeItem(at: outputURL)
        
        do {
            let assetWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mov)
            let outputSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: size.width,
                AVVideoHeightKey: size.height
            ]
            
            let assetWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: outputSettings)
            assetWriter.add(assetWriterInput)
            
            let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: assetWriterInput, sourcePixelBufferAttributes: nil)
            assetWriterInput.expectsMediaDataInRealTime = true
            assetWriter.startWriting()
            assetWriter.startSession(atSourceTime: .zero)
            
            let duration = CMTime(value: 1, timescale: framesPerSecond)
            var frameCount: Int64 = 0
            
            let mediaQueue = DispatchQueue(label: "mediaInputQueue")
            assetWriterInput.requestMediaDataWhenReady(on: mediaQueue) {
                for image in images {
                    while !assetWriterInput.isReadyForMoreMediaData { }
                    
                    if let buffer = self.pixelBuffer(from: image, size: size) {
                        let timestamp = CMTime(value: frameCount, timescale: framesPerSecond)
                        pixelBufferAdaptor.append(buffer, withPresentationTime: timestamp)
                        frameCount += 1
                    }
                }
                assetWriterInput.markAsFinished()
                assetWriter.finishWriting {
                    completion(true)
                }
            }
        } catch {
            print("Error writing images to video: \(error)")
            completion(false)
        }
    }
    
    
    
    
    func setupCanvasButton() {
        if let canvasImage = UIImage(named: "New_Canvas") {
            let scaleFactor: CGFloat = 0.1 // Change this value as needed
            let scaledSize = CGSize(width: canvasImage.size.width * scaleFactor, height: canvasImage.size.height * scaleFactor)
            canvasButton = UIButton(frame: CGRect(origin: CGPoint(x: (view.frame.width - scaledSize.width) / 2, y: view.frame.size.height), size: scaledSize))
            canvasButton.setBackgroundImage(canvasImage, for: .normal)
        } else {
            // Fallback frame in case the image isn't found
            canvasButton = UIButton(frame: CGRect(x: 20, y: view.frame.size.height, width: 300, height: 200))
        }
        canvasButton.addTarget(self, action: #selector(clearTapped), for: .touchUpInside)
        
        // Add swipe down gesture recognizer to hide the canvasButton
        let hideGesture = UISwipeGestureRecognizer(target: self, action: #selector(hideCanvasButton))
        hideGesture.direction = .down
        canvasButton.addGestureRecognizer(hideGesture)
        
        canvasButton.frame.origin.y = view.frame.size.height
        
        
        view.addSubview(canvasButton)
    }
    
    func setupSaveButton() {
        if let saveImage = UIImage(named: "SaveButton") {
            let scaleFactor: CGFloat = 0.2 // Twice the scale factor of the canvas button
            let scaledSize = CGSize(width: saveImage.size.width * scaleFactor, height: saveImage.size.height * scaleFactor)
            
            saveButton = UIButton(frame: CGRect(origin: CGPoint(x: (view.frame.width - scaledSize.width) / 2, y: view.frame.size.height - 20), size: scaledSize))
            saveButton.setBackgroundImage(saveImage, for: .normal)
            print(scaledSize)
        } else {
            // Fallback frame in case the image isn't found
            saveButton = UIButton(frame: CGRect(x: 20, y: view.frame.size.height - canvasButton.frame.height - 210, width: 600, height: 400))
            print("saveButton.png not found")
        }
        
        saveButton.addTarget(self, action: #selector(createVideo), for: .touchUpInside)
        
        
        
        view.addSubview(saveButton)
    }
    
    
    
    
    
    
    @objc func showCanvasButton() {
        print("showCanvasButton called")
        UIView.animate(withDuration: 0.3) {
            self.canvasButton.frame.origin.y = self.view.frame.size.height - self.canvasButton.frame.size.height - 20
            self.saveButton.frame.origin.y = self.canvasButton.frame.origin.y - self.saveButton.frame.size.height - 20
        }
        
    }
    
    @objc func animateCanvasButtonPopup() {
        print("animateCanvasButtonPopup called")
        
        UIView.animate(withDuration: 0.3) {
            self.canvasButton.frame.origin.y = self.view.frame.size.height - self.canvasButton.frame.size.height - 20
            self.saveButton.frame.origin.y = self.canvasButton.frame.origin.y - self.saveButton.frame.size.height - 20
        }
        
    }
    
    @objc func hideCanvasButton() {
        UIView.animate(withDuration: 0.3) {
            self.canvasButton.frame.origin.y = self.view.frame.size.height
            self.saveButton.frame.origin.y = self.view.frame.size.height + self.canvasButton.frame.size.height
        }
        
    }
    
    
    func startSlideshow() {
        timer = Timer.scheduledTimer(timeInterval: 0.25, target: self, selector: #selector(showNextImage), userInfo: nil, repeats: true)
    }
    
    func loadImage(named filename: String) -> UIImage? {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        if let documentsDirectory = paths.first {
            let imagePath = documentsDirectory.appending("/\(filename)")
            return UIImage(contentsOfFile: imagePath)
        }
        return nil
    }
    
    @objc func showNextImage() {
        if capturedImageFilenames.isEmpty { return }
        
        imageView.image = loadImage(named: capturedImageFilenames[currentIndex])
        currentIndex = (currentIndex + 1) % capturedImageFilenames.count
    }
    
    @objc func goBack() {
        timer?.invalidate()
        dismiss(animated: true, completion: nil)
    }
    
    @objc func clearTapped() {
        let alert = UIAlertController(title: "Clear Photos", message: "Are you sure you want to clear all photos? This action cannot be undone.", preferredStyle: .alert)
        
        // Add the "Clear" action, which calls the delegate method if confirmed
        alert.addAction(UIAlertAction(title: "Clear", style: .destructive, handler: { [weak self] _ in
            self?.delegate?.clearAllPhotos()
            print("ClearTapped")
            self?.goBack()
        }))
        
        // Add a "Cancel" action that does nothing but close the alert
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        // Present the alert to the user
        present(alert, animated: true, completion: nil)
    }
    //    @objc func override(){
    //        delegate?.betaOverride()
    //    }
    
    
    
    @objc func video(_ videoPath: String, didFinishSavingWithError error: Error?, contextInfo info: AnyObject) {
        if let error = error {
            print("Error saving video: \(error.localizedDescription)")
        } else {
            print("Successfully saved video to photo library!")
        }
    }
    
    //    @objc func createGif() {
    //
    //        var maxWidth: CGFloat = 0
    //        var maxHeight: CGFloat = 0
    //        // Assuming you want to generate a video with the name "video.mp4" in the app's documents directory
    //        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
    //        let outputPath = "\(paths[0])/video.mp4"
    //        var imagesToUse: [UIImage] = []
    //
    //        for filename in capturedImageFilenames {
    //            if let image = loadImage(named: filename) {
    //                imagesToUse.append(image)
    //                if image.size.width > maxWidth{
    //                    maxWidth = image.size.width
    //                }
    //                if image.size.height > maxHeight {
    //                    maxHeight = image.size.height
    //                }
    //
    //            }
    //        }
    //
    //        writeImagesAsVideo(images: imagesToUse, to: outputPath, withSize: CGSize(width: maxWidth, height: maxHeight), framesPerSecond: 5) { success in
    //            if success {
    //                let videoUrl = URL(fileURLWithPath: outputPath)
    //                self.saveVideoToPhotoLibrary(videoUrl: videoUrl)
    //            }
    //        }
    //        goBack()
    //    }
    @objc func createVideo() {
        hideCanvasButton()
        createGif()
        
        var maxWidth: CGFloat = 0
        var maxHeight: CGFloat = 0
        // Assuming you want to generate a video with the name "video.mp4" in the app's documents directory
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        //let outputPath = "\(paths[0])/video.mp4"
        let uniqueFileName = "AlignMadeThis-\(UUID().uuidString).mp4"
        let outputPath = "\(paths[0])/\(uniqueFileName)"
        
        var imagesToUse: [UIImage] = []
        
        for filename in capturedImageFilenames {
            if let image = loadImage(named: filename) {
                imagesToUse.append(image)
                if image.size.width > maxWidth {
                    maxWidth = image.size.width
                }
                if image.size.height > maxHeight {
                    maxHeight = image.size.height
                }
            }
        }
        
        writeImagesAsVideo(images: imagesToUse, to: outputPath, withSize: CGSize(width: maxWidth, height: maxHeight), framesPerSecond: 5) { success in
            if success {
                let videoUrl = URL(fileURLWithPath: outputPath)
                //self.saveVideoToPhotoLibrary(videoUrl: videoUrl)
                // Present the share sheet
                GalleryManager.shared.videoSaved(at: videoUrl)
                DispatchQueue.main.async {
                    self.presentShareSheet(for: videoUrl)
                }
            }
        }
        //goBack()
    }
    
    
    func presentShareSheet(for videoUrl: URL) {
        // Ensure the video file is accessible and shareable
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = false
        do {
            var shareableVideoUrl = videoUrl
            try shareableVideoUrl.setResourceValues(resourceValues)
            
            // Copying the file to a temporary directory for sharing
            let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            let temporaryFileURL = temporaryDirectoryURL.appendingPathComponent(shareableVideoUrl.lastPathComponent)
            try FileManager.default.copyItem(at: shareableVideoUrl, to: temporaryFileURL)
            
            // Presenting the UIActivityViewController
            DispatchQueue.main.async {
                if self.isViewLoaded && self.view.window != nil {
                    let activityViewController = UIActivityViewController(activityItems: [temporaryFileURL], applicationActivities: nil)
                    if let popoverController = activityViewController.popoverPresentationController {
                        popoverController.sourceView = self.view
                        popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
                        popoverController.permittedArrowDirections = []
                    }
                    self.present(activityViewController, animated: true, completion: nil)
                }
            }
        } catch {
            print("Error preparing or sharing file: \(error)")
        }
    }
    
    @objc func createGif() {
           let images = capturedImageFilenames.compactMap { loadImage(named: $0) }
           createGIF(with: images, loopCount: 0, frameDelay: 0.2) { gifURL in
               if let gifURL = gifURL {
                   // You might want to do something with the GIF URL, like saving it or sharing it
                   print("GIF created at: \(gifURL)")
               }
           }
       }
    
    func createGIF(with images: [UIImage], loopCount: Int = 0, frameDelay: Double, completion: @escaping (URL?) -> Void) {
        // Ensure the array of images is not empty
        guard !images.isEmpty else {
            completion(nil)
            return
        }

        let fileProperties = [
            kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFLoopCount as String: loopCount]
        ] as CFDictionary

        let frameProperties = [
            kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFDelayTime as String: frameDelay]
        ] as CFDictionary

        let documentsDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let gifURL = documentsDirectoryURL.appendingPathComponent("animated.gif")

        guard let destination = CGImageDestinationCreateWithURL(gifURL as CFURL, UTType.gif.identifier as CFString, images.count, nil) else {
            completion(nil)
            return
        }

        CGImageDestinationSetProperties(destination, fileProperties)

        for image in images {
            guard let cgImage = image.cgImage else { continue }
            CGImageDestinationAddImage(destination, cgImage, frameProperties)
        }

        if !CGImageDestinationFinalize(destination) {
            completion(nil)
            return
        }

        completion(gifURL)
    }

    
    

//
//        self.present(activityViewController, animated: true, completion: nil)
//    }

    
}

extension GalleryViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}



 
