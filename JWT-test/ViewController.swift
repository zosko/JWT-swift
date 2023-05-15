//
//  ViewController.swift
//  JWT-test
//
//  Created by Bosko Petreski on 26.4.23.
//

import UIKit
import CryptoKit

extension Data {
    func urlSafeBase64EncodedString() -> String {
        return base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

extension String {
    func urlSafeBase64Decoded() -> Data? {
        var st = self
            .replacingOccurrences(of: "_", with: "/")
            .replacingOccurrences(of: "-", with: "+")
        let remainder = self.count % 4
        if remainder > 0 {
            st = st.padding(toLength: self.count + 4 - remainder,
                            withPad: "=",
                            startingAt: 0)
        }
        guard let d = Data(base64Encoded: st, options: .ignoreUnknownCharacters) else{
            return nil
        }
        return d
    }
}

struct AccessKey {
    static let developer_id = "GET_FROM_DOOR_DASH"
    static let key_id = "GET_FROM_DOOR_DASH"
    static let signing_secret = "GET_FROM_DOOR_DASH"
}

struct Header: Encodable {
    let alg = "HS256"
    let typ = "JWT"
    let ddVer = "DD-JWT-V1"
    
    private enum CodingKeys: String, CodingKey {
        case alg
        case typ
        case ddVer = "dd-ver"
    }
}

struct Payload: Encodable {
    let aud = "doordash"
    let iss = AccessKey.developer_id
    let kid = AccessKey.key_id
    let exp = Int(Date.now.timeIntervalSince1970 + 60)
    let iat = Int(Date.now.timeIntervalSince1970)
}

struct Params: Codable {
    let external_delivery_id: String
    let pickup_address: String
    let pickup_business_name: String
    let pickup_phone_number: String
    let pickup_instructions: String
    let dropoff_address: String
    let dropoff_business_name: String
    let dropoff_phone_number: String
    let dropoff_instructions: String
    let order_value: Int
}

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let secret = AccessKey.signing_secret.urlSafeBase64Decoded() else { return }
        let privateKey = SymmetricKey(data: secret)
        
        let headerJSONData = try! JSONEncoder().encode(Header())
        let headerBase64String = headerJSONData.urlSafeBase64EncodedString()
        
        let payloadJSONData = try! JSONEncoder().encode(Payload())
        let payloadBase64String = payloadJSONData.urlSafeBase64EncodedString()
        
        let toSign = Data((headerBase64String + "." + payloadBase64String).utf8)
        
        let signature = HMAC<SHA256>.authenticationCode(for: toSign, using: privateKey)
        let signatureBase64String = Data(signature).urlSafeBase64EncodedString()
        
        let token = [headerBase64String, payloadBase64String, signatureBase64String].joined(separator: ".")
        print(token)
        
        let url = URL(string: "https://openapi.doordash.com/drive/v2/deliveries/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer " + token, forHTTPHeaderField: "Authorization")
        
        let params = Params(external_delivery_id: "D-12341",
                            pickup_address: "901 Market Street 6th Floor San Francisco, CA 94103",
                            pickup_business_name: "Wells Fargo SF Downtown",
                            pickup_phone_number: "+16505555555",
                            pickup_instructions: "Enter gate code 1234 on the callbox.",
                            dropoff_address: "901 Market Street 6th Floor San Francisco, CA 94103",
                            dropoff_business_name: "Wells Fargo SF Downtown",
                            dropoff_phone_number: "+16505555555",
                            dropoff_instructions: "Enter gate code 1234 on the callbox.",
                            order_value: 1999)
        
        request.httpBody = try! JSONEncoder().encode(params)
        
        let dataTask = URLSession.shared.dataTask(with: request) { data,response,error in
            guard let data = data else {
                print("ERROR NO DATA")
                return
            }
            print(String(data: data, encoding: .utf8))
        }
        dataTask.resume()
    }
    
    
}

