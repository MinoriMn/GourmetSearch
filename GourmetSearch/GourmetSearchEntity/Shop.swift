import Foundation

typealias Shop = GourmetSearchRequest.Response.Results.Shop

extension Shop: Equatable {
    static func ==(lhs: Shop, rhs: Shop) -> Bool {
        return lhs.id == rhs.id
    }
}
