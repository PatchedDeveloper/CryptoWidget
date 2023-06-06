//

//
//  Created by Danila Kardashevskii on 05.04.2023
//

import WidgetKit
import SwiftUI
import Intents

var apiKeys = "bitcoin"

func getSymbol(from configuration: CryptorankWidgetSettingsIntent) -> String {
    return configuration.Symbol?.identifier ?? "bitcoin"
}

//MARK: Structure for getting token data
struct CoinData : Codable{
    let data: Metadata
}
//Structure for data
struct Metadata: Codable {
    let name: String
    let symbol: String
    let key: String
    let price: CoinPrice
    let image : CoinImage
    let histPrices: CoinHistPrice
}
//Structure for Price
struct CoinPrice : Codable{
    let USD : Double
}
//Structure for Image
struct CoinImage : Codable{
    let x150 : String
}
//Structure Price for 24 hours
struct CoinHistPrice : Codable{
    let price24h : CoinHistPrices24
    //Attention: this variable is located in - enum CodingKeys
    enum CodingKeys : String, CodingKey{
        case price24h = "24H"
    }
}
struct CoinHistPrices24 : Codable{
    let USD : Double
}
//MARK: Structure for Entry
struct CoinDataEntry: TimelineEntry {
    let date: Date
    let data: CoinData
    let datagraph: GraphModel
    let datatoken : TokenSearch
    let configuration : CryptorankWidgetSettingsIntent
}
//MARK:  Timeline Provider
struct BitcoinDataProvider: IntentTimelineProvider {
    typealias Entry = CoinDataEntry
    typealias Intent = CryptorankWidgetSettingsIntent
            // дальше ваш код

    func placeholder( in context: Context) -> CoinDataEntry {
        CoinDataEntry(date: Date(), data: CoinData(data: Metadata(name: "Placeholder", symbol: "", key: "", price: CoinPrice(USD: 1), image: CoinImage(x150: ""), histPrices: CoinHistPrice(price24h: CoinHistPrices24(USD: 0)))), datagraph: GraphModel(data: GraphData(bitcoin: BitcoinGraph(timestamps: [], prices: []))), datatoken: TokenSearch(data: []),configuration: CryptorankWidgetSettingsIntent())
    }

    func getSnapshot(for configuration: CryptorankWidgetSettingsIntent,in context: Context, completion: @escaping (CoinDataEntry) -> ()) {
        let entry = CoinDataEntry(date: Date(), data: CoinData(data: Metadata(name: "Placeholder", symbol: "", key: "", price: CoinPrice(USD: 1), image: CoinImage(x150: ""), histPrices: CoinHistPrice(price24h: CoinHistPrices24(USD: 0)))), datagraph: GraphModel(data: GraphData(bitcoin: BitcoinGraph(timestamps: [], prices: []))), datatoken: TokenSearch(data: []), configuration: configuration)
        completion(entry)
    }

    func getTimeline(for configuration: CryptorankWidgetSettingsIntent,in context: Context, completion: @escaping (Timeline<CoinDataEntry>) -> ()) {
        WidgetCenter.shared.reloadAllTimelines()
        var entries: [CoinDataEntry] = []
        let currentDate = Date()
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 1, to: currentDate)!
        let apiKey = getSymbol(from: configuration)
        apiKeys = apiKey
        
