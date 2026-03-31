//
//  CallablePayloadDecoder.swift
//  Altos del Murco
//
//  Created by José Ruiz on 13/3/26.
//

import Foundation

enum CallablePayloadDecoder {
    static func decode<T: Decodable>(_ type: T.Type, from data: Any) throws -> T {
        guard JSONSerialization.isValidJSONObject(data) else {
            throw NSError(
                domain: "CallablePayloadDecoder",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid callable payload"]
            )
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: data)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: jsonData)
    }
}
