//
//  SwiftUIView.swift
//  Cryptorankio
//
//  Created by Danila Kardashevkii on 17.04.2023.
//

import SwiftUI

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

struct SwiftUIView: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUIView()
    }
}
