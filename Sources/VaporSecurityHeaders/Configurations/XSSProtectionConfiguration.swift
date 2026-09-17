import Vapor

public struct XSSProtectionConfiguration: SecurityHeaderConfiguration {
    public init() {}

    func setHeader(on response: inout Response, from request: Request) {
        response.headers[.xssProtection] = "0"
    }
}
