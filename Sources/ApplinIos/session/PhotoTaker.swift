import AVFoundation
import Foundation
import UIKit

class PhotoTaker: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    let promise: ApplinPromise<[UIImagePickerController.InfoKey: Any]> = ApplinPromise()

    @MainActor
    static func take(_ navController: UINavigationController) async throws -> UIImage? {
        let allowed = await AVCaptureDevice.requestAccess(for: .video)
        if !allowed {
            let dialogCtl = UIAlertController(title: "Need Camera Permission", message: nil, preferredStyle: .alert)
            dialogCtl.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in }))
            dialogCtl.addAction(UIAlertAction(
                    title: "Open Settings",
                    style: .default,
                    handler: { _ in
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
            ))
            navController.present(dialogCtl, animated: true);
            return nil
        }
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
            throw ApplinError.appError("Camera is unavailable.")
        }
        let availableMediaTypes = UIImagePickerController.availableMediaTypes(for: .camera) ?? []
        if !availableMediaTypes.contains(UTType.image.identifier) {
            throw ApplinError.appError("Image capture is unavailable.")
        }
        let photoTaker = PhotoTaker()
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.mediaTypes = [UTType.image.identifier]
        if UIImagePickerController.isCameraDeviceAvailable(.front) {
            imagePicker.cameraDevice = .front
        }
        imagePicker.delegate = photoTaker
        navController.present(imagePicker, animated: true)

        let info = await photoTaker.promise.value()
        await navController.dismissAsync(animated: true)
        if info.isEmpty {
            return nil
        }
        guard let uiImage = (info[.editedImage] ?? info[.originalImage]) as? UIImage else {
            throw ApplinError.appError("Failed to retrieve image from camera.")
        }
        return uiImage
    }

    // UIImagePickerControllerDelegate
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        let _ = self.promise.tryComplete(value: [:])
    }

    func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        let _ = self.promise.tryComplete(value: info)
    }
}