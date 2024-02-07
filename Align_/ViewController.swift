//  1.1.0
//  ViewController.swift
//  Align
//
//
//  Created by William Rule on 10/16/23.
//  1.1.0 Finished on 12/5/23 by William Rule
//  TimeCheck (written on January 25th, 8:55PM)


import SwiftUI
import AVKit
import AVFoundation
import UIKit
//import FLAnimatedImage

//TO DO LIST
//1. Figure out UI and what to do with it.
//2. Fix logic with the toggle.  Should not be an issue if we only have a single temple able to be used.
//3. Impliment a better explanation of how the app works.
//4. Optimize for different devices that are not the iPhone 13 max.
//5. Top left. Figure out what to do with that space. (countdown till deadline or some shit idk)
//6. SettingsView needs to change to something different.


class ViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    
    
    private let settingsButton = UIButton(type: .system)
    private let gearImageView = UIImageView()
    
    private var topRectangle: UIView!
    private let toggleButton = UIButton()
    //private let topRectangle = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))

    
    
    var imageView: UIImageView!
    var indicatorView: UIImageView!
    
    private var slideshowTimer: Timer?
    private var currentButtonIndex = 0 // Add this to keep track of the current index
    private var previousSelectedOption = AppState.shared.selectedOption

    
    private let photoCounterKey = "photoCounter"
    
    
    let selectedOption = UserDefaults.standard.integer(forKey: UserDefaultsKeys.selectedOption)
    
    
    var tempCapturedImage: UIImage?
    
    
    
    
    
    var shouldAddCapturedImage: Bool = false
    //Capture Session
    var session: AVCaptureSession?
    //Photo Output
    let output = AVCapturePhotoOutput()
    //View Preview
    let previewLayer = AVCaptureVideoPreviewLayer()
    //Shutter button
    
    var player: AVPlayer?
    var popupView: UIView?
    var templateView: UIView?
    
    
    var playerLayer: AVPlayerLayer?
    var playerTwo: AVPlayer?
    var playerContainerView: UIView?
    
    var blackBackgroundView = UIView()
    
    
    
    var capturedImages: [UIImage] = [] {
        didSet {
            updateImageDisplay()
        }
    }
    var capturedImageFilenamesStorage: [[String]] = []
    var capturedImageFilenames: [String] = []
    
    
    
    let imageDisplayView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let picture1: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = .clear
        imageView.contentMode = .scaleAspectFill
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    let picture2: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = .clear
        imageView.contentMode = .scaleAspectFill
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    let picture3: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = .clear
        imageView.contentMode = .scaleAspectFill
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    let customPicture: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = .clear
        imageView.contentMode = .scaleAspectFill
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    
    private let shutterButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        button.layer.cornerRadius = 50
        button.layer.borderWidth = 10
        button.layer.borderColor = UIColor.white.cgColor
        return button
    }()
    
    
    // AVCaptureVideoPreviewLayer for camera preview (non-optional)
//    let gifImageView: FLAnimatedImageView = {
//        let imageView = FLAnimatedImageView()
//        imageView.contentMode = .scaleAspectFit
//        return imageView
//    }()
    
    var isInitialGifPlayed = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        GalleryManager.shared.delegate = self
        
        print(selectedOption)
        
        
        if let savedFilenames = UserDefaults.standard.array(forKey: "capturedImageFilenamesKey") as? [String] {
            capturedImageFilenames = savedFilenames
        }
        
//        if let savedStorage = UserDefaults.standard.array(forKey: "capturedImageFilenamesStorageKey") a? [] {
//            capturedImageFilenamesStorage = savedStorage
//        }
        
