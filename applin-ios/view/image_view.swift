import Foundation
import UIKit

class NoIntrinsicSizeImageView: UIImageView {
    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
    }
}

class NoIntrinsicSizeActivityView: UIActivityIndicatorView {
    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
    }
}

/// ImageView loads an image from a URL and display it.
/// It shows an activity indicator while loading.
class ImageView: UIView {
    private static func makeIndicator() -> NoIntrinsicSizeActivityView {
        let indicator = NoIntrinsicSizeActivityView(style: .medium)
        indicator.startAnimating()
        return indicator
    }

    private enum Symbol: Equatable {
        case loading(NoIntrinsicSizeActivityView)
        case image(UIImageView, ApplinDisposition)
        case error(NoIntrinsicSizeImageView)
    }

    private var aspectRatioConstraint = ConstraintHolder()
    private var containerHelper: SingleViewContainerHelper?
    private var name: String = "ImageView"

    private let lock = ApplinLock()
    private var url: URL?
    private var fetchImageTask: Task<(), Never>?
    private var aspectRatio: Double
    private var symbol: Symbol

    init(aspectRatio: Double) {
        self.symbol = .loading(Self.makeIndicator())
        self.aspectRatio = aspectRatio
        super.init(frame: CGRect.zero)
        self.name = "ImageView{\(self.address)}"
        print("\(self).init")
        self.containerHelper = SingleViewContainerHelper(superView: self)
        //self.backgroundColor = pastelYellow
        self.clipsToBounds = true
        NSLayoutConstraint.activate([
            self.widthAnchor.constraint(equalToConstant: 100_000.0).withPriority(.defaultLow + 1.0),
        ])
        self.applyAspectRatio(aspectRatio)
        self.applySymbol(self.symbol)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @MainActor
    private func applyAspectRatio(_ aspectRatio: Double) {
        self.aspectRatioConstraint.set(
                self.widthAnchor.constraint(equalTo: self.heightAnchor, multiplier: aspectRatio))
    }

    @MainActor
    private func applySymbol(_ symbol: Symbol) {
        switch symbol {
        case let .loading(indicator):
            print("ImageView.applyUpdate .loading")
            indicator.translatesAutoresizingMaskIntoConstraints = false
            self.containerHelper!.update(indicator, {
                [
                    indicator.centerXAnchor.constraint(equalTo: self.centerXAnchor),
                    indicator.centerYAnchor.constraint(equalTo: self.centerYAnchor),
                ]
            })
        case let .image(image, disposition):
            print("ImageView.applyUpdate .image")
            image.translatesAutoresizingMaskIntoConstraints = false
            switch disposition {
            case .fit:
                image.contentMode = .scaleAspectFit
            case .stretch:
                image.contentMode = .scaleToFill
            case .cover:
                image.contentMode = .scaleAspectFill
            }
            self.containerHelper!.update(image, {
                [
                    image.leftAnchor.constraint(equalTo: self.leftAnchor),
                    image.rightAnchor.constraint(equalTo: self.rightAnchor),
                    image.topAnchor.constraint(equalTo: self.topAnchor),
                    image.bottomAnchor.constraint(equalTo: self.bottomAnchor),
                ]
            })
        case let .error(image):
            print("ImageView.applyUpdate .error")
            image.translatesAutoresizingMaskIntoConstraints = false
            image.tintColor = .systemGray
            self.containerHelper!.update(image, {
                [
                    image.centerXAnchor.constraint(equalTo: self.centerXAnchor),
                    image.centerYAnchor.constraint(equalTo: self.centerYAnchor),
                    image.widthAnchor.constraint(lessThanOrEqualTo: self.widthAnchor),
                    image.heightAnchor.constraint(lessThanOrEqualTo: self.heightAnchor),
                    image.widthAnchor.constraint(equalToConstant: 24.0).withPriority(.fittingSizeLevel),
                    image.heightAnchor.constraint(equalTo: image.widthAnchor),
                ]
            })
        }
    }

    @MainActor
    private func setSymbol(_ symbol: Symbol) {
        let changed = self.symbol != symbol
        self.symbol = symbol
        if changed {
            self.applySymbol(symbol)
        }
    }

    @MainActor
    private func fetchImage(_ url: URL, _ disposition: ApplinDisposition) async {
        print("ImageView.fetchImage(\(url.absoluteString))")
        self.name = "ImageView{\(self.address) \(url.absoluteString)}"
        let indicator = Self.makeIndicator()
        self.setSymbol(.loading(indicator))
        // TODO: Merge concurrent fetches of the same URL.  Maybe the ios library does this already?
        //  https://developer.apple.com/documentation/uikit/views_and_controls/table_views/asynchronously_loading_images_into_table_and_collection_views#3637628
        // TODO: When retrying multiple URLs at same server, round-robin the URLs.  Maybe the ios library does this already?
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10.0 /* seconds */
        config.timeoutIntervalForResource = 60.0 /* seconds */
        // TODONT: Don't set the config.urlCache to nil.  We want to use the cache.
        config.httpShouldSetCookies = true
        let urlSession = URLSession(configuration: config)
        defer {
            urlSession.invalidateAndCancel()
        }
        var urlRequest = URLRequest(
                url: url,
                cachePolicy: .useProtocolCachePolicy
        )
        urlRequest.httpMethod = "GET"
        for _ in [1, 2, 3, 4, 5] {
            if Task.isCancelled {
                return
            }
            print("ImageView.fetchImage(\(url.absoluteString)) start")
            do {
                let (data, urlResponse) = try await urlSession.data(for: urlRequest)
                let httpResponse = urlResponse as! HTTPURLResponse
                if !(200...299).contains(httpResponse.statusCode) {
                    if httpResponse.contentTypeBase() == "text/plain",
                       let string = String(data: data, encoding: .utf8) {
                        throw "server error: \(httpResponse.statusCode) "
                                + "\(HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)) \"\(string)\""
                    } else {
                        throw "server error: \(httpResponse.statusCode) "
                                + "\(HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)), "
                                + "len=\(data.count) \(httpResponse.mimeType ?? "")"
                    }
                }
                guard let image = UIImage(data: data) else {
                    throw "error processing data as image: \(data.count) bytes"
                }
                print("ImageView.fetchImage(\(url.absoluteString)) done")
                let uiImageView = UIImageView(image: image)
                self.setSymbol(.image(uiImageView, disposition))
                return
            } catch {
                print("ImageView.fetchImage(\(url.absoluteString) error: \(error)")
                await sleep(ms: 5_000)
            }
        }
        print("ImageView.fetchImage(\(url.absoluteString) giving up")
        let image = NoIntrinsicSizeImageView(image: UIImage(systemName: "xmark"))
        self.setSymbol(.error(image))
    }

    private func loadImageBundleFile(filepath: String, _ disposition: ApplinDisposition) async {
        do {
            print("ImageView.loadImageBundleFile(\(filepath))")
            let data = try await readBundleFile(filepath: filepath)
            guard let image = UIImage(data: data) else {
                throw "error processing data as image: \(data.count) bytes"
            }
            print("ImageView.loadImageBundleFile(\(filepath)) done")
            let uiImageView = UIImageView(image: image)
            Task { @MainActor in
                self.setSymbol(.image(uiImageView, disposition))
            }
        } catch {
            print("ImageView.loadImageBundleFile(\(filepath)) error: \(error)")
            let image = NoIntrinsicSizeImageView(image: UIImage(systemName: "xmark"))
            Task { @MainActor in
                self.setSymbol(.error(image))
            }
        }
    }

    func update(_ url: URL, aspectRatio: Double, _ disposition: ApplinDisposition) {
        Task { @MainActor in
            await self.lock.lockAsync({
                //print("ImageView.update aspectRatio=\(aspectRatio) url=\(url.absoluteString)")
                if self.aspectRatio != aspectRatio {
                    self.aspectRatio = aspectRatio
                    self.applyAspectRatio(aspectRatio)
                }
                if self.url != url {
                    self.url = url
                    self.fetchImageTask?.cancel()
                    self.fetchImageTask = Task {
                        if url.scheme == "asset" {
                            await self.loadImageBundleFile(filepath: url.path, disposition)
                        } else {
                            await self.fetchImage(url, disposition)
                        }
                    }
                } else if case let .image(image, oldDisposition) = self.symbol, oldDisposition != disposition {
                    let symbol: Symbol = .image(image, disposition)
                    self.symbol = symbol
                    self.applySymbol(symbol)
                }
            })
        }
    }

    override public var description: String {
        self.name
    }
}
