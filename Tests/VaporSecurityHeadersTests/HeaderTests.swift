import HTTPTypes
import Testing
import Vapor
import VaporTesting
import VaporSecurityHeaders

@Suite("Security headers")
struct HeaderTests {

    @Test("default headers")
    func defaultHeaders() async throws {
        try await withApp { app in
            app.middleware.use(SecurityHeadersFactory().build())
            app.get("test") { _ in "TEST" }
            try await app.testing { client in
                let response = try await client.get("test")
                #expect(response.status == .ok)
                #expect(response.headers[.xContentTypeOptions] == "nosniff")
                #expect(response.headers[.contentSecurityPolicy] == "default-src 'self'")
                #expect(response.headers[.xFrameOptions] == "DENY")
                #expect(response.headers[.xssProtection] == "0")
            }
        }
    }

    @Test("API factory headers")
    func apiHeaders() async throws {
        try await withApp { app in
            app.middleware.use(SecurityHeadersFactory.api().build())
            app.get("test") { _ in "TEST" }
            try await app.testing { client in
                let response = try await client.get("test")
                #expect(response.headers[.xContentTypeOptions] == "nosniff")
                #expect(response.headers[.contentSecurityPolicy] == "default-src 'none'")
                #expect(response.headers[.xFrameOptions] == "DENY")
                #expect(response.headers[.xssProtection] == "0")
            }
        }
    }

    @Test("HSTS and referrer policy")
    func hstsAndReferrer() async throws {
        try await withApp { app in
            let headers = SecurityHeadersFactory.api()
                .with(strictTransportSecurity: StrictTransportSecurityConfiguration())
                .with(referrerPolicy: .init(.noReferrer))
                .build()
            app.middleware.use(headers)
            app.get("test") { _ in "TEST" }
            try await app.testing { client in
                let response = try await client.get("test")
                #expect(response.headers[.strictTransportSecurity] == "max-age=31536000; includeSubDomains; preload")
                #expect(response.headers[.referrerPolicy] == "no-referrer")
            }
        }
    }

    @Test("per-request CSP override")
    func perRequestCSPOverride() async throws {
        try await withApp { app in
            app.middleware.use(SecurityHeadersFactory.api().build())
            app.get("route") { req -> String in
                req.contentSecurityPolicy = ContentSecurityPolicyConfiguration(
                    value: ContentSecurityPolicy().defaultSrc(sources: CSPKeywords.none).scriptSrc(sources: "test")
                )
                return "Different CSP!"
            }
            try await app.testing { client in
                let response = try await client.get("route")
                #expect(response.headers[.contentSecurityPolicy] == "default-src 'none'; script-src test")
            }
        }
    }

    @Test("headers still applied on abort")
    func headersOnAbort() async throws {
        try await withApp { app in
            app.middleware.use(SecurityHeadersFactory.api().build())
            app.middleware.use(ErrorMiddleware.default(environment: .testing))
            app.get("abort") { _ -> String in
                throw Abort(.badRequest)
            }
            try await app.testing { client in
                let response = try await client.get("abort")
                #expect(response.status == .badRequest)
                #expect(response.headers[.xContentTypeOptions] == "nosniff")
                #expect(response.headers[.contentSecurityPolicy] == "default-src 'none'")
                #expect(response.headers[.xFrameOptions] == "DENY")
            }
        }
    }

    @Test("content type options can be disabled")
    func contentTypeOptionsOff() async throws {
        try await withApp { app in
            let factory = SecurityHeadersFactory().with(contentTypeOptions: .init(option: .none))
            app.middleware.use(factory.build())
            app.get("test") { _ in "TEST" }
            try await app.testing { client in
                let response = try await client.get("test")
                #expect(response.headers[.xContentTypeOptions] == nil)
            }
        }
    }

    @Test("server header")
    func serverHeader() async throws {
        try await withApp { app in
            let factory = SecurityHeadersFactory().with(server: .init(value: "nudge"))
            app.middleware.use(factory.build())
            app.get("test") { _ in "TEST" }
            try await app.testing { client in
                let response = try await client.get("test")
                #expect(response.headers[.server] == "nudge")
            }
        }
    }
}

@Suite("HTTPS redirect")
struct RedirectionTests {

    @Test("redirects http to https")
    func redirectsToHTTPS() async throws {
        try await withApp { app in
            app.middleware.use(HTTPSRedirectMiddleware(environment: .production))
            app.get { _ in "Test" }
            try await app.testing { client in
                let response = try await client.get("/") { req in
                    req.headers[HTTPField.Name("Host")!] = "localhost:8080"
                }
                #expect(response.status == .movedPermanently)
                #expect(response.headers[.location] == "https://localhost:8080/")
            }
        }
    }

    @Test("skips redirect in development")
    func skipsInDevelopment() async throws {
        try await withApp { app in
            app.middleware.use(HTTPSRedirectMiddleware(environment: .development))
            app.get { _ in "Test" }
            try await app.testing { client in
                let response = try await client.get("/") { req in
                    req.headers[HTTPField.Name("Host")!] = "localhost:8080"
                }
                #expect(response.status == .ok)
            }
        }
    }

    @Test("allows when X-Forwarded-Proto is https")
    func allowsForwardedHTTPS() async throws {
        try await withApp { app in
            app.middleware.use(HTTPSRedirectMiddleware(environment: .production))
            app.get { _ in "Test" }
            try await app.testing { client in
                let response = try await client.get("/") { req in
                    req.headers[.xForwardedProto] = "https"
                }
                #expect(response.status == .ok)
            }
        }
    }

    @Test("rejects disallowed host")
    func rejectsDisallowedHost() async throws {
        try await withApp { app in
            app.middleware.use(
                HTTPSRedirectMiddleware(
                    allowedHosts: ["example.com"],
                    environment: .production
                )
            )
            app.get { _ in "Test" }
            try await app.testing { client in
                let response = try await client.get("/") { req in
                    req.headers[HTTPField.Name("Host")!] = "localhost:8080"
                }
                #expect(response.status == .badRequest)
            }
        }
    }
}
