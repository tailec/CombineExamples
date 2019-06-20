//
//  TimerViewController.swift
//  CombineExamples
//
//  Created by Pawel Krawiec on 19/06/2019.
//  Copyright © 2019 tailec. All rights reserved.
//

import UIKit
import Combine

class TimerViewController: UIViewController {
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var tableView: UITableView! {
        didSet { tableView.dataSource = self }
    }
    
    @Published private var currentTime: String = ""
    private var laps = [String]()
    private let cancellableBag = CancellableBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Timer.publish(every: 0.1, on: .main, in: .default)
            .autoconnect()
            .scan(0, { (acc, _ ) in return acc + 1 })
            .map { $0.timeInterval }
            .replaceError(with: "")
            .eraseToAnyPublisher()
            .assign(to: \.currentTime, on: self)
            .cancelled(by: cancellableBag)
        
        $currentTime
            .sink { value in
                self.timerLabel.text = value
            }
            .cancelled(by: cancellableBag)
        
       splitButtonTaps
            .map { [weak self] _ -> AnyPublisher<String, Never> in
                guard let strongSelf = self else {
                    return Publishers.Empty().eraseToAnyPublisher()
                }
                return Publishers.Just(strongSelf.currentTime)
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .scan([String]()) { (acc, new) -> [String] in
                return acc + [new]
            }
            .eraseToAnyPublisher()
            .sink { [weak self] laps in
                guard let strongSelf = self else { return }
                strongSelf.laps = laps
                strongSelf.tableView.reloadData()
            }
            .cancelled(by: cancellableBag)
    }
    
    private let splitButtonTaps = PassthroughSubject<Void, Never>()
    @IBAction func splitButtonDidTap(_ sender: UIButton) {
        splitButtonTaps.send()
    }
}

extension TimerViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return laps.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell =  tableView.dequeueReusableCell(withIdentifier: "cell") else {
            return UITableViewCell(style: .default, reuseIdentifier: "cell")
        }
        cell.textLabel?.text = laps[indexPath.row]
        return cell
    }
}

fileprivate extension Int {
    var timeInterval: String {
        String(format: "%0.2d:%0.2d.%0.1d",
               arguments: [(self / 600) % 600, (self % 600 ) / 10, self % 10])
    }
}
