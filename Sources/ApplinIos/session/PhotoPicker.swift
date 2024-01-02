import Foundation
import PhotosUI // Imports PhotoKit.

class PhotoPicker: ObservableObject, PHPickerViewControllerDelegate {
    let promise: ApplinPromise<PHPickerResult?> = ApplinPromise()

    @MainActor
    static func pick(_ navController: UINavigationController) async -> Result<Data, String>? {
        let photoPicker = PhotoPicker()
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.preferredAssetRepresentationMode = .compatible
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = photoPicker
        await navController.presentAsync(picker, animated: true)
        let optResult = await photoPicker.promise.value()
        await navController.dismissAsync(animated: true)
        guard let result = optResult else {
            return nil
        }
        let promise: ApplinPromise<Result<UIImage, String>> = ApplinPromise()
        result.itemProvider.loadObject(ofClass: UIImage.self) { reading, error in
            if error != nil {
                #if targetEnvironment(simulator)
                let suffix = "\nNote that Apple Simulator fails reading HEIC images (bug 63426347)."
                #else
                let suffix = ""
                #endif
                promise.complete(value: .failure(
                        "Error reading image: \"\(error?.localizedDescription ?? "nil")\".\(suffix)"
                ))
            } else if let uiImage = reading as? UIImage {
                promise.complete(value: .success(uiImage))
            } else {
                promise.complete(value: .failure("Error reading image."))
            }
        }
        let uiImage: UIImage
        switch await promise.value() {
        case let .failure(err):
            return .failure(err)
        case let .success(u):
            uiImage = u
        }
        let optData = await Task<Data?, Never> {
            uiImage.jpegData(compressionQuality: 0.9)
        }
                .value
        if let data = optData {
            return .success(data)
        } else {
            return .failure("Error converting image to JPEG.")
        }
    }

    // PHPickerViewControllerDelegate

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        let _ = self.promise.tryComplete(value: results.first)
    }
}