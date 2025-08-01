import Foundation

enum BuildEnv {
    static var googleMapsAPIKey: String {
        guard let path = Bundle.main.path(forResource: "Env", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let key = dict["GOOGLE_MAPS_API_KEY"] as? String else {
            fatalError("GOOGLE_MAPS_API_KEY missing in Env.plist")
        }
        return key
    }
}