        let url = URL(string: "https://api.**********/**/**/\(apiKey)?locale=en")!
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let data = data {
                
                guard let urlgraph = URL(string: "https://api.*******/**/charts/prices-by-coin?keys=\(apiKey)&days=7") else {
                    print("Invalid URL")
                    return
                }

             let taskgraph = URLSession.shared.dataTask(with: urlgraph) { (datagraph, responsegraph, errorgraph) in
                    if let datagraph = datagraph{
                        
                        guard let urltoken = URL(string: "https://api.******/**/coins?limit=10") else {
                            print("Invalid URL")
                            return
                        }
                        
                     let taskdata = URLSession.shared.dataTask(with: urltoken) { (datatoken, responsetoken, errortoken) in
                            
                            guard let datatoken = datatoken else {
                                print("Invalid data")
                                return
                            }
                                        
                            do {
                                let decodedDataToken = try JSONDecoder().decode(TokenSearch.self, from: datatoken)
                                
                                let decodedDatagraph = try JSONDecoder().decode(GraphModel.self, from: datagraph)
                    
                                let decodedData = try JSONDecoder().decode(CoinData.self, from: data)
                                
                                let entry = CoinDataEntry(date: currentDate, data: decodedData, datagraph: decodedDatagraph, datatoken: decodedDataToken, configuration: configuration)
                                
                                entries.append(entry)
                                
                                let timeline = Timeline(entries: entries, policy: .after(refreshDate))
                                
                                completion(timeline)
                            } catch {
                                let timeline = Timeline(entries: entries, policy: .after(refreshDate))
                                completion(timeline)
                            }
                        }
                        taskdata.resume()
                        
                        
                    } else {
                        print("Invalid data")
                        return
                    }
                    
                    if let error = error {
                        print("Error fetching Bitcoin data: \(error.localizedDescription)")
                        return
                    }
                    
                    //123
                }
                taskgraph.resume()
            } else {
                let timeline = Timeline(entries: entries, policy: .after(refreshDate))
                completion(timeline)
            }
        }
        task.resume()
    }
}

// MARK: - View Widget
struct BitcoinWidget: Widget {
    let kind: String = "BitcoinWidget"
    
    var body: some WidgetConfiguration {
        IntentConfiguration(
            kind: kind,
            intent: CryptorankWidgetSettingsIntent.self,
            provider: BitcoinDataProvider()
        )
        { entry in

            ZStack{
                ContainerRelativeShape().fill(Color("backgroundWidget"))
                VStack{
                    // index 1 - Price
                    // index 2 - procent
                    let isProcent = entry.configuration.isProcent
                    //MARK: NAME TOKEN
                               HStack{
                                   Text(entry.data.data.name)
                                       .foregroundColor(.white)
                                       .font(.custom("SFProText-Regular.ttf", size: 17))
                                   Spacer()
                               }
                               .padding(.leading,14)
                               .padding(.top,14)
                               //MARK: PRICE CHANGE AND SYMBOL
                               HStack{
                                   Text(entry.data.data.symbol)
                                       .foregroundColor(Color("usdtTextColor"))
                                       .font(.custom("SFProText-Regular.ttf", size: 14))
                                   
                                   Spacer()
                                   //price change
                                   if (isProcent.rawValue == 1){
                                       let currentpriced = entry.data.data.price.USD
                                       let price24hd = entry.data.data.histPrices.price24h.USD
                                       let dollar = currentpriced - price24hd
                                       
                                      
                                       if (dollar>0){
                                           Text("+$\(String(format: "%.2f", dollar))")
                                               .foregroundColor(Color.green)
                                               .font(.custom("SFProText-Light.ttf", size: 14))
                                       }
                                       else{
                                           Text("-$\(String(format: "%.2f", dollar * -1))")
                                               .foregroundColor(Color.red)
                                               .font(.custom("SFProText-Light.ttf", size: 14))
                                       }
                                   }
                                   if (isProcent.rawValue == 2){
                                       let currentpriced = entry.data.data.price.USD
                                       let price24hd = entry.data.data.histPrices.price24h.USD
                                       let procent = 100 - ((price24hd / currentpriced) * 100)
                                       
                                      
                                       if (procent>0){
                                           Text("+\(String(format: "%.2f", procent))%")
                                               .foregroundColor(Color.green)
                                               .font(.custom("SFProText-Light.ttf", size: 14))
                                       }
                                       else{
                                           Text("\(String(format: "%.2f", procent))%")
                                               .foregroundColor(Color.red)
                                               .font(.custom("SFProText-Light.ttf", size: 14))
                                       }
                                   }
                               }
                              .padding(.horizontal,14)
                               //Graph
                               HStack{
                                   if let url = URL(string: entry.data.data.image.x150), let imageData = try? Data(contentsOf: url),
                                      let image = UIImage(data: imageData) {
                                              Image(uiImage: image)
                                                  .resizable()
                                                  .aspectRatio(contentMode: .fit)
                                                  .frame(width: 43,height: 43)
                                          } else {
                                              Text("Image not found")
                                          }
                                   Spacer()
                                   //MARK: repositories graph View CryptorankWidgetio/Graph
                                   GraphView(coin: GraphModel(data: GraphData(bitcoin: BitcoinGraph(timestamps: [], prices: entry.datagraph.data.bitcoin.prices))))
                                       .frame(width: 89,height: 35)
                                    
                                   
                               }
                               .padding(.horizontal,14)
                               .padding(.bottom,5)
                               HStack{
                                   Text("$\(String(format: "%.2f", entry.data.data.price.USD))")
                                       .foregroundColor(.white)
                                       .font(.custom("SFProText-Regular.ttf", size: 20))
                                   Spacer()
                               }
                               .padding(.leading,14)
                               .padding(.bottom,10)

                           }
                       }

        }
        .configurationDisplayName("Cryptorank")
        .description("Просматривайте котировки и изменение цены в течении дня")
        .supportedFamilies([.systemSmall])
    }
}