//        topRectangle = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
//            topRectangle.backgroundColor = .blue // Set a background color for visibility
//            view.addSubview(topRectangle)
        
        
        updateCapturedImagesArray()
        view.backgroundColor = .black
        view.layer.addSublayer(previewLayer)
        view.addSubview(shutterButton)
        checkCameraPermissions()
        
        
        
        //setupResetTimer()
        setupImageView()
        
        //updateIndicator()
        
        
        
        shutterButton.addTarget(self, action: #selector(didTapTakePhoto), for: .touchUpInside)
        
        
        view.addSubview(imageDisplayView)
        imageDisplayView.addSubview(picture1)
        imageDisplayView.addSubview(picture2)
        imageDisplayView.addSubview(picture3)
        imageDisplayView.addSubview(customPicture)
        
        
        setupSettingsButton()
        //setupGearImageView()
        
        setupLayout()
        //setupGestureRecognizers()
        
        
        
        let tap1 = UITapGestureRecognizer(target: self, action: #selector(handleImageTap))
        picture1.addGestureRecognizer(tap1)
        picture1.isUserInteractionEnabled = true
        
        let tap2 = UITapGestureRecognizer(target: self, action: #selector(handleImageTap))
        picture2.addGestureRecognizer(tap2)
        picture2.isUserInteractionEnabled = true
        
        let tap3 = UITapGestureRecognizer(target: self, action: #selector(handleImageTap))
        picture3.addGestureRecognizer(tap3)
        picture3.isUserInteractionEnabled = true
        
        imageView.isUserInteractionEnabled = true
        
        //ShowTemplate
        
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(showTemplate), name: .selectedOptionChanged, object: nil)
        
        //Indicator Stuff
        
        indicatorView = UIImageView()
        indicatorView.contentMode = .scaleAspectFill
        indicatorView.layer.masksToBounds = true
        
        // Add indicatorView to the view hierarchy
        view.addSubview(indicatorView)
        
        // Set up the layout constraints for indicatorView
        setupIndicatorViewConstraints()
        
        setupToggleButton()
        
    }
    
    //2D Array Sthuff
    
    var images2DArray: [[String]] = []

    // Load existing data from UserDefaults, if any
    func loadImages2DArray() {
        if let data = UserDefaults.standard.data(forKey: "images2DArrayKey"),
           let array = try? JSONSerialization.jsonObject(with: data, options: []) as? [[String]] {
            images2DArray = array
        }
    }
    
    func updateImages2DArray(with newImages: [String]) {
        let selectedOption = UserDefaults.standard.integer(forKey: "selectedOption")
        
        // Ensure the array is large enough
        while images2DArray.count <= selectedOption {
            images2DArray.append([])
        }
        
        // Update the specific sub-array
        images2DArray[selectedOption] = newImages
        saveImages2DArray()
    }
    
    func saveImages2DArray() {
        do {
            let data = try JSONSerialization.data(withJSONObject: images2DArray, options: [])
            UserDefaults.standard.set(data, forKey: "images2DArrayKey")
        } catch {
            print("Error serializing 2D array of images: \(error)")
        }
    }
    
    func getCurrentImageFilenames() -> [String] {
        let selectedOption = UserDefaults.standard.integer(forKey: "selectedOption")
        return (selectedOption < images2DArray.count) ? images2DArray[selectedOption] : []
    }

    
    @objc func handlePinchGesture(_ recognizer: UIPinchGestureRecognizer) {
        if recognizer.state == .began || recognizer.state == .changed {
            showTemplateOnCapturedImageView()
        } else if recognizer.state == .ended {
            
            // Hide or remove the templateImageView
        }
    }
    @objc func handlePanGesture(_ recognizer: UIPanGestureRecognizer) {
        if recognizer.state == .began || recognizer.state == .changed {
            // Show template
            showTemplate()
        } else if recognizer.state == .ended {
            // Hide template
            hideTemplate()
        }
    }
    
    
    @objc func showTemplate(){
        //let currentSelectedOption = AppState.shared.selectedOption
        // let count = UserDefaults.standard.integer(forKey: photoCounterKey)
        view.bringSubviewToFront(imageView)
        
        if isToggleTrue {
            hideCustomMode()
            imageView.isHidden = false
            guard let template = UIImage(named: "Template0.png") else { return }
            imageView.image = template
            
            
            imageView.contentMode = .scaleAspectFit
            imageView.translatesAutoresizingMaskIntoConstraints = false
            
            let aspectRatio = template.size.width / template.size.height
            let targetWidth = view.bounds.width
            
            NSLayoutConstraint.activate([
                imageView.widthAnchor.constraint(equalToConstant: targetWidth),
                imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 1/aspectRatio),
                imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ])
        }
        else{
            imageView.isHidden = true
            showCustomMode()
        }
        
        print("Selected option changed. Update UI accordingly.")
    }
    
    //CIV TEMPLATE STUFF______________
    
    func setupTemplateImageView() {
        //let currentSelectedOption = AppState.shared.selectedOption
        guard let templateImage = UIImage(named: "Template0.png") else { return }
        
        let imageView = UIImageView(image: templateImage)
        imageView.contentMode = .scaleAspectFit
        imageView.frame = view.bounds // Adjust as needed
        imageView.isUserInteractionEnabled = false
        imageView.isHidden = true // Initially hidden
        view.addSubview(imageView)
        view.bringSubviewToFront(imageView) // Ensure it's on top
        
        templateImageView = imageView // Store the reference
    }
    
    @objc func showTemplateOnCapturedImageView() {
        templateImageView?.isHidden = false
    }
    
    func hideTemplate(){
        templateImageView?.isHidden = true
        print("template hide attempted")
    }
    
    func setupCustomMode(){
        
        let targetWidth = view.bounds.width
        
        NSLayoutConstraint.activate([
            customPicture.widthAnchor.constraint(equalToConstant: targetWidth),
            customPicture.heightAnchor.constraint(equalTo: customPicture.widthAnchor, multiplier: 1),
            customPicture.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            customPicture.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        
        //let photoCounter = UserDefaults.standard.integer(forKey: photoCounterKey)
        
        [customPicture].forEach { imageView in
            imageView.layer.borderWidth = 10
            imageView.layer.borderColor = UIColor.white.cgColor
            imageView.layer.cornerRadius = 40  // adjust for desired bevel
            imageView.clipsToBounds = true
            imageView.alpha = 0.5 // semi-transparent if photoCounter is less than 5
            
            
        }
        
        
        
    }
    
    
    func showCustomMode(){
        customPicture.isHidden = false
    }
    
    func hideCustomMode(){
        customPicture.isHidden = true
    }
    
    private func configureAndAddImageView() {
        imageView.contentMode = .scaleAspectFill
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 10 // Beveled edges
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        
        // Constraints to center the image and set its size
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            imageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor)
        ])
    }
    
    // Function to configure and add placeholder view
    private func configureAndAddPlaceholderView() {
        placeholderView.layer.borderWidth = 2 // Adjust as needed
        placeholderView.layer.borderColor = UIColor.white.cgColor
        placeholderView.layer.cornerRadius = 10 // Beveled edges
        placeholderView.backgroundColor = .clear
        placeholderView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(placeholderView)
        
        // Constraints to center the placeholder and set its size
        NSLayoutConstraint.activate([
            placeholderView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            placeholderView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            placeholderView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5),
            placeholderView.heightAnchor.constraint(equalTo: placeholderView.widthAnchor)
        ])
    }
    
    
    
    @objc func handleImageTap() {
        let capturedImageFilenames = getCurrentImageFilenames()
        let photoCounter = UserDefaults.standard.integer(forKey: photoCounterKey)
        
        print("handleImageTap count:")
        print(photoCounter)
        
        if photoCounter >= 5 {
            let galleryVC = GalleryViewController()
            galleryVC.delegate = self
            galleryVC.capturedImageFilenames = self.capturedImageFilenames
            self.present(galleryVC, animated: true, completion: nil)
        }else{
            let alert = UIAlertController(title: "Gallery Locked", message: "You need to capture 5 photos to access the gallery.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    
    
    func setupIndicatorViewConstraints() {
        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        
        // Define the distance from the top
        let topDistance: CGFloat = 15 // Adjust this value as needed
        
        NSLayoutConstraint.activate([
            // Center the indicatorView horizontally in the view
            indicatorView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            // Position the indicatorView a fixed distance from the top of the view
            indicatorView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: topDistance),
            // Set the width of the indicatorView
            indicatorView.widthAnchor.constraint(equalToConstant: 100),
            // Set the height of the indicatorView
            indicatorView.heightAnchor.constraint(equalTo: indicatorView.widthAnchor, multiplier: 0.5)
        ])
    }
    
    
    
    
    
    func updateIndicator() {
        let photoCounter = UserDefaults.standard.integer(forKey: photoCounterKey)
        let imageName = "Align\(photoCounter).png"
        
        if let image = UIImage(named: imageName) {
            indicatorView?.image = image
        } else {
            // Provide a default image or handle the error
            print("Failed to load image named: \(imageName)")
            // Set a default image or leave the image view empty
            indicatorView?.image = UIImage(named: "Align5.png") // Replace with your default image
        }
        
        print("indicator updated")
        print("current count is \(photoCounter)")
    }
    
    
    
    override func viewDidAppear(_ animated: Bool) {
        print("view appeared")
        super.viewDidAppear(animated)
        //let photoCounter = UserDefaults.standard.integer(forKey: photoCounterKey)
        
        showTemplate()
        let photoCounter = UserDefaults.standard.integer(forKey: photoCounterKey)
        if photoCounter == 0 {
            print("VIEWDID APPEAR READ COUNT AT 0")
            showVideoPopup()
        }
        updateIndicator()
        
        //showIntroVideoIfNeeded()
        playIntroVideoIfNeeded()
        // Check if the counter needs to be reset
        checkAndResetCounterIfNeeded()
        checkOptionStates()
        
        
    }
    
    
    
    
    func playIntroVideoIfNeeded() {
        let photoCounter = UserDefaults.standard.integer(forKey: photoCounterKey)
        
        if photoCounter == 0 {
            DispatchQueue.main.async {
                self.setupBlackBackgroundView()
                self.setupPlayerContainerView()
                self.setupPlayerAndPlay()
            }
        }
    }
    
    private func setupBlackBackgroundView() {
        // Initialize and set up the black background view
        //let blackBackgroundView = UIView()
        blackBackgroundView.backgroundColor = .black
        blackBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(blackBackgroundView)
        // Activate constraints
        NSLayoutConstraint.activate([
            blackBackgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            blackBackgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            blackBackgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blackBackgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissVideoPlayer))
        blackBackgroundView.addGestureRecognizer(tapGesture)
        
        // Add tap gesture recognizer to the blackBackgroundView to skip the video
        
    }
    
    private func setupPlayerContainerView() {
        // Initialize and set up the player container view
        playerContainerView = UIView()
        playerContainerView?.backgroundColor = .black
        playerContainerView?.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(playerContainerView!)
        
        // Activate constraints
        NSLayoutConstraint.activate([
            playerContainerView!.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playerContainerView!.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            playerContainerView!.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1),
            playerContainerView!.heightAnchor.constraint(equalTo: playerContainerView!.widthAnchor, multiplier: 9/16)
        ])
        
        // Call layoutIfNeeded() to update the layout immediately
        playerContainerView?.layoutIfNeeded()
    }
    
    private func setupPlayerAndPlay() {
        // Ensure the video file exists
        guard let path = Bundle.main.path(forResource: "Intro", ofType: "mp4") else {
            print("Intro video not found")
            return
        }
        
        // Set up the player and player layer
        let videoURL = URL(fileURLWithPath: path)
        playerTwo = AVPlayer(url: videoURL)
        playerLayer = AVPlayerLayer(player: playerTwo)
        
        // Configure the player layer and add it to the container view
        playerLayer?.frame = playerContainerView!.bounds
        playerLayer?.videoGravity = .resizeAspect
        playerContainerView?.layer.addSublayer(playerLayer!)
        
        // Play the video
        playerTwo?.play()
        
        // Add observer for when the video finishes playing
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.videoDidEnd),
                                               name: .AVPlayerItemDidPlayToEndTime,
                                               object: playerTwo?.currentItem)
        
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissVideoPlayer))
        playerContainerView?.addGestureRecognizer(tapGesture)
    }
    @objc func videoDidEnd(notification: Notification) {
        // Increment photoCounter after the video has finished playing
        //UserDefaults.standard.set(1, forKey: "photoCounterKey")
        
        // Dismiss the video player
        playerTwo?.pause()
        playerLayer?.removeFromSuperlayer()
        playerContainerView?.removeFromSuperview()
        blackBackgroundView.removeFromSuperview()
        
        //view.subviews.first(where: { $0.backgroundColor == .black })?.removeFromSuperview()
    }
    
    @objc func dismissVideoPlayer() {
        // Stop the video playback
        playerTwo?.pause()
        
        // Remove the player layer and container view from the view hierarchy
        playerLayer?.removeFromSuperlayer()
        playerContainerView?.removeFromSuperview()
        blackBackgroundView.removeFromSuperview()
        
    }
    
    
    
    func updateCapturedImagesArray() {
        capturedImages.removeAll()  // Clear the array to avoid duplication
        
        for filename in capturedImageFilenames {
            if let image = loadImage(named: filename) {
                capturedImages.append(image)
            }
        }
    }
    
    
    
    
    
    //TEMPLATE SETTINGS STUFF
    
    
    

    
    private func setupSettingsButton() {
        settingsButton.addTarget(self, action: #selector(openSettings), for: .touchUpInside)
        
        // Other setup code...
        // Set constraints to not stretch the image
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        settingsButton.imageView?.tintColor = nil
        settingsButton.imageView?.contentMode = .scaleAspectFit
        view.addSubview(settingsButton)
        
        // Calculate the button width as 1/6th of the screen width
        let buttonWidth = UIScreen.main.bounds.width / 5
        // Calculate the button height maintaining the image aspect ratio (600x300)
        let buttonHeight = buttonWidth / 1.5
        
        
        
        // Constraints to position the button in the top-left corner of the view
        NSLayoutConstraint.activate([
            settingsButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            settingsButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 30),
            settingsButton.widthAnchor.constraint(equalToConstant: buttonWidth), // Dynamic width
            settingsButton.heightAnchor.constraint(equalToConstant: buttonHeight) // Dynamic height
        ])

        startSlideshow()
        
    }

