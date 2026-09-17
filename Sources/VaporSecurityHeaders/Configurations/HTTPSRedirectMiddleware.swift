import HTTPTypes
import Vapor

/// Redirects non-HTTPS requests to HTTPS outside development.
///
/// Pass `environment` explicitly because Vapor 5 `Request` no longer carries
/// `application` without JWT context middleware.
public struct HTTPSRedirectMiddleware: Middleware {

    let allowedHosts: [String]?
    let environment: Environment

    public init(allowedHosts: [String]? = nil, environment: Environment = .production) {
        self.allowedHosts = allowedHosts
        self.environment = environment
    }

    public func respond(to request: Request, chainingTo next: any Responder) async throws -> Response {
        if environment == .development {
            return try await next.respond(to: request)
        }

        let proto = request.headers.forwarded.first?.proto
            ?? request.headers[.xForwardedProto]
            ?? request.url.scheme
            ?? "http"

        guard proto == "https" else {
            // HTTPField.Name.host is unavailable (use authority); clients still send Host.
            guard let host = request.headers[HTTPField.Name("Host")!] else {
                throw Abort(.badRequest)
            }

            if let allowedHosts = allowedHosts {
                guard allowedHosts.contains(host) else {
                    throw Abort(.badRequest)
                }
            }

            let httpsURL = "https://" + host + "\(request.url)"
            return request.redirect(to: httpsURL, redirectType: .permanent)
        }
        return try await next.respond(to: request)
    }
}