struct widget_Previews: PreviewProvider {
    static var previews: some View {
        CoinEntryView(entry: BitcoinDataProvider.Entry(date: Date(), data: CoinData(data: Metadata(name: "Placeholder", symbol: "", key: "", price: CoinPrice(USD: 0), image: CoinImage(x150: ""), histPrices: CoinHistPrice(price24h: CoinHistPrices24(USD: 0)))), datagraph: GraphModel(data: GraphData(bitcoin: BitcoinGraph(timestamps: [], prices: []))), datatoken: TokenSearch(data: []), configuration: CryptorankWidgetSettingsIntent()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}


//MARK: widget preview
struct CoinEntryView : View {
    var entry: BitcoinDataProvider.Entry

    var body: some View {
        ZStack{
            
            VStack{
                //nameToken
                HStack{
                    Text(entry.data.data.name)
                        .foregroundColor(.white)
                        .font(.custom("SFProText-Regular.ttf", size: 17))
                    Spacer()
                }
                .padding(.leading,14)
                .padding(.top,14)
                
                HStack{
                    Text(entry.data.data.symbol)
                        .foregroundColor(Color("usdtTextColor"))
                        .font(.custom("SFProText-Regular.ttf", size: 14))
                    
                    Spacer()
                    Text("555")
                        .foregroundColor(Color("green"))
                        .font(.custom("SFProText-Light.ttf", size: 13))
                }
                .padding(.horizontal,14)
                //Graph
                HStack{
                    if let url = URL(string: entry.data.data.image.x150), let imageData = try? Data(contentsOf: url),
                       let image = UIImage(data: imageData) {
                               Image(uiImage: image)
                                   .resizable()
                                   .aspectRatio(contentMode: .fit)
                                   .frame(width: 43,height: 43)
                           } else {
                               Text("Image not found")
                           }
                    Spacer()
                    GraphView(coin: GraphModel(data: GraphData(bitcoin: BitcoinGraph(timestamps: [], prices: [
                       28023.96462891106,
                                                                                                                                                                                               28010.82177321632,
                                                                                                                                                                                               28212.665314092013,
                                                                                                                                                                                               28151.814890023143,
                                                                                                                                                                                               28243.70565313109,
                                                                                                                                                                                               28207.59080321623,
                                                                                                                                                                                               28238.56343500705,
                                                                                                                                                                                               28651.823086637385,
                                                                                                                                                                                               28534.251655863576,
                                                                                                                                                                                               28571.50176462446,
                                                                                                                                                                                               28524.56349904744,
                                                                                                                                                                                               28560.200864010196,
                                                                                                                                                                                               28510.796349488348,
                                                                                                                                                                                               28592.68953601978,
                                                                                                                                                                                               28389.36256467981,
                                                                                                                                                                                               28055.039338452058,
                                                                                                                                                                                               28025.336330736733,
                                                                                                                                                                                               28003.108537020857,
                                                                                                                                                                                               28228.212658733424,
                                                                                                                                                                                               28160.36844817287,
                                                                                                                                                                                               28180.95453592925,
                                                                                                                                                                                               28016.368812758355,
                                                                                                                                                                                               28064.56428831244,
                                                                                                                                                                                               28054.78060889805,
                                                                                                                                                                                               28076.04291721583,
                                                                                                                                                                                               27909.07447240444,
                                                                                                                                                                                               27859.102195443254,
                                                                                                                                                                                               27943.617354777416,
                                                                                                                                                                                               27979.676121829583,
                                                                                                                                                                                               28032.980105661132,
                                                                                                                                                                                               28129.60802554523,
                                                                                                                                                                                               28096.25631754918,
                                                                                                                                                                                               28057.73366485591,
                                                                                                                                                                                               28005.11215006774,
                                                                                                                                                                                               28052.035580384585,
                                                                                                                                                                                               28084.34373815923,
                                                                                                                                                                                               28010.81585533759,
                                                                                                                                                                                               28061.38762436323,
                                                                                                                                                                                               27966.16500687051,
                                                                                                                                                                                               27833.18172619142,
                                                                                                                                                                                               27856.2539784792,
                                                                                                                                                                                               27923.168112666583,
                                                                                                                                                                                               27931.68151386649,
                                                                                                                                                                                               27967.57183611891,
                                                                                                                                                                                               27929.14342326692,
                                                                                                                                                                                               27922.36122652712,
                                                                                                                                                                                               27891.575551987356,
                                                                                                                                                                                               27903.627696687723,
                                                                                                                                                                                               27946.94000588841,
                                                                                                                                                                                               27892.2918124029,
                                                                                                                                                                                               27912.080554709883,
                                                                                                                                                                                               28027.937953787,
                                                                                                                                                                                               28046.653568764938,
                                                                                                                                                                                               28108.195561695426,
                                                                                                                                                                                               28035.81635787371,
                                                                                                                                                                                               28013.48504311581,
                                                                                                                                                                                               28015.22762292301,
                                                                                                                                                                                               28032.22343006102,
                                                                                                                                                                                               28017.207098139155,
                                                                                                                                                                                               28001.894726591538,
                                                                                                                                                                                               27928.988541717757,
                                                                                                                                                                                               27939.0166193794,
                                                                                                                                                                                               27925.324046387195,
                                                                                                                                                                                               27989.591825987485,
                                                                                                                                                                                               28096.585140232422,
                                                                                                                                                                                               28067.73519269657,
                                                                                                                                                                                               28082.427491255738,
                                                                                                                                                                                               27905.719969917405,
                                                                                                                                                                                               27912.790621698943,
                                                                                                                                                                                               27941.721346433165,
                                                                                                                                                                                               27966.68138351557,
                                                                                                                                                                                               27942.271228217225,
                                                                                                                                                                                               27911.64480574096,
                                                                                                                                                                                               27931.52094460958,
                                                                                                                                                                                               27972.840417076502,
                                                                                                                                                                                               28135.28737445635,
                                                                                                                                                                                               28522.368447202138,
                                                                                                                                                                                               28344.834644890827,
                                                                                                                                                                                               28321.214719544587,
                                                                                                                                                                                               28308.88513422616,
                                                                                                                                                                                               28317.992586744975,
                                                                                                                                                                                               28284.195089754765,
                                                                                                                                                                                               28304.10965311375,
                                                                                                                                                                                               28325.057960184506,
                                                                                                                                                                                               28344.12793190219,
                                                                                                                                                                                               28284.47814734971,
                                                                                                                                                                                               28327.46636823819,
                                                                                                                                                                                               28515.3683091775,
                                                                                                                                                                                               29169.90917839179,
                                                                                                                                                                                               29180.830108167094,
                                                                                                                                                                                               29243.480429333405,
                                                                                                                                                                                               29710.278116427424,
                                                                                                                                                                                               29852.61932620119,
                                                                                                                                                                                               30203.05940455709,
                                                                                                                                                                                               30116.530240360036,
                                                                                                                                                                                               29945.57213988896,
                                                                                                                                                                                               30088.21274743049,
                                                                                                                                                                                               30042.075695794556,
                                                                                                                                                                                               30126.08578645722,
                                                                                                                                                                                               30130.214366063923,
                                                                                                                  ]))))
                     
                    
                }
                .padding(.horizontal,14)
                HStack{
                    Text("$\(String(format: "%.2f", entry.data.data.price.USD))")
                        .foregroundColor(.white)
                        .font(.custom("SFProText-Regular.ttf", size: 20))
                    Spacer()
                }
                
                .padding(.leading,14)
                .padding(.bottom,10)
                Spacer()
            }
        }
        .background(Color("backgroundWidget"))
    }
}

struct GraphModel: Codable {
    let data: GraphData
}

// graphic
struct GraphData: Codable {
    let bitcoin: BitcoinGraph
    
    enum CodingKeys : String, CodingKey {
        case bitcoin
        
        init(from decoder: Decoder, configuration: CryptorankWidgetSettingsIntent) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let apiKey = container.allKeys.first(where: { $0.stringValue != "bitcoin" })?.stringValue ?? "bitcoin"
            self = CodingKeys(rawValue: apiKey)!
        }

        var stringValue: String {
            switch self {
            case .bitcoin:
                return apiKeys
            }
        }
    }
}

struct BitcoinGraph: Codable {
    let timestamps: [Double]
    let prices: [Double]
}

struct GraphView: View {
    let data: [Double]
    let maxY: Double
    let minY: Double
    let yfirst: Double
    let ylast: Double
    var ColorGraph = ""
    

    init(coin: GraphModel){
        data = coin.data.bitcoin.prices ?? []
        maxY = data.max() ?? 0
        minY = data.min() ?? 0
        yfirst = data.first ?? 0
        ylast = data.last ?? 0
        print(data)
        if yfirst > ylast{
                      ColorGraph = "red"
                  }
                  else{
                      ColorGraph = "green"
                  }
    }
    
    var body: some View {

        VStack{
                
            CurveChart(data: data)
                .stroke(Color(ColorGraph), style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)) // line
                      .background(
                          CurveChart(data: data, isBackground: true)
                            .fill(.linearGradient(colors: [Color(ColorGraph).opacity(0.4), .clear], startPoint: .top, endPoint: .bottom)) // background fill
                          )


        }
//        .frame(width: 89,height: 43)
    }
}

struct CurveChart: Shape { // chnaged var to a Shape struct
    
