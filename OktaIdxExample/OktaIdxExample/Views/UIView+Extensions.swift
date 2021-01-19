import UIKit

extension UIView {
    func allInputFields() -> [UITextInput] {
        var result: [UITextInput] = []
        self.subviews.forEach { (view) in
            result.append(contentsOf: view.allInputFields())
            if let inputView = view as? UITextInput {
                result.append(inputView)
            }
        }
        return result
    }
}