//    @objc func openSettings() {
//        // Your existing logic for opening settings
//        print("Settings opened")
//    }
    
    private func startSlideshow() {
            slideshowTimer?.invalidate() // Invalidate any existing timer
            slideshowTimer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(changeSlideshowImage), userInfo: nil, repeats: true)
        }
    
    //GPT
    
    @objc private func changeSlideshowImage() {
        let currentSelectedOption = AppState.shared.selectedOption
        let currentButton = createButtonArray(excluding: currentSelectedOption)

        // Update the button image using the current index
        if currentButtonIndex < currentButton.count {
            updateButtonImage(for: currentButton[currentButtonIndex])
        }

        // Increment the index or reset it if it exceeds the array length
        currentButtonIndex = (currentButtonIndex + 1) % currentButton.count
    }

    func createButtonArray(excluding currentSelectedOption: Int) -> [Int] {
        let range = 0...4
        return range.filter { $0 != currentSelectedOption }
    }

//    private func updateButtonImage(for option: Int) {
////        let gearImage = UIImage(named: "Gear.png")
//        guard let buttonImage = UIImage(named: "Template\(option).png")?.withRenderingMode(.alwaysOriginal) else {
//            print("Image for option \(option) not found")
//            return
//        }
//        settingsButton.setImage(buttonImage, for: .normal)
////        settingsButton.setImage(gearImage, for: .normal)
//    }
    
    private func updateButtonImage(for option: Int) {
        guard let originalImage = UIImage(named: "Template\(option).png") else {
            print("Image for option \(option) not found")
            return
        }

        let whiteTintedImage = applyWhiteTintToImage(originalImage)
        settingsButton.setImage(whiteTintedImage?.withRenderingMode(.alwaysOriginal), for: .normal)
        settingsButton.tintColor = .white // Explicitly set the tint color to white
    }
    
    private func applyWhiteTintToImage(_ image: UIImage) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)

        let context = UIGraphicsGetCurrentContext()
        context?.translateBy(x: 0, y: image.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)

        let rect = CGRect(origin: .zero, size: image.size)

        // Draw the original image
        context?.draw(image.cgImage!, in: rect)

        // Set blend mode to source in and fill with white color
        context?.setBlendMode(.sourceIn)
        context?.setFillColor(UIColor.white.cgColor)
        context?.fill(rect)

        let whiteTintedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return whiteTintedImage
    }
    
    private func setupGearImageView() {
        gearImageView.image = UIImage(named: "Gear.png")
        gearImageView.translatesAutoresizingMaskIntoConstraints = false
        gearImageView.contentMode = .scaleAspectFit

        view.addSubview(gearImageView)
        //view.sendSubviewToBack(gearImageView)

        // Calculate the button width as 1/5th of the screen width and apply a scale factor
        let baseButtonWidth = UIScreen.main.bounds.width / 5
        let scaleFactor: CGFloat = 1.3  // 20% larger
        let scaledWidth = baseButtonWidth * scaleFactor
        let scaledHeight = scaledWidth / 1.5  // Maintain the aspect ratio of 600x300

        NSLayoutConstraint.activate([
            gearImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10 - (scaledHeight - (baseButtonWidth / 1.5)) / 2),
            gearImageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 30 - (scaledWidth - baseButtonWidth) / 2),
            gearImageView.widthAnchor.constraint(equalToConstant: scaledWidth),
            gearImageView.heightAnchor.constraint(equalToConstant: scaledHeight)
        ])
    }
    
   

    
    
    
    //Me
