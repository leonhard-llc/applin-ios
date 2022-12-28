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
    private enum State {
        case loading(NoIntrinsicSizeActivityView)
        case image(UIImageView)
        case error(NoIntrinsicSizeImageView)
    }

    private var containerHelper: SingleViewContainerHelper?
    private var state: State

    private let lock = NSLock()
    private var aspectRatio: Double = 1.0
    private var url: URL?
    private var fetchImageTask: Task<(), Never>?

    override init(frame: CGRect) {
        print("ImageView.init")
        let indicator = NoIntrinsicSizeActivityView(style: .medium)
        self.state = .loading(indicator)
        super.init(frame: frame)
        self.containerHelper = SingleViewContainerHelper(superView: self)
        self.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.widthAnchor.constraint(equalToConstant: 100_000.0).withPriority(.fittingSizeLevel),
        ])
        self.backgroundColor = pastelYellow
        self.clipsToBounds = true
        indicator.startAnimating()
        Task {
            await self.updateViews()
        }
    }

    convenience init() {
        print("ColumnView.init")
        self.init(frame: CGRect.zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @MainActor
    func updateViews() async {
        switch self.state {
        case let .loading(indicator):
            print("ImageView.applyUpdate .loading")
            indicator.translatesAutoresizingMaskIntoConstraints = false
            self.containerHelper!.update(indicator, {
                [
                    self.heightAnchor.constraint(equalTo: self.widthAnchor, multiplier: self.aspectRatio),
                    indicator.centerXAnchor.constraint(equalTo: self.centerXAnchor),
                    indicator.centerYAnchor.constraint(equalTo: self.centerYAnchor),
                ]
            })
        case let .image(image):
            print("ImageView.applyUpdate .image")
            image.translatesAutoresizingMaskIntoConstraints = false
            image.contentMode = .scaleAspectFill
            self.containerHelper!.update(image, {
                [
                    self.heightAnchor.constraint(equalTo: self.widthAnchor, multiplier: self.aspectRatio),
                    image.centerXAnchor.constraint(equalTo: self.centerXAnchor),
                    image.centerYAnchor.constraint(equalTo: self.centerYAnchor),
                    image.widthAnchor.constraint(equalToConstant: 100_000.0).withPriority(.fittingSizeLevel),
                    image.widthAnchor.constraint(lessThanOrEqualTo: self.widthAnchor),
                    image.heightAnchor.constraint(lessThanOrEqualTo: self.heightAnchor),
                ]
            })
        case let .error(image):
            print("ImageView.applyUpdate .error")
            image.translatesAutoresizingMaskIntoConstraints = false
            image.tintColor = .systemGray
            self.containerHelper!.update(image, {
                [
                    self.heightAnchor.constraint(equalTo: self.widthAnchor, multiplier: self.aspectRatio),
                    image.centerXAnchor.constraint(equalTo: self.centerXAnchor),
                    image.centerYAnchor.constraint(equalTo: self.centerYAnchor),
                    image.widthAnchor.constraint(equalToConstant: 100_000.0).withPriority(.fittingSizeLevel),
                    image.widthAnchor.constraint(lessThanOrEqualTo: self.widthAnchor, multiplier: 0.5),
                    image.heightAnchor.constraint(lessThanOrEqualTo: self.heightAnchor, multiplier: 0.5),
                    image.heightAnchor.constraint(equalTo: image.widthAnchor),
                ]
            })
        }
    }

    @MainActor
    func showLoading() async {
        let indicator = NoIntrinsicSizeActivityView(style: .medium)
        indicator.startAnimating()
        self.state = .loading(indicator)
        await self.updateViews()
    }

    @MainActor
    func showImage(_ image: UIImage) async {
        self.state = .image(UIImageView(image: image))
        await self.updateViews()
    }

    @MainActor
    func showError() async {
        self.state = .error(NoIntrinsicSizeImageView(image: UIImage(systemName: "x.square")))
        await self.updateViews()
    }

    func fetchImage(_ url: URL) async {
        print("ImageView.fetchImage(\(url.absoluteString))")
        await self.showLoading()
        // TODO: Merge concurrent fetches of the same URL.  Maybe the ios library does this already?
        //  https://developer.apple.com/documentation/uikit/views_and_controls/table_views/asynchronously_loading_images_into_table_and_collection_views#3637628
        // TODO: Retry on error.
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
            let httpResponse: HTTPURLResponse
            do {
                let (data, urlResponse) = try await urlSession.data(for: urlRequest)
                httpResponse = urlResponse as! HTTPURLResponse
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
                await showImage(image)
                return
            } catch {
                print("ImageView.fetchImage(\(url.absoluteString) error: \(error)")
                await sleep(ms: 5_000)
            }
        }
        print("ImageView.fetchImage(\(url.absoluteString) giving up")
        await self.showError()
    }

    func update(_ url: URL, aspectRatio: Double) {
        print("ImageView.update aspectRatio=\(aspectRatio) url=\(url.absoluteString)")
        self.lock.lock()
        defer {
            self.lock.unlock()
        }
        self.aspectRatio = aspectRatio
        if self.url == url {
            Task {
                await self.updateViews()
            }
        } else {
            self.url = url
            self.fetchImageTask?.cancel()
            self.fetchImageTask = Task {
                await self.fetchImage(url)
            }
        }
    }
}
