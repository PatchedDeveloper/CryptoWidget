//
//  IntentHandler.swift
//  CryptorankAppIntent
//
//  Created by Danila Kardashevkii on 19.04.2023.
//

import Intents

//MARK: for search coin
struct TokenSearch: Codable {
    let data: [Datum]
}

//- Datum
struct Datum: Codable {
    let key: String
    let name: String
}

class IntentHandler: INExtension, CryptorankWidgetSettingsIntentHandling{
    
    func provideSymbolOptionsCollection(for intent: CryptorankWidgetSettingsIntent, with completion: @escaping (INObjectCollection<Symbol>?, Error?) -> Void) {
        let urlString = "https://api.cryptorank.io/v0/coins?limit=50"
        guard let url = URL(string: urlString) else {
            completion(nil, NSError(domain: "YourAppDomain", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let data = data {
                do {
                    let tokenSearch = try JSONDecoder().decode(TokenSearch.self, from: data)
                    let symbols = tokenSearch.data.map { Symbol(identifier: $0.key, display: $0.name) }
                    let collection = INObjectCollection(items: symbols)
                    completion(collection, nil)
                } catch let error {
                    completion(nil, error)
                }
            } else {
                completion(nil, error)
            }
        }
        task.resume()
    }
    
}
