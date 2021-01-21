import UIKit

extension UIView {
    func allInputFields() -> [UITextInput & UIResponder] {
        var result: [UITextInput & UIResponder] = []
        self.subviews.forEach { (view) in
            result.append(contentsOf: view.allInputFields())
            if let inputView = view as? UITextInput & UIResponder {
                result.append(inputView)
            }
        }
        return result
    }
}

