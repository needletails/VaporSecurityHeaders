import HTTPTypes
import Vapor

public extension HTTPField.Name {
    /// Referrer-Policy (not always present in HTTPTypes presets).
    static let referrerPolicy = HTTPField.Name("Referrer-Policy")!
}
