//
//  SearchViewController.swift
//  CombineExamples
//
//  Created by Pawel Krawiec on 19/06/2019.
//  Copyright © 2019 tailec. All rights reserved.
//

import UIKit
import Combine

class SearchViewController: UIViewController {
    @IBOutlet weak var queryTextField: UITextField!
    @IBOutlet weak var tableView: UITableView! {
        didSet { tableView.dataSource = self }
    }
    
    private var repos = [Repo]()
    private let cancellableBag = CancellableBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        $query
            .throttle(for: 0.5, scheduler: DispatchQueue.main, latest: true)
            .removeDuplicates()
            .map { query -> AnyPublisher<[Repo], Never> in
                guard query.count >= 3 else {
                    return Publishers.Just([])
                        .eraseToAnyPublisher()
                }
                return API().search(with: query)
                    .retry(3)
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .replaceError(with: [])
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
            .sink { [weak self] repos in
                guard let strongSelf = self else { return }
                strongSelf.repos = repos
                strongSelf.tableView.reloadData()
            }
            .cancelled(by: cancellableBag)
    }
    
    @Published private var query: String = ""
    @IBAction func queryDidChange(_ sender: UITextField) {
        query = sender.text ?? ""
    }
}

extension SearchViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return repos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell =  tableView.dequeueReusableCell(withIdentifier: "cell") else {
            return UITableViewCell(style: .default, reuseIdentifier: "cell")
        }
        cell.textLabel?.text = repos[indexPath.row].name
        return cell
    }    
}

fileprivate class API {
    func search(with query: String) -> AnyPublisher<[Repo], Never> {
        URLSession.shared.dataTaskPublisher(for: URLRequest(url: URL(string: "https://api.github.com/search/repositories?q=\(query)")!))
            .map { $0.data }
            .decode(type: SearchResponse.self, decoder: JSONDecoder())
            .map { $0.items }
            .replaceError(with: [])
            .eraseToAnyPublisher()
    }
}

fileprivate struct SearchResponse: Decodable {
    let items: [Repo]
}

fileprivate struct Repo: Decodable, Hashable {
    let name: String
}
