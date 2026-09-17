import Vapor

public struct ServerConfiguration: SecurityHeaderConfiguration {
    private let value: String

    public init(value: String) {
        self.value = value
    }

    func setHeader(on response: inout Response, from request: Request) {
        response.headers[.server] = value
    }
}
