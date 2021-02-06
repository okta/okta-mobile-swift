import Foundation
import PlaygroundSupport
import SwiftUI
import XCTest
import OktaIdx

public class PlaygroundHelper: NSObject {
    enum Error: Swift.Error {
        case error(message: String)
    }
    
    public override init() {
        PlaygroundPage.current.needsIndefiniteExecution = true

        super.init()
    }
    
    public func expectation(for name: String? = nil) -> XCTestExpectation {
        return XCTestExpectation.init(description: name ?? "Waiting")
    }
    
    public func wait(for expectation: XCTestExpectation, timeout: TimeInterval = 5) {
        XCTWaiter().wait(for: [expectation], timeout: timeout)
    }
    
    public func handle(error: Swift.Error?) -> Swift.Error {
        print("Error: \(String(describing: error))")
        
        finish()
        return error ?? Error.error(message: "Unknown error")
    }
    
    public func handle(error message: String) -> Swift.Error {
        print(message)
        finish()
        return Error.error(message: message)
    }
    
    public func finish(with token: IDXClient.Token? = nil) {
        if let token = token {
            print("Received a successful token \(token)")
        } else {
            print("Finished execution")
        }
        PlaygroundPage.current.finishExecution()
    }
    
    public func showPrompt(for labelName: String) -> String {
        let expectation = XCTestExpectation(description: "Prompt for \(labelName)")
        var result: String = ""

        PlaygroundPage.current.setLiveView(InputView(labelName: labelName, completion: { (value) in
            result = value
            expectation.fulfill()
        }))

        wait(for: expectation, timeout: 60)

        return result
    }
}

public struct InputView: View {
    @State public var labelName: String
    @State public var value: String = ""
    public var completion: ((String)->Void)
    public var body: some View {
        Form {
            HStack {
                Text("\($labelName.wrappedValue):")
                TextField($labelName.wrappedValue, text: $value)
            }
            Button("Continue") {
                completion(value)
            }
        }
    }
}
