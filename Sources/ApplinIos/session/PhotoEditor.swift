import Foundation
import OSLog
import UIKit

class PhotoEditor: UIViewController {
    static let logger = Logger(subsystem: "Applin", category: "PhotoEditor")

    static func edit(_ navController: UINavigationController, _ image: UIImage, aspectRatio: Float32) async throws -> Data? {
        let photoEditor = PhotoEditor(image, aspectRatio: aspectRatio)
        photoEditor.modalPresentationStyle = .fullScreen
        // TODO: Make the presented modal appear right-side up when device is upside down.
        navController.present(photoEditor, animated: true)
        //navController.pushViewController(photoEditor, animated: false)
        let value = await photoEditor.promise.value()
        photoEditor.dismiss(animated: true)
        //navController.popViewController(animated: false)
        return value
    }

    private let sourceImage: UIImage
    private let titleLabel: UILabel!
    private let cancelButton: UIButton!
    private var saveButton: UIButton?
    private let resizer: UIView!
    private let topShade: UIView!
    private let leftShade: UIView!
    private let rightShade: UIView!
    private let bottomShade: UIView!
    private let portal: UIView!
    private let imageView: UIImageView!
    private let sourceAspectRatio: CGFloat
    private let resultAspectRatio: CGFloat
    /// Radians.
    //private var rotation: CGFloat = 0.0
    private let initialScale: CGFloat
    private let minScale: CGFloat
    private let maxScale: CGFloat
    private var scale: CGFloat = 0.0
    /// Offset units are in result image widths.
    private let offsetScrollLimits: CGSize
    private var offset = CGSize.zero

    let promise: ApplinPromise<Data?> = ApplinPromise()

