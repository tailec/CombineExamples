//
//  URLSession+Combine.swift
//  CombineExamples
//
//  Created by Pawel Krawiec on 18/06/2019.
//  Copyright © 2019 tailec. All rights reserved.
//

import Foundation
import Combine

extension URLSession {
    func get(url: URL, params: [String: Any]) -> AnyPublisher<Data, URLError> {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        for param in params {
            request.setValue(param.key, forHTTPHeaderField: param.value as! String)
        }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .map { $0.data }
            .eraseToAnyPublisher()
    }
}
