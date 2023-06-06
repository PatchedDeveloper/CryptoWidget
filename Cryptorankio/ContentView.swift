import SwiftUI

struct CoinData : Codable{
    let data: data
}

struct data: Codable {
    let name: String
    let symbol: String
    let price: CoinPrice
}

struct CoinPrice : Codable{
    let USD : Double
}


class BitcoinData: ObservableObject {
    @Published var bitcoin: CoinData?

    init() {
        guard let url = URL(string: "https://api.cryptorank.io/v0/coins/bitcoin?locale=en") else {
            print("Invalid URL")
            return
        }

        URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                print("Error fetching Bitcoin data: \(error.localizedDescription)")
                return
            }
            

            guard let data = data else {
                print("Invalid data")
                return
            }
            print(String(data: data, encoding: .utf8)!)
            do {
                let decodedData = try JSONDecoder().decode(CoinData.self, from: data)
                DispatchQueue.main.async {
                    self.bitcoin = decodedData
                }
            } catch {
                print("Error decoding Bitcoin data: \(error.localizedDescription)")
            }
        }.resume()
    }
}

struct ContentView: View {
    @ObservedObject var bitcoinData = BitcoinData()

    var body: some View {
        VStack {
            if let bitcoin = bitcoinData.bitcoin {
                Text(bitcoin.data.name)
                    .font(.title)
                Text("Symbol: \(bitcoin.data.symbol)")
                Text("Price: $\(String(format: "%.2f", bitcoin.data.price.USD))")
            } else {
                Text("Loading...")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