    init(_ image: UIImage, aspectRatio: Float32) {
        Self.logger.dbg("PhotoEditor.init")
        self.sourceImage = image
        self.titleLabel = UILabel()
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.titleLabel.text = "Crop"
        self.titleLabel.font = UIFont.preferredFont(forTextStyle: .title1)
        self.titleLabel.numberOfLines = 0
        self.titleLabel.textAlignment = .center
        self.titleLabel.textColor = .label.dark()

        let promise = self.promise
        let backAction = UIAction(title: "    Cancel    ", handler: { _ in
            Self.logger.dbg("cancelButton UIAction")
            let _ = promise.tryComplete(value: nil)
        })
        self.cancelButton = UIButton(type: .system, primaryAction: backAction)
        self.cancelButton.translatesAutoresizingMaskIntoConstraints = false
        self.cancelButton.setTitleColor(.label.dark())

        self.resizer = UIView()
        self.resizer.translatesAutoresizingMaskIntoConstraints = false
        self.resizer.clipsToBounds = true

        self.imageView = UIImageView(image: image)
        self.imageView.translatesAutoresizingMaskIntoConstraints = false
        self.imageView.contentMode = .scaleAspectFit
        self.resizer.addSubview(self.imageView)

        let resizer = self.resizer!

        func makeShade() -> UIView {
            let view = UIView()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.isOpaque = false
            view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
            resizer.addSubview(view)
            return view
        }

        self.topShade = makeShade()
        self.leftShade = makeShade()
        self.rightShade = makeShade()
        self.bottomShade = makeShade()

        self.portal = UIView()
        self.portal.translatesAutoresizingMaskIntoConstraints = false
        self.portal.isOpaque = false
        self.portal.layer.borderColor = CGColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
        self.portal.layer.borderWidth = 1.0
        self.resizer.addSubview(self.portal)

        precondition(image.size.width >= 1.0)
        precondition(image.size.height >= 1.0)
        self.resultAspectRatio = CGFloat(aspectRatio)
        self.sourceAspectRatio = image.size.width / image.size.height
        if self.sourceAspectRatio < self.resultAspectRatio {
            // Source is taller than result.
            self.initialScale = 1.0
            self.offsetScrollLimits = CGSize(
                    width: 0,
                    height: 0.5 * ((1.0 / self.sourceAspectRatio) - (1.0 / self.resultAspectRatio)))
        } else if self.sourceAspectRatio == self.resultAspectRatio {
            self.initialScale = 1.0
            self.offsetScrollLimits = CGSize.zero
        } else {
            // Source is wider than result.
            self.initialScale = self.sourceAspectRatio / self.resultAspectRatio
            self.offsetScrollLimits = CGSize(width: 0.5 * (self.initialScale - 1.0), height: 0)
        }
        Self.logger.dbg("sourceAspectRatio=\(self.sourceAspectRatio) resultAspectRatio=\(self.resultAspectRatio) scrollLimits=\(self.offsetScrollLimits)")
        self.minScale = 0.5 * min(self.sourceAspectRatio, 1.0 / self.sourceAspectRatio)
        self.maxScale = 5.0 * max(self.sourceAspectRatio, 1.0 / self.sourceAspectRatio)
        self.scale = self.initialScale;

        super.init(nibName: nil, bundle: nil)

        // This is here because UIButton.addAction(uiAction, for: .primaryActionTriggered) does not work.
        self.saveButton = UIButton(
                type: .system,
                primaryAction: UIAction(title: "    Save    ", handler: { [weak self] _ in self?.save() }))
        self.saveButton!.translatesAutoresizingMaskIntoConstraints = false
        self.saveButton!.setTitleColor(.label.dark())

        self.view.backgroundColor = .black
        self.view.addSubview(self.titleLabel)
        self.view.addSubview(self.cancelButton)
        self.view.addSubview(self.saveButton!)
        self.view.addSubview(self.resizer)

        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(onDoubleTap))
        tapRecognizer.numberOfTapsRequired = 2
        self.resizer.addGestureRecognizer(tapRecognizer)
        self.resizer.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(onPan)))
        self.resizer.addGestureRecognizer(
                // Apple doesn't document the signature of the action.
                UIPinchGestureRecognizer(target: self, action: #selector(onPinch)))

        // TODO: Support rotating.
        // TODO: Add instructions label.

        NSLayoutConstraint.activate([
            self.titleLabel.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 4.0),
            self.titleLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            self.resizer.topAnchor.constraint(equalTo: self.titleLabel.bottomAnchor, constant: 4.0),
            self.resizer.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            self.resizer.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            self.cancelButton.topAnchor.constraint(equalTo: self.resizer.bottomAnchor, constant: 8.0),
            self.cancelButton.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 8.0),
            self.cancelButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -8.0),
            self.saveButton!.topAnchor.constraint(equalTo: self.resizer.bottomAnchor, constant: 8.0),
            self.saveButton!.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -8.0),
            self.saveButton!.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -8.0),
            self.topShade.topAnchor.constraint(equalTo: self.resizer.topAnchor),
            self.topShade.leftAnchor.constraint(equalTo: self.resizer.leftAnchor),
            self.topShade.rightAnchor.constraint(equalTo: self.resizer.rightAnchor),
            self.bottomShade.leftAnchor.constraint(equalTo: self.resizer.leftAnchor),
            self.bottomShade.rightAnchor.constraint(equalTo: self.resizer.rightAnchor),
            self.bottomShade.bottomAnchor.constraint(equalTo: self.resizer.bottomAnchor),
            self.leftShade.topAnchor.constraint(equalTo: self.topShade.bottomAnchor),
            self.leftShade.leftAnchor.constraint(equalTo: self.resizer.leftAnchor),
            self.leftShade.bottomAnchor.constraint(equalTo: self.bottomShade.topAnchor),
            self.rightShade.topAnchor.constraint(equalTo: self.topShade.bottomAnchor),
            self.rightShade.rightAnchor.constraint(equalTo: self.resizer.rightAnchor),
            self.rightShade.bottomAnchor.constraint(equalTo: self.bottomShade.topAnchor),
            self.portal.topAnchor.constraint(equalTo: self.topShade.bottomAnchor),
            self.portal.leftAnchor.constraint(equalTo: self.leftShade.rightAnchor),
            self.portal.rightAnchor.constraint(equalTo: self.rightShade.leftAnchor),
            self.portal.bottomAnchor.constraint(equalTo: self.bottomShade.topAnchor),
            self.portal.centerXAnchor.constraint(equalTo: self.resizer.centerXAnchor),
            self.portal.centerYAnchor.constraint(equalTo: self.resizer.centerYAnchor),
            self.portal.widthAnchor.constraint(equalTo: self.portal.heightAnchor, multiplier: self.resultAspectRatio),
            self.imageView.centerXAnchor.constraint(equalTo: self.portal.centerXAnchor),
            self.imageView.centerYAnchor.constraint(equalTo: self.portal.centerYAnchor),
            self.imageView.leftAnchor.constraint(equalTo: self.portal.leftAnchor),
            self.imageView.rightAnchor.constraint(equalTo: self.portal.rightAnchor),
            self.imageView.heightAnchor.constraint(equalTo: self.imageView.widthAnchor, multiplier: 1.0 / self.sourceAspectRatio)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not implemented")
    }

    func updateImageTransform() {
        self.imageView.transform = CGAffineTransform.identity
                .scaledBy(x: self.imageView.bounds.width, y: self.imageView.bounds.width)
                .translatedBy(x: self.offset.width, y: self.offset.height)
                .scaledBy(
                        x: 1.0 / self.imageView.bounds.width,
                        y: 1.0 / self.imageView.bounds.width)
                .scaledBy(x: self.scale, y: self.scale)
    }

    @objc func onDoubleTap() {
        Self.logger.info("onDoubleTap")
        //self.rotation = 0.0
        self.offset = CGSize.zero
        //self.scale = self.initialScale
        Self.logger.debug("onPan scale=\(self.scale) offset=\(self.offset.width),\(self.offset.height)")
        self.updateImageTransform()
    }

    @objc func onPan(_ panRecognizer: UIPanGestureRecognizer) {
        if panRecognizer.state != .began && panRecognizer.state != .changed {
            return
        }
        let delta = panRecognizer.translation(in: self.portal)
        let offsetDX = delta.x / self.portal.bounds.width
        let offsetDY = delta.y / self.portal.bounds.width
        self.offset.width += offsetDX
        self.offset.height += offsetDY
        panRecognizer.setTranslation(.zero, in: self.portal)
        if /* self.rotation == 0.0 && */ self.scale == self.initialScale {
            self.offset.width = self.offset.width.clamp(-self.offsetScrollLimits.width, self.offsetScrollLimits.width)
            self.offset.height = self.offset.height.clamp(-self.offsetScrollLimits.height, self.offsetScrollLimits.height)
        } else {
            self.offset.width = self.offset.width.clamp(-0.8, 0.8)
            self.offset.height = self.offset.height.clamp(
                    -0.8 / self.sourceAspectRatio,
                    0.8 / self.sourceAspectRatio)
        }
        Self.logger.debug("onPan delta=\(offsetDX),\(offsetDY) offset=\(self.offset.width),\(self.offset.height)")
        self.updateImageTransform()
    }

    @objc func onPinch(_ pinchRecognizer: UIPinchGestureRecognizer) {
        // TODO: Adjust offset.  See code in `EditPhotoViewState._doPinchZoom` in `c1/dart/lib/page/edit_photo_page.dart`.
        self.scale *= pinchRecognizer.scale
        self.scale = self.scale.clamp(minScale, maxScale)
        Self.logger.info("onPinch dScale=\(pinchRecognizer.scale) scale=\(self.scale)")
        pinchRecognizer.scale = 1.0
        self.updateImageTransform()
    }

    @objc func save() {
        Self.logger.dbg("save")
        let before = Date.now
        let resultWidth: CGFloat
        let resultHeight: CGFloat
        if self.sourceAspectRatio < self.resultAspectRatio {
            // Source is taller than result.
            resultWidth = self.sourceImage.size.width
            resultHeight = resultWidth / self.resultAspectRatio
        } else if self.sourceAspectRatio == self.resultAspectRatio {
            resultWidth = self.sourceImage.size.width
            resultHeight = self.sourceImage.size.height
        } else {
            // Source is wider than result.
            resultHeight = self.sourceImage.size.height
            resultWidth = resultHeight * self.resultAspectRatio
        }
        let format = UIGraphicsImageRendererFormat()
        format.opaque = true
        format.scale = 1.0 // One pixel per point.
        format.preferredRange = .standard // Use sRGB.  Note that .extended is P3 color space.
        let renderer = UIGraphicsImageRenderer(
                size: CGSize(width: resultWidth, height: resultHeight), format: format)
        let image = renderer.jpegData(withCompressionQuality: 0.90, actions: { ctx in
            ctx.cgContext.concatenate(CGAffineTransform(scaleX: resultWidth, y: resultWidth))
            ctx.cgContext.concatenate(CGAffineTransform(translationX: 0.5, y: 0.5 / self.resultAspectRatio))
            //ctx.cgContext.concatenate(CGAffineTransform(rotationAngle: self.rotation * 180.0 / CGFloat.pi))
            ctx.cgContext.concatenate(CGAffineTransform(translationX: self.offset.width, y: self.offset.height))
            ctx.cgContext.concatenate(CGAffineTransform(scaleX: self.scale, y: self.scale))
            // I couldn't get UIImage.draw(in:) to work.  It sometimes renders shifted vertically.
            //let height = 1.0 / self.resultAspectRatio
            //self.sourceImage.draw(in: CGRect(x: -0.5, y: -0.5 * height, width: 1.0, height: height))
            //ctx.cgContext.setFillColor(CGColor(gray: 0.75, alpha: 0.85))
            //ctx.cgContext.fill(CGRect(x: -0.49, y: -0.49, width: 0.98, height: 0.98))
            ctx.cgContext.concatenate(CGAffineTransform(translationX: -0.5, y: -0.5 / self.sourceAspectRatio))
            ctx.cgContext.concatenate(CGAffineTransform(scaleX: 1.0 / self.sourceImage.size.width, y: 1.0 / self.sourceImage.size.width))
            self.sourceImage.draw(at: CGPoint(x: 0.0, y: 0.0))
        })
        Self.logger.debug("rendered and compressed image, elapsed=\(before.distance(to: Date.now))")
        let _ = self.promise.tryComplete(value: image)
    }

    // UIViewController

    override var prefersStatusBarHidden: Bool {
        true
    }

    override func viewDidLayoutSubviews() {
        self.updateImageTransform()
    }

    // We need this because UIKit doesn't call viewDidLayoutSubviews after the device rotates.
    override func viewWillTransition(
            to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        Self.logger.dbg("viewWillTransition")
        coordinator.animate(alongsideTransition: nil) { _ in
            // Runs after the rotation has completed.
            self.updateImageTransform()
        }
    }

}