    let data: [Double]
    var isBackground: Bool = false
    
    func path(in rect: CGRect) -> Path {
        Path { path in
            for index in data.indices {
                let xPosition: CGFloat = rect.width / CGFloat(data.count-1) * CGFloat(index)
                
                let maxY = data.max() ?? 0
                let minY = data.min() ?? 0
                
                let yAxis: CGFloat = maxY - minY
                
                let yPosition: CGFloat = (1 - CGFloat((Double(data[index]) - minY) / yAxis)) * rect.height
                
                if isBackground{
                    if index == 0{
                        path.move(to: CGPoint(x: 0, y: rect.height))
                    }
                    path.addLine(to: CGPoint(x: xPosition, y: yPosition))
                }
                else{
                    if index == 0{
                        path.move(to: CGPoint(x: xPosition, y: yPosition))
                    }
                    path.addLine(to: CGPoint(x: xPosition, y: yPosition))
                }
            }
            if isBackground { // this is needed so the backkground shape is filled correctly (closing the shape)
                path.addLine(to: CGPoint(x: rect.width, y: rect.height))
            }
        }

    }
}

struct plotPoint: Shape { // chnaged var to a Shape struct
    
    let data: [Double]
    let index: Int
    let size = 20.0
    
    func path(in rect: CGRect) -> Path {
        
        let xStep = rect.width / Double(data.count-1)
        let yStep = rect.height / (data.max() ?? 0)
        
        let xCenter = Double(index) * xStep
        let yCenter = rect.height - yStep * data[index]
        
        var path = Path()
        path.addEllipse(in: CGRect(x: xCenter - size/2, y: yCenter - size/2, width: size, height: size))
        
        return path
    }
}
