import Vapor

public struct SecurityHeaders: Sendable {

    var configurations: [any SecurityHeaderConfiguration]

    init(contentTypeConfiguration: ContentTypeOptionsConfiguration = ContentTypeOptionsConfiguration(option: .nosniff),
         contentSecurityPolicyConfiguration: ContentSecurityPolicyConfiguration = ContentSecurityPolicyConfiguration(value: ContentSecurityPolicy().defaultSrc(sources: CSPKeywords.`self`)),
         frameOptionsConfiguration: FrameOptionsConfiguration = FrameOptionsConfiguration(option: .deny),
         xssProtectionConfiguration: XSSProtectionConfiguration? = XSSProtectionConfiguration(),
         hstsConfiguration: StrictTransportSecurityConfiguration? = nil,
         serverConfiguration: ServerConfiguration? = nil,
         contentSecurityPolicyReportOnlyConfiguration: ContentSecurityPolicyReportOnlyConfiguration? = nil,
         referrerPolicyConfiguration: ReferrerPolicyConfiguration? = nil) {
        configurations = [contentTypeConfiguration, contentSecurityPolicyConfiguration, frameOptionsConfiguration]

        if let xssProtectionConfiguration {
            configurations.append(xssProtectionConfiguration)
        }

        if let hstsConfiguration = hstsConfiguration {
            configurations.append(hstsConfiguration)
        }

        if let serverConfiguration = serverConfiguration {
            configurations.append(serverConfiguration)
        }

        if let contentSecurityPolicyReportOnlyConfiguration = contentSecurityPolicyReportOnlyConfiguration {
            configurations.append(contentSecurityPolicyReportOnlyConfiguration)
        }

        if let referrerPolicyConfiguration = referrerPolicyConfiguration {
            configurations.append(referrerPolicyConfiguration)
        }
    }

}

extension SecurityHeaders: Middleware {

    public func respond(to request: Request, chainingTo next: any Responder) async throws -> Response {
        var response = try await next.respond(to: request)
        for spec in configurations {
            spec.setHeader(on: &response, from: request)
        }
        // Drop per-request CSP override after headers are applied.
        request.contentSecurityPolicy = nil
        return response
    }
}
