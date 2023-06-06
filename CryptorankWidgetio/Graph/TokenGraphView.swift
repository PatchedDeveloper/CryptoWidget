////
////  TokenModel.swift
////  CryptoApp
////
////  Created by Danila Kardashevkii on 11.04.2023.
////
//
//import Foundation
//
//class BitcoinGraphData: ObservableObject {
//    @Published var bitcoin: GraphModel?
//
//    init() {
//        guard let url = URL(string: "https://api.cryptorank.io/v0/charts/prices-by-coin?keys=bitcoin&days=7")
//        else {
//            print("Invalid URL")
//            return
//        }
//
//        URLSession.shared.dataTask(with: url) { (data, response, error) in
//            if let error = error {
//                print("Error fetching Bitcoin data: \(error.localizedDescription)")
//                return
//            }
//
//            guard let data = data
//            else {
//                print("Invalid data")
//                return
//            }
//
//            do {
//                let decodedData = try JSONDecoder().decode(GraphModel.self, from: data)
//                DispatchQueue.main.async {
////                    print(NSString(data: data, encoding:NSUTF8StringEncoding)!)
//                    self.bitcoin = decodedData
//                
//                }
//            } catch {
//                print("Error decoding Bitcoin data: \(error.localizedDescription)")
//            }
//        }.resume()
//    }
//    
//}
//struct GraphModel: Codable {
//    let data: GraphData
//}
//
//struct GraphData: Codable {
//    let bitcoin: BitcoinGraph
//}
//
//struct BitcoinGraph: Codable {
//    let timestamps: [Double]
//    let prices: [Double]
//}
