import Vapor

public struct ContentTypeOptionsConfiguration: SecurityHeaderConfiguration {

    private let option: Options

    public init(option: Options) {
        self.option = option
    }

    public enum Options: Sendable {
        case nosniff
        case none
    }

    func setHeader(on response: inout Response, from request: Request) {
        switch option {
        case .nosniff:
            response.headers[.xContentTypeOptions] = "nosniff"
        case .none:
            break
        }
    }
}
