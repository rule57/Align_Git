import Foundation

class ViewControllerProvider: ObservableObject {
    private weak var viewController: ViewController?

    init(viewController: ViewController) {
        self.viewController = viewController
    }

    func clearAllPhotos() {
        viewController?.clearAllPhotos()
    }
    func betaOverride(){
        viewController?.betaOverride()
    }
}
