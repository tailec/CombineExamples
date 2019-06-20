//
//  UsernameViewController.swift
//  CombineExamples
//
//  Created by Pawel Krawiec on 20/06/2019.
//  Copyright © 2019 tailec. All rights reserved.
//

import UIKit
import Combine

class UsernameViewController: UIViewController {
    @IBOutlet weak var label: UILabel!
    private let cancellableBag = CancellableBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        $text
            .throttle(for: 0.5, scheduler: DispatchQueue.main, latest: true)
            .map { text -> AnyPublisher<String, Never> in
                guard !text.isEmpty else {
                    return Publishers.Just("Field can't be empty")
                        .eraseToAnyPublisher()
                }
                return API().search(with: text)
                    .map { isAvailable in
                        isAvailable ? "Name available" : "Name already taken"
                    }
                    .prepend("Checking...")
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .prepend("Start typing...") // initial state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                guard let strongSelf = self else { return }
                strongSelf.label.text = message
            }
            .cancelled(by: cancellableBag)
    }
    
    @Published private var text: String = ""
    @IBAction func textFieldDidChange(_ sender: UITextField) {
        text = sender.text ?? ""
    }
}

fileprivate class API {
    func search(with query: String) -> AnyPublisher<Bool, Never> {
        URLSession.shared.dataTaskPublisher(for: URLRequest(url: URL(string: "https://api.github.com/search/repositories?q=\(query)")!))
            .map { $0.data }
            .decode(type: SearchResponse.self, decoder: JSONDecoder())
            .map { $0.totalCount == 0 }
            .replaceError(with: false)
            .eraseToAnyPublisher()
    }
}

fileprivate struct SearchResponse: Decodable {
    let totalCount: Int
}