//
//    private func startSlideshow() {
//        slideshowTimer?.invalidate() // Invalidate any existing timer
//        slideshowTimer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(changeSlideshowImage), userInfo: nil, repeats: true)
//    }
//
//    @objc private func changeSlideshowImage() {
//        let currentSelectedOption = AppState.shared.selectedOption
//
//
////        let currentButton = nil
////        if currentSelectedOption != 0{
////            let currentButton = 0
////        }else{
////            let currentButton = 1
////        }
////
////        if currentButton == currentSelectedOption{
////            //
////        }
////
////        if currentSelectedOption < 5 {
////            updateButtonImage(for: currentSelectedOption)
////        } else {
////            // Reset the option count or handle as required for the slideshow
////            // For example, cycle through options 0-4
////        }
//    }
//
//    func createButtonArray(excluding currentSelectedOption: Int) -> [Int] {
//        let range = 0...4
//        return range.filter { $0 != currentSelectedOption }
//    }
//
//    private func updateButtonImage(for option: Int) {
//        guard let buttonImage = UIImage(named: "Template\(option).png")?.withRenderingMode(.alwaysOriginal) else {
//            print("Image for option \(option) not found")
//            return
//        }
//        settingsButton.setImage(buttonImage, for: .normal)
//    }
    
    //@State private var options = [false, false, false, false, false, false]
    
    @objc private func openSettings() {
        print(selectedOption)
        // Initialize SettingsView with the binding.
        let settingsView = SettingsView()
        
        // Present the hosting controller with the SettingsView.
        let hostingController = UIHostingController(rootView: settingsView)
        self.present(hostingController, animated: true, completion: nil)
    }
    
    
    private func checkOptionStates() {
        if SharedData.shared.selectedOption < 5 {
            print("first 5")
            // React to the first option being selected
        }
        else{
            print("number 6")
        }
        // Add more checks for other options as needed
    }
    
    
    
    
    func showVideoPopup() {
        popupView = UIView()
        popupView?.backgroundColor = .black
        popupView?.layer.cornerRadius = 30
        popupView?.frame = CGRect(x: 40, y: 280, width: self.view.frame.width - 80, height: self.view.frame.width - 80)
        
        if let path = Bundle.main.path(forResource: "Tut", ofType:"mp4") {
            let videoURL = URL(fileURLWithPath: path)
            player = AVPlayer(url: videoURL)
        }
        if let player = player, let popup = popupView {
            let playerLayer = AVPlayerLayer(player: player)
            playerLayer.frame = CGRect(x: 0, y: 0, width: popup.frame.width, height: popup.frame.height - 50)
            popup.layer.addSublayer(playerLayer)
            
            // Play the video
            player.play()
            
            // Add observer to know when the video playback ends
            //NotificationCenter.default.addObserver(self, selector: #selector(dismissPopup), name: .AVPlayerItemDidPlayToEndTime, object: nil)
            
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: player.currentItem,
                queue: .main
            ) { [weak self] _ in
                self?.player?.seek(to: CMTime.zero)
                self?.player?.play()
            }
        } else {
            print("Video not found")
            return
        }
        
        // Add tap gesture recognizer to the popupView to dismiss it
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissPopup))
        popupView?.addGestureRecognizer(tapGesture)
        print("adding popup")
        if let popup = popupView {
            self.view.addSubview(popup)
            print(popup)
        }
    }
    
    
    @objc func dismissPopup() {
        print("dismisspopup called")
        player?.pause()
        player = nil
        if popupView?.superview != nil {
            print("Popup view has a superview")
            popupView?.removeFromSuperview()
        } else {
            print("Popup view doesn't have a superview")
        }
        popupView?.removeFromSuperview()
        print("attempting to remove popup")
        //playGif()
        showTemplate()
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        
    }
    
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = view.bounds
        shutterButton.center = CGPoint(x: view.frame.size.width/2, y: view.frame.size.height - 150)
        //gifImageView.frame = view.bounds // Set the frame for the GIF view to match the view bounds
    }
    
    
    private func checkCameraPermissions(){
        switch AVCaptureDevice.authorizationStatus(for: .video){
            
        case .notDetermined:
            // Request
            AVCaptureDevice.requestAccess(for: .video){ [weak self] granted in guard granted else{
                return
            }
                DispatchQueue.main.async {
                    self?.setUpCamera()
                }
            }
        case .restricted:
            break
        case .denied:
            break
        case .authorized:
            setUpCamera()
        @unknown default:
            break
        }
    }
    
    
    private func setUpCamera(){
        let session = AVCaptureSession()
        if let device = AVCaptureDevice.default(for: .video){
            do {
                let input = try AVCaptureDeviceInput(device: device)
                if session.canAddInput(input){
                    session.addInput(input)
                }
                if session.canAddOutput(output){
                    session.addOutput(output)
                }
                
                previewLayer.videoGravity = .resizeAspectFill
                previewLayer.session = session
                
                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    session.startRunning()
                    
                    DispatchQueue.main.async {
                        self?.session = session
                    }
                }
                
            }
            catch{
                print(error)
            }
        }
    }
    
    
    @objc private func didTapTakePhoto() {
        output.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else {
            return
        }
        tempCapturedImage = image
        
        // Only add the image if the flag is set to true
        if shouldAddCapturedImage {
            imageCaptured(image)
            shouldAddCapturedImage = false // Reset the flag
        }
        // createOrUpdateGif() // Create or update the GIF
        
        
        session?.stopRunning()
        
        capturedImageView = UIImageView(image: image)
        capturedImageView.contentMode = .scaleAspectFill
        capturedImageView.frame = view.bounds
        view.addSubview(capturedImageView)
        
        setupImageReviewButtons()
        setupGestureRecognizers() // Make sure this is active
        //setupTemplateImageView()
        
    }
    
    
    var capturedImageView: UIImageView!
    
    var saveButton: UIButton!
    var retakeButton: UIButton!
    var templateImageView: UIImageView!
    
    
    func setupImageReviewButtons() {
        // Define button sizes and positions
        let buttonPadding: CGFloat = 10
        let buttonSize: CGFloat = 150 // Size for retake button
        let saveButtonSize: CGFloat = 200 // Larger size for save button
        
        
        
        // Initialize and configure saveButton
        saveButton = UIButton(frame: CGRect(x: (view.bounds.width - saveButtonSize) / 2, y: view.bounds.height, width: saveButtonSize, height: saveButtonSize))
        if let saveImage = UIImage(named: "NewSave") {
            saveButton.setImage(saveImage, for: .normal)
            saveButton.imageView?.contentMode = .scaleAspectFit // Keep the image's aspect ratio
        }
        saveButton.addTarget(self, action: #selector(savePhoto), for: .touchUpInside)
        
        // Initialize and configure retakeButton
        retakeButton = UIButton(frame: CGRect(x: (view.bounds.width - buttonSize) / 2, y: view.bounds.height + saveButtonSize + buttonPadding, width: buttonSize, height: buttonSize))
        if let retakeImage = UIImage(named: "NewRetake") {
            retakeButton.setImage(retakeImage, for: .normal)
            retakeButton.imageView?.contentMode = .scaleAspectFit // Keep the image's aspect ratio
        }
        retakeButton.addTarget(self, action: #selector(retakePhoto), for: .touchUpInside)
        
        // Add buttons to the view
        view.addSubview(saveButton)
        view.addSubview(retakeButton)
        
        // Animate buttons onto the screen
        UIView.animate(withDuration: 0.2) {
            self.saveButton.center.y -= (saveButtonSize + self.view.safeAreaInsets.bottom + 100)
            self.retakeButton.center.y -= (buttonSize + self.view.safeAreaInsets.bottom + 220)
        }
    }
    
    
    
//    func saveAndStoreImage(_ image: UIImage) {
//        //let number = selectedOption
//        let filename = "image\(Date().timeIntervalSince1970).jpeg"
//        if saveImage(image, named: filename) {
//            capturedImageFilenames.append(filename)
//            UserDefaults.standard.set(capturedImageFilenames, forKey: "capturedImageFilenamesKey")
//            
//            // Optionally, you can add a slight delay to ensure unique filenames
//            Thread.sleep(forTimeInterval: 0.001)
//        }
//    }
    func saveAndStoreImage(_ image: UIImage) {
        let selectedOption = UserDefaults.standard.integer(forKey: "selectedOption")

        // Ensure the 2D array is large enough
        while images2DArray.count <= selectedOption {
            images2DArray.append([])
        }

        let filename = "image\(Date().timeIntervalSince1970).jpeg"
        if saveImage(image, named: filename) {
            // Append the filename to the appropriate sub-array
            images2DArray[selectedOption].append(filename)

            // Save the updated 2D array to UserDefaults
            saveImages2DArray()

            // Optionally, you can add a slight delay to ensure unique filenames
            Thread.sleep(forTimeInterval: 0.001)
        }
    }

    
    // Inside your ViewController class
    // EDITING PORTION _____
    
    func setupGestureRecognizers() {
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        
        capturedImageView.isUserInteractionEnabled = true
        capturedImageView.addGestureRecognizer(pinchGesture)
        capturedImageView.addGestureRecognizer(panGesture)
    }
    
    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let view = gesture.view else { return }
        
        if gesture.state == .began || gesture.state == .changed {
            let currentScale = view.frame.size.width / view.bounds.size.width
            let newScale = currentScale * gesture.scale
            if newScale > 1 && newScale < 2 { // Assuming the max zoom is 3x
                view.transform = view.transform.scaledBy(x: gesture.scale, y: gesture.scale)
            }
            gesture.scale = 1
        }
        if gesture.state == .began || gesture.state == .changed {
            showTemplateOnCapturedImageView()
        } else if gesture.state == .ended {
            hideTemplate()
        }
    }
    
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        if let view = gesture.view {
            let newCenter = CGPoint(x: view.center.x + translation.x, y: view.center.y + translation.y)
            // Restrict movement within the parent view's bounds
            if view.bounds.contains(newCenter) {
                view.center = newCenter
                gesture.setTranslation(CGPoint.zero, in: view)
            }
        }
        if gesture.state == .began || gesture.state == .changed {
            showTemplateOnCapturedImageView()
        } else if gesture.state == .ended {
            hideTemplate()
        }
    }
    
    //End _____
    
    
    
    
    @objc func savePhoto() {
        var photoCounter = UserDefaults.standard.integer(forKey: photoCounterKey)
        
        if photoCounter < 5 {
            photoCounter += 1
            UserDefaults.standard.set(photoCounter, forKey: photoCounterKey)
            UserDefaults.standard.synchronize() // Ensure data is saved immediately
            print("#2")
            //indicatorView.updateIndicator()
            setupLayout()
        }
        
        saveButton.isHidden = true
        retakeButton.isHidden = true
        
        
        var capturedImage: UIImage?
        
        // Correct way to get the key window in iOS 13 and later
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
            
            let rect = capturedImageView.convert(capturedImageView.bounds, to: window)
            
            capturedImage = captureScreen(in: rect)
        }
        
        // Check if the capturedImage is not nil before proceeding
        guard let imageToSave = capturedImage else { return }
        
        // Now capturedImage is available for the rest of your code
        shouldAddCapturedImage = true
        capturedImages.append(imageToSave)
        saveAndStoreImage(imageToSave)
        
        print("savePhoto")
        print(capturedImageFilenames)
        
        updateImageDisplay()
        returnToCameraView()
    }
    
    
    func captureTransformedImage(from imageView: UIImageView) -> UIImage? {
        // Create a temporary image view with the same image and transformations
        let tempImageView = UIImageView(image: imageView.image)
        tempImageView.transform = imageView.transform
        tempImageView.bounds = imageView.bounds
        tempImageView.contentMode = imageView.contentMode
        
        // The center should be adjusted based on the panned position
        tempImageView.center = CGPoint(x: imageView.bounds.midX - imageView.frame.origin.x,
                                       y: imageView.bounds.midY - imageView.frame.origin.y)
        
        // Add the temporary image view to the window
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.addSubview(tempImageView)
            tempImageView.center = window.center
            
            // Capture the image
            let renderer = UIGraphicsImageRenderer(bounds: tempImageView.frame)
            let capturedImage = renderer.image { _ in
                tempImageView.drawHierarchy(in: tempImageView.bounds, afterScreenUpdates: true)
            }
            
            // Remove the temporary image view
            tempImageView.removeFromSuperview()
            
            return capturedImage
        }
        
        return nil
    }
    
    
    func captureScreen(in rect: CGRect) -> UIImage? {
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            return nil
        }
        
        let renderer = UIGraphicsImageRenderer(bounds: rect)
        let capturedImage = renderer.image { _ in
            window.drawHierarchy(in: rect, afterScreenUpdates: true)
        }
        
        return capturedImage
        
    }
    
    
    
    
    
    
    
    
    @objc func retakePhoto() {
        returnToCameraView()
    }
    
    func returnToCameraView() {
        capturedImageView.removeFromSuperview()
        saveButton.removeFromSuperview()
        retakeButton.removeFromSuperview()
        session?.startRunning()
        //showTemplate()
    }
    
    
    
    func setupLayout() {
        // Top right corner
        NSLayoutConstraint.activate([
            imageDisplayView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            imageDisplayView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            imageDisplayView.widthAnchor.constraint(equalToConstant: 80),  // Adjust as needed
            imageDisplayView.heightAnchor.constraint(equalToConstant: 110), // Adjust as needed
            
            picture1.centerXAnchor.constraint(equalTo: imageDisplayView.centerXAnchor),
            picture1.centerYAnchor.constraint(equalTo: imageDisplayView.centerYAnchor),
            picture1.widthAnchor.constraint(equalToConstant: 60),
            picture1.heightAnchor.constraint(equalToConstant: 60),
            
            picture2.bottomAnchor.constraint(equalTo: picture1.bottomAnchor, constant: 10),
            picture2.trailingAnchor.constraint(equalTo: picture1.leadingAnchor, constant: 50),
            picture2.widthAnchor.constraint(equalToConstant: 60),
            picture2.heightAnchor.constraint(equalToConstant: 60),
            
            picture3.bottomAnchor.constraint(equalTo: picture2.bottomAnchor, constant: 10),
            picture3.trailingAnchor.constraint(equalTo: picture2.leadingAnchor, constant: 50),
            picture3.widthAnchor.constraint(equalToConstant: 60),
            picture3.heightAnchor.constraint(equalToConstant: 60)
            
            
        ])
        
        
        let photoCounter = UserDefaults.standard.integer(forKey: photoCounterKey)
        
        [picture1, picture2, picture3].forEach { imageView in
            imageView.layer.borderWidth = 3
            imageView.layer.borderColor = UIColor.white.cgColor
            imageView.layer.cornerRadius = 10  // adjust for desired bevel
            imageView.clipsToBounds = true
            if photoCounter >= 5 {
                imageView.alpha = 1.0 // fully opaque if photoCounter is 5 or more
            } else {
                imageView.alpha = 0.5 // semi-transparent if photoCounter is less than 5
            }
        }
        setupCustomMode()
        
        
    }
    
    
    
