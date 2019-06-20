//
//  ViewController.swift
//  CombineExamples
//
//  Created by Pawel Krawiec on 17/06/2019.
//  Copyright © 2019 tailec. All rights reserved.
//

import UIKit
import Combine

class LoginViewController: UIViewController {
    @IBOutlet weak private var usernameTextField: UITextField!
    @IBOutlet weak private var passwordTextField: UITextField!
    @IBOutlet weak private var loginButton: UIButton!
    @IBOutlet weak private var activityIndicator: UIActivityIndicatorView!
    
    private let executing = CurrentValueSubject<Bool, Never>(false)
    private var cancellableBag = CancellableBag()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let credentials = Publishers.CombineLatest($username, $password) { ($0, $1) }
            .share()
        
        credentials
            .map { uname, pass in
                return uname.count >= 4 && pass.count >= 4
            }
            .prepend(false) // initial state
            .assign(to: \.isEnabled, on: loginButton)
            .cancelled(by: cancellableBag)
        
        loginTaps
            .flatMap { _ in
                return Publishers.Just((self.username, self.password))
            }
            .handleEvents(receiveOutput: { [weak self] _ in
                guard let strongSelf = self else { return }
                strongSelf.executing.send(true)
            })
            .map { uname, pass in
                URLSession.shared.get(url: URL(string: "https://postman-echo.com/basic-auth")!,
                                      params: ["username": uname,
                                               "password": pass,
                                               "Authorization": "Basic cG9zdG1hbjpwYXNzd29yZA=="])
                    .retry(3)
                    .decode(type: AuthResponse.self, decoder: JSONDecoder())
                    .map { $0.authenticated }
                    .replaceError(with: false)
            }
            .switchToLatest()
            .handleEvents(receiveOutput: { [weak self] _ in
                guard let strongSelf = self else { return }
                strongSelf.executing.send(false)
            })
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
            .sink(receiveValue: { [weak self] result in
                guard let strongSelf = self else { return }
                let alert = UIAlertController(title: result ? "Success!" : "Failure!", message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                strongSelf.present(alert, animated: true)
                
            })
            .cancelled(by: cancellableBag)
        
        executing
            .map(!)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
            .assign(to: \.isHidden, on: activityIndicator)
            .cancelled(by: cancellableBag)
    }

    @Published private var username: String = ""
    @IBAction func usernameDidChange(_ sender: UITextField) {
        username = sender.text ?? ""
    }
    
    @Published private var password: String = ""
    @IBAction func passwordDidChange(_ sender: UITextField) {
        password = sender.text ?? ""
    }
    
    private let loginTaps = PassthroughSubject<Void, Never>()
    @IBAction func loginDidTap(_ sender: UIButton) {
        loginTaps.send()
    }
}

private struct AuthResponse: Decodable {
    let authenticated: Bool
}
