//
//  MainViewController.swift
//  CombineExamples
//
//  Created by Pawel Krawiec on 19/06/2019.
//  Copyright © 2019 tailec. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {
    private let rows = ["Login example", "Search example", "Timer example", "Username example"]
    
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.dataSource = self
            tableView.delegate = self
        }
    }
}

extension MainViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
        }
        cell!.textLabel?.text = rows[indexPath.row]
        return cell!
    }
}

extension MainViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            show(loginViewController, sender: nil)
        case 1:
            show(searchViewController, sender: nil)
        case 2:
            show(timerViewController, sender: nil)
        case 3:
            show(usernameViewController, sender: nil)
        default:
            return
        }
    }
}

struct Row {
    let name: String
}


var loginViewController: LoginViewController {
    guard let loginViewController = UIStoryboard(name: "Login", bundle: nil).instantiateInitialViewController() as? LoginViewController else { fatalError()}
    return loginViewController
}

var searchViewController: SearchViewController {
    guard let searchViewController = UIStoryboard(name: "Search", bundle: nil).instantiateInitialViewController() as? SearchViewController else { fatalError()}
    return searchViewController
}

var timerViewController: TimerViewController {
    guard let timerViewController = UIStoryboard(name: "Timer", bundle: nil).instantiateInitialViewController() as? TimerViewController else { fatalError()}
    return timerViewController
}

var usernameViewController: UsernameViewController {
    guard let usernameViewController = UIStoryboard(name: "Username", bundle: nil).instantiateInitialViewController() as? UsernameViewController else { fatalError()}
    return usernameViewController
}
