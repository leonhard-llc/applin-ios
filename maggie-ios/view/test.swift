import UIKit

class TestController: UIViewController {
    var state: Bool = false
    var label1: UILabel?
    var label2: UILabel?
    var textField: UITextField?
    var constraints: [NSLayoutConstraint] = []

    required init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("unimplemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .systemBackground
        self.updateWidgets()
    }

    public func toggleState() {
        print("toggle")
        self.state.toggle()
        self.updateWidgets()
    }

    public func updateWidgets() {
        NSLayoutConstraint.deactivate(self.constraints)
        self.constraints.removeAll()
        if self.label1 == nil {
            self.label1 = UILabel()
            self.label1!.text = "label1"
            self.label1!.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(self.label1!)
        }
        if self.state {
            if self.label2 == nil {
                self.label2 = UILabel()
                self.label2!.text = "label2"
                self.label2!.translatesAutoresizingMaskIntoConstraints = false
                self.view.addSubview(self.label2!)
            }
        } else {
            if self.label2 != nil {
                self.label2!.removeFromSuperview()
                self.label2 = nil
            }
        }
        if self.textField == nil {
            self.textField = UITextField(frame: .zero)
            self.textField!.placeholder = "Login Name"
            self.textField!.borderStyle = .roundedRect
            self.textField!.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(self.textField!)
        }
        self.constraints.append(
                self.label1!.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor))
        var prevView: UIView = self.label1!
        if self.label2 != nil {
            self.constraints.append(
                    self.label2!.topAnchor.constraint(equalTo: prevView.bottomAnchor))
            prevView = self.label2!
        }
        self.constraints.append(
                self.textField!.topAnchor.constraint(equalTo: prevView.bottomAnchor))
        NSLayoutConstraint.activate(self.constraints)
    }
}

// @main
class TestAppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    override init() {
        super.init()
    }

    func application(
            _ application: UIApplication,
            didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        print("launch")
        // https://betterprogramming.pub/creating-ios-apps-without-storyboards-42a63c50756f
        let controller = TestController()
        Task(priority: .high) {
            while !Task.isCancelled {
                controller.toggleState()
                await sleep(ms: 5_000)
            }
        }
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window!.rootViewController = controller
        self.window!.makeKeyAndVisible()
        return true
    }
}
