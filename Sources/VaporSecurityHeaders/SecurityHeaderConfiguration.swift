import Vapor

protocol SecurityHeaderConfiguration: Sendable {
    func setHeader(on response: inout Response, from request: Request)
}
