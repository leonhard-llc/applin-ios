import Foundation
import OSLog
import UIKit

class PhotoEditor: UIViewController {
    static let logger = Logger(subsystem: "Applin", category: "PhotoEditor")

    static func edit(_ navController: UINavigationController, _ image: UIImage, aspectRatio: Float32) async throws -> UIImage? {
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

    private let titleLabel: UILabel!
    private let cancelButton: UIButton!
    private let saveButton: UIButton!
    private let resizer: UIView!
    private let topShade: UIView!
    private let leftShade: UIView!
    private let rightShade: UIView!
    private let bottomShade: UIView!
    private let portal: UIView!
    private let imageView: UIImageView!
    private let sourceSize: CGSize
    private let resultSize: CGSize
    private let sourceAspectRatio: CGFloat
    private let resultAspectRatio: CGFloat
    private let initialScale: CGFloat
    private let minScale: CGFloat
    private let maxScale: CGFloat
    private let scrollLimits: CGSize
    /// Radians.
    private var rotation: CGFloat = 0.0
    private var scale: CGFloat = 0.0
    private var offset = CGSize.zero

    let promise: ApplinPromise<UIImage?> = ApplinPromise()

    init(_ image: UIImage, aspectRatio: Float32) {
        Self.logger.dbg("PhotoEditor.init")
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

        let saveAction = UIAction(title: "    Save    ", handler: { _ in
            Self.logger.dbg("saveButton UIAction")
            // TODO: Render image.
            let _ = promise.tryComplete(value: nil)
        })
        self.saveButton = UIButton(type: .system, primaryAction: saveAction)
        self.saveButton.translatesAutoresizingMaskIntoConstraints = false
        self.saveButton.setTitleColor(.label.dark())

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
        self.sourceSize = image.size
        self.sourceAspectRatio = image.size.width / image.size.height
        if self.sourceAspectRatio < self.resultAspectRatio {
            // Source is taller than result.
            let resultWidth = image.size.width
            let resultHeight = resultWidth / self.resultAspectRatio
            self.resultSize = CGSize(width: resultWidth, height: resultHeight)
            let scaledSourceHeight = self.resultSize.width / self.sourceAspectRatio
            let verticalRange = scaledSourceHeight - resultHeight
            self.scrollLimits = CGSize(width: 0, height: verticalRange / 2.0)
        } else if self.sourceAspectRatio == self.resultAspectRatio {
            self.resultSize = image.size
            self.scrollLimits = CGSize.zero
        } else {
            // Source is wider than result.
            let resultHeight = image.size.height
            let resultWidth = resultHeight * self.resultAspectRatio
            self.resultSize = CGSize(width: resultWidth, height: resultHeight)
            let scaledSourceWidth = self.resultSize.height * self.sourceAspectRatio
            let horizontalRange = scaledSourceWidth - resultWidth
            self.scrollLimits = CGSize(width: horizontalRange / 2.0, height: 0)
        }
        Self.logger.dbg("sourceSize=\(self.sourceSize) sourceAspectRatio=\(self.sourceAspectRatio) resultAspectRatio=\(self.resultAspectRatio) resultSize=\(self.resultSize) scrollLimits=\(self.scrollLimits)")
        self.initialScale = max(image.size.width, image.size.height) / min(image.size.width, image.size.height)
        self.minScale = 0.5 * min(self.sourceAspectRatio, 1.0 / self.sourceAspectRatio)
        self.maxScale = 5.0 * max(self.sourceAspectRatio, 1.0 / self.sourceAspectRatio)
        self.scale = self.initialScale;

        super.init(nibName: nil, bundle: nil)

        self.view.backgroundColor = .black
        self.view.addSubview(self.titleLabel)
        self.view.addSubview(self.cancelButton)
        self.view.addSubview(self.saveButton)
        self.view.addSubview(self.resizer)

        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(onDoubleTap))
        tapRecognizer.numberOfTapsRequired = 2
        self.resizer.addGestureRecognizer(tapRecognizer)
        self.resizer.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(onPan)))

        NSLayoutConstraint.activate([
            self.titleLabel.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 4.0),
            self.titleLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            self.resizer.topAnchor.constraint(equalTo: self.titleLabel.bottomAnchor, constant: 4.0),
            self.resizer.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            self.resizer.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            self.cancelButton.topAnchor.constraint(equalTo: self.resizer.bottomAnchor, constant: 8.0),
            self.cancelButton.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 8.0),
            self.cancelButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -8.0),
            self.saveButton.topAnchor.constraint(equalTo: self.resizer.bottomAnchor, constant: 8.0),
            self.saveButton.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -8.0),
            self.saveButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -8.0),
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
            self.portal.widthAnchor.constraint(equalTo: self.portal.heightAnchor, multiplier: CGFloat(aspectRatio)),
            self.imageView.topAnchor.constraint(equalTo: self.portal.topAnchor),
            self.imageView.leftAnchor.constraint(equalTo: self.portal.leftAnchor),
            self.imageView.rightAnchor.constraint(equalTo: self.portal.rightAnchor),
            self.imageView.bottomAnchor.constraint(equalTo: self.portal.bottomAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not implemented")
    }

    func updateImageTransform() {
        Self.logger.dbg("scale=\(self.scale) offset=\(self.offset) rotation=\(self.rotation)")
        let scaleViewToResult = self.resultSize.width / self.portal.bounds.width
        self.imageView.transform =
                CGAffineTransform.identity
                        .scaledBy(x: self.scale, y: self.scale)
                        .scaledBy(x: 1.0 / scaleViewToResult, y: 1.0 / scaleViewToResult)
                        //.rotated(by: self.rotation * 180.0 / CGFloat.pi)
                        .translatedBy(x: self.offset.width, y: self.offset.height)
                        .scaledBy(x: scaleViewToResult, y: scaleViewToResult)
    }

    @objc func onDoubleTap() {
        Self.logger.info("onDoubleTap")
        self.rotation = 0.0
        self.offset = CGSize.zero
        self.scale = self.initialScale
        self.updateImageTransform()
    }

    @objc func onPan(_ panRecognizer: UIPanGestureRecognizer) {
        if panRecognizer.state != .began && panRecognizer.state != .changed {
            return
        }
        let delta = panRecognizer.translation(in: self.portal)
        let scaleViewToResult = self.resultSize.width / self.portal.bounds.width
        self.offset.width += delta.x * scaleViewToResult
        self.offset.height += delta.y * scaleViewToResult
        panRecognizer.setTranslation(.zero, in: self.portal)
        //Self.logger.debug("onPan \(delta.x),\(delta.y)")
        if self.rotation == 0.0 && self.scale == self.initialScale {
            // Constrain scrolling.
            self.offset.width = self.offset.width.clamp(-self.scrollLimits.width, self.scrollLimits.width)
            self.offset.height = self.offset.height.clamp(-self.scrollLimits.height, self.scrollLimits.height)
        }
        self.updateImageTransform()
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
