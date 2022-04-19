import Rswift

public extension StoryboardResourceWithInitialControllerType {

    @available(iOS 13.0, tvOS 13.0, *)
    func instantiateInitialViewController<ViewController>(creator: ((NSCoder) -> ViewController?)? = nil) -> UIViewController? where ViewController: UIViewController {
        UIStoryboard(resource: self).instantiateInitialViewController { coder in
            creator?(coder)
        }
    }

    @available(iOS 13.0, tvOS 13.0, *)
    func instantiateViewController<ViewController>(identifier: StoryboardViewControllerResource<ViewController>,creator: ((NSCoder) -> ViewController?)? = nil) -> UIViewController where ViewController: UIViewController {
        UIStoryboard(resource: self).instantiateViewController(identifier: identifier.description) { coder in
            return creator?(coder)
        }
    }

}
