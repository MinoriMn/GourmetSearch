import Combine
import APIKit

class GourmetSearchAPI {
    private let apiKey: String

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    public func searchShops(
        id: [String]? = nil,
        keyword: String? = nil,
        lat: Float? = nil,
        lng: Float? = nil,
        range: GourmetSearchRequest.Parameter.Range? = nil,
        genre: String? = nil,
        order: GourmetSearchRequest.Parameter.Order? = nil,
        start: Int? = nil,
        count: Int? = nil
    ) -> AnyPublisher<[Shop], Error> {
        return Future<[Shop], Error>() { [weak self] promise in
            guard let self = self else {
                promise(.failure(CommonError.couldNotFoundSelf))
                return
            }
            let parameter: GourmetSearchRequest.Parameter = .init(
                key: self.apiKey,
                id: id,
                keyword: keyword,
                lat: lat,
                lng: lng,
                range: range,
                genre: genre,
                order: order,
                start: start,
                count: count
            )
            let request = GourmetSearchRequest(parameter: parameter)

            Session.send(request) { result in
                switch result {
                case .success(let response):
                    print(response)
                    promise(.success(response.shop))
                case .failure(let error):
                    print(error)
                    promise(.failure(error))
                }
            }

        }
        .eraseToAnyPublisher()
    }
}

struct GourmetSearchRequest: Request {
    //リクエスト先のurl
    var baseURL: URL {
        return URL(string: "https://webservice.recruit.co.jp/hotpepper/gourmet")!
    }

    var path: String {
//        var param: String = "?key=\(parameter.key)&format=json"
//
//        if let id = parameter.id {
//            param += "&id=\(id.joined(separator:","))"
//        }
//        if let keyword = parameter.keyword {
//            param += "&keyword=\(keyword)"
//        }
//        if let lat = parameter.lat, let lng = parameter.lng {
//            param += "&lat=\(lat)"
//            param += "&lng=\(lng)"
//        }
//        if let range = parameter.range {
//            param += "&range=\(range.rawValue)"
//        }
//        if let genre = parameter.genre {
//            param += "&genre=\(genre)"
//        }
//        param += "&lunch=\(parameter.lunch ? 1 : 0)"
//        param += "&pet=\(parameter.pet ? 1 : 0)"
//        if let order = parameter.order {
//            param += "&order=\(order.rawValue)"
//        }
//        if let start = parameter.start {
//            param += "&start=\(start)"
//        }
//        if let count = parameter.count {
//            param += "&count=\(count)"
//        }

        return "/v1/"
    }

    //httpメソッド
    var method: HTTPMethod {
        return .get
    }

    //レスポンスデータのデコード
    func response(from object: Any, urlResponse: HTTPURLResponse) throws -> Response {
        guard let data = object as? Data else {
            throw ResponseError.unexpectedObject(object)
        }
        let jsonDecoder = JSONDecoder()
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        return try jsonDecoder.decode(Response.self, from: data)
    }

    let parameter: Parameter
    var parameters: Any? {
        var params: [String: Any] = ["key": parameter.key, "format": "json"]
        if let id = parameter.id {
            params["id"] = id.joined(separator:",")
        }
        if let keyword = parameter.keyword {
            params["keyword"] = keyword
        }
        if let lat = parameter.lat, let lng = parameter.lng {
            params["lat"] = lat
            params["lng"] = lng
        }
        if let range = parameter.range {
            params["range"] = range.rawValue
        }
        if let genre = parameter.genre {
            params["genre"] = genre
        }
        params["lunch"] = parameter.lunch ? 1 : 0
        params["pet"] = parameter.pet ? 1 : 0
        if let order = parameter.order {
            params["order"] = order.rawValue
        }
        if let start = parameter.start {
            params["start"] = start
        }
        if let count = parameter.count {
            params["count"] = count
        }

        return params
    }

//    var dataParser: DataParser {
//        return JSONDataParser(readingOptions: [.allowFragments])
//    }
}

extension GourmetSearchRequest {
    struct Parameter {
        let key: String
        let id: [String]?
        let keyword: String?
        let lat: Float?
        let lng: Float?
        let range: Range?
        let genre: String?
        let lunch: Bool = false
        let pet: Bool = false
        let order: Order?
        let start: Int?
        let count: Int?

        enum Range: Int {
            case u300m = 1
            case u500m = 2
            case u1000m = 3
            case u2000m = 4
            case u3000m = 5
        }

        enum Order: Int {
            case name = 1
            case genre = 2
            case area = 3
            case recommendation = 4
        }
    }
}

extension GourmetSearchRequest {
    struct Response: Codable {
        // お店
        struct Shop: Codable {
            // お店ジャンル
            struct Genre: Codable {
                let code: String
                let name: String
            }

            // ディナー予算
            struct Budget: Codable {
                let code: String
                let name: String
                let average: String
            }

            // 店舗URL
            struct ShopURL: Codable {
                let pc: String?
            }

            struct Photo: Codable {
                struct PC: Codable  {
                    let l: String?
                    let m: String?
                    let s: String?
                }

                struct Mobile: Codable  {
                    let l: String?
                    let s: String?
                }

                let pc: PC
                let mobile: Mobile
            }

            let id: String
            let name: String
            let logoImage: String?
            let address: String
            let lat: Float
            let lng: Float
            let genre: Genre
            let budget: Budget
            let urls: ShopURL
            let photo: Photo
            let open: String?
            let close: String?
        }

        let apiVersion: String
        let resultsAvailable: Int
        let resultsReturned: Int
        let resultsStart: Int
        let shop: [Shop]
    }
}
