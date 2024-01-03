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
    //private let initialScale: CGFloat
    //private let minScale: CGFloat
    //private let maxScale: CGFloat
    /// Radians.
    //private var rotation: CGFloat = 0.0
    private var scale: CGFloat = 0.0
    /// Offset units are in result image widths.
    private let offsetScrollLimits: CGSize
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
        self.sourceAspectRatio = image.size.width / image.size.height
        if self.sourceAspectRatio < self.resultAspectRatio {
            // Source is taller than result.
            self.scale = 1.0
            self.offsetScrollLimits = CGSize(width: 0, height: 0.5 * (1.0 / self.sourceAspectRatio - 1.0 / self.resultAspectRatio))
        } else if self.sourceAspectRatio == self.resultAspectRatio {
            self.offsetScrollLimits = CGSize.zero
        } else {
            // Source is wider than result.
            self.scale = self.sourceAspectRatio / self.resultAspectRatio
            self.offsetScrollLimits = CGSize(width: 0.5 * (self.scale - 1.0), height: 0)
        }
        Self.logger.dbg("sourceAspectRatio=\(self.sourceAspectRatio) resultAspectRatio=\(self.resultAspectRatio) scrollLimits=\(self.offsetScrollLimits)")
        //self.initialScale = max(image.size.width, image.size.height) / min(image.size.width, image.size.height)
        //self.minScale = 0.5 * min(self.sourceAspectRatio, 1.0 / self.sourceAspectRatio)
        //self.maxScale = 5.0 * max(self.sourceAspectRatio, 1.0 / self.sourceAspectRatio)
        //self.scale = self.initialScale;

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
        Self.logger.dbg("offset=\(self.offset)")
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
        self.updateImageTransform()
    }

    @objc func onPan(_ panRecognizer: UIPanGestureRecognizer) {
        if panRecognizer.state != .began && panRecognizer.state != .changed {
            return
        }
        let delta = panRecognizer.translation(in: self.portal)
        self.offset.width += delta.x / self.portal.bounds.width
        self.offset.height += delta.y / self.portal.bounds.width
        panRecognizer.setTranslation(.zero, in: self.portal)
        //Self.logger.debug("onPan \(delta.x),\(delta.y)")
        //if self.rotation == 0.0 && self.scale == self.initialScale {
        // Constrain scrolling.
        self.offset.width = self.offset.width.clamp(-self.offsetScrollLimits.width, self.offsetScrollLimits.width)
        self.offset.height = self.offset.height.clamp(-self.offsetScrollLimits.height, self.offsetScrollLimits.height)
        //}
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