//    func updateImageDisplay() {
//        let count = capturedImageFilenames.count
//        
//        // Clear all images first
//        picture1.image = nil
//        picture2.image = nil
//        picture3.image = nil
//        customPicture.image = nil
//        
//        // Helper function to safely load images
//        func safelyLoadImage(named name: String) -> UIImage? {
//            return loadImage(named: name) ?? nil
//        }
//        
//        if count >= 1 {
//            picture3.image = safelyLoadImage(named: capturedImageFilenames[count - 1])
//            customPicture.image = safelyLoadImage(named: capturedImageFilenames[count - 1])
//        }
//        if count >= 2 {
//            picture2.image = safelyLoadImage(named: capturedImageFilenames[count - 2])
//        }
//        if count >= 3 {
//            picture1.image = safelyLoadImage(named: capturedImageFilenames[count - 3])
//        }
//        
//        updateIndicator()
//    }
    
    func updateImageDisplay() {
        let selectedOption = UserDefaults.standard.integer(forKey: "selectedOption")
        let currentFilenames = (selectedOption < images2DArray.count) ? images2DArray[selectedOption] : []
        let count = currentFilenames.count
        
        // Clear all images first
        picture1.image = nil
        picture2.image = nil
        picture3.image = nil
        customPicture.image = nil
        
        // Helper function to safely load images
        func safelyLoadImage(named name: String) -> UIImage? {
            return loadImage(named: name) ?? nil
        }
        
        if count >= 1 {
            picture3.image = safelyLoadImage(named: currentFilenames[count - 1])
            customPicture.image = safelyLoadImage(named: currentFilenames[count - 1])
        }
        if count >= 2 {
            picture2.image = safelyLoadImage(named: currentFilenames[count - 2])
        }
        if count >= 3 {
            picture1.image = safelyLoadImage(named: currentFilenames[count - 3])
        }
        
        updateIndicator()
    }

    
    
    
    func imageCaptured(_ image: UIImage) {
        capturedImages.insert(image, at: 0)
    }
    
    func saveImage(_ image: UIImage, named: String) -> Bool {
        print("saveImage")
        // print("saveImage called from \(Thread.callStackSymbols)")
        
        guard let data = image.jpegData(compressionQuality: 1.0) else {
            return false
        }
        let fullPath = getDocumentsDirectory().appendingPathComponent(named)
        do {
            try data.write(to: fullPath)
            return true
        } catch {
            print("Unable to write the image data to the disk")
            return false
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    
    func loadImage(named filename: String) -> UIImage? {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        if let documentsDirectory = paths.first {
            let imagePath = documentsDirectory.appending("/\(filename)")
            return UIImage(contentsOfFile: imagePath)
        }
        return nil
    }
    
    
    
    func getImage(named: String) -> UIImage? {
        let fullPath = getDocumentsDirectory().appendingPathComponent(named)
        return UIImage(contentsOfFile: fullPath.path)
    }
    
    //_____INDICATOR_____________
    
    
    func checkAndResetCounterIfNeeded() {
        let currentDate = Date()
        let calendar = Calendar.current
        
        // Get the last reset date from UserDefaults
        let lastResetDate = UserDefaults.standard.object(forKey: "LastResetDate") as? Date ?? currentDate
        
        // Calculate the date and time for the reset (5 AM today)
        let resetDateComponents = calendar.dateComponents([.year, .month, .day], from: currentDate)
        guard let resetDateToday = calendar.date(from: resetDateComponents),
              let resetDateTime = calendar.date(bySettingHour: 19, minute: 24, second: 0, of: resetDateToday) else { return }
        
        
        
        
        if lastResetDate < resetDateTime && currentDate >= resetDateTime || !calendar.isDate(currentDate, inSameDayAs: lastResetDate) {
            resetCounter()
            UserDefaults.standard.set(currentDate, forKey: "LastResetDate")
        }
        print(currentDate)
        print(lastResetDate)
        print(resetDateTime)
        
    }
    
    
    
    @objc func resetCounter() {
        UserDefaults.standard.set(0, forKey: photoCounterKey)
        UserDefaults.standard.synchronize()
        updateIndicator()
        print("count reset")
        setupLayout()
    }
    
    
    private func setupImageView() {
        let imageViewWidth: CGFloat = 300 / 2.5
        let imageViewHeight: CGFloat = 200 / 2.5
        let xPos = (view.bounds.width - imageViewWidth) / 2
        imageView = UIImageView(frame: CGRect(x: xPos, y: 50, width: imageViewWidth, height: imageViewHeight))
        imageView.contentMode = .scaleAspectFit
        view.addSubview(imageView)
    }
    
    
    private func setupToggleButton() {
        toggleButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toggleButton)
        let math = (view.frame.width * 0.13)
        NSLayoutConstraint.activate([
                toggleButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: math),
                toggleButton.topAnchor.constraint(equalTo: shutterButton.topAnchor, constant: 10), // 10 is the spacing between the rectangle and the button
                toggleButton.widthAnchor.constraint(equalToConstant: 80),
                toggleButton.heightAnchor.constraint(equalToConstant: 80)
            ])

            toggleButton.addTarget(self, action: #selector(toggleButtonTapped), for: .touchUpInside)
            updateToggleButtonImage()
    }
    
    var isToggleTrue = true // The boolean value to track the state

    private func updateToggleButtonImage() {
        let imageName = isToggleTrue ? "ToggleTrue.png" : "ToggleFalse.png"
        toggleButton.setImage(UIImage(named: imageName), for: .normal)
    }
    
    @objc private func toggleButtonTapped() {
        isToggleTrue.toggle()
        updateToggleButtonImage()
        //updateCurrentSelectedOption()
    }
    
//    private func updateCurrentSelectedOption() {
//        if isToggleTrue {
//            // Set CurrentSelectedOption to its previous value between 0 and 4
//            // You need to have a way to remember the last selected option
//            if AppState.shared.selectedOption != 5{
//                AppState.shared.selectedOption = previousSelectedOption
//            }else{
//                AppState.shared.selectedOption = 0
//            }
//            //AppState.shared.selectedOption = previousSelectedOption
//        } else {
//            // When the toggle is false, set CurrentSelectedOption to 5
////            if AppState.shared.selectedOption != 5{
////                previousSelectedOption = AppState.shared.selectedOption
////            }
//            AppState.shared.selectedOption = 5
//        }
//    }
    
    
    
}

let placeholderView = UIView()


extension ViewController: GalleryViewControllerDelegate {
    func clearAllPhotos() {
        // Your logic to clear all photos goes here
        print("clearing")
        
        capturedImageFilenames.removeAll()
        
        print(capturedImageFilenames)
        UserDefaults.standard.set([String](), forKey: "capturedImageFilenamesKey")
        
        updateCapturedImagesArray()
        updateImageDisplay()
        resetCounter()
    }
    
    func betaOverride(){
        let galleryVC = GalleryViewController()
        galleryVC.delegate = self
        galleryVC.capturedImageFilenames = self.capturedImageFilenames
        self.present(galleryVC, animated: true, completion: nil)
    }
}





extension UIImage {
    func resized(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, self.scale)
        self.draw(in: CGRect(origin: .zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }
}

extension ViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        // Settings screen was dismissed, check the options
        checkOptionStates()
    }
}




