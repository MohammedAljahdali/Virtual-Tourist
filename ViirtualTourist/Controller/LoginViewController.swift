//
//  LoginViewController.swift
//  
//
//  Created by Mohammed Khakidaljahdali on 17/12/2019.
//

import UIKit
import Firebase
import FirebaseUI

class LoginViewController: UIViewController {

    
        
    var authUI: FUIAuth!
    var user: User!
    var db: Firestore!
    fileprivate var _authHandle: AuthStateDidChangeListenerHandle!
    
    
    @IBAction func enterTheAppTapped(_ sender: Any) {
        if user == nil {
            let alertVC = UIAlertController(title: "Enter Failed", message: "Please Login", preferredStyle: .alert)
            alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alertVC, animated: true, completion: nil)
            return
        } else {
           performSegue(withIdentifier: "mapViewSegue", sender: nil)
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupAuth()
        authUser()
        setupButtons()
        db = Firestore.firestore()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setupButtons()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination as! MapViewController
        vc.user = user
        vc.authUI = authUI
        vc.db = db
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension LoginViewController: FUIAuthDelegate {
    
    func setupAuth() {
        authUI = FUIAuth.defaultAuthUI()
        authUI!.delegate = self
        let providers: [FUIAuthProvider] = [
          FUIGoogleAuth(),
//          FUIFacebookAuth(),
//          FUITwitterAuth(),
//          FUIPhoneAuth(authUI:FUIAuth.defaultAuthUI()),
        ]
        authUI.providers = providers
    }
    
    func authUser() {
        _authHandle = Auth.auth().addStateDidChangeListener({ (auth, user) in
            if let activeUser = user {
                if self.user != activeUser {
                    self.user = activeUser
                    self.db.collection("users").document("\(activeUser.email!)").setData(["name":activeUser.displayName!])
                    
                }
            } else {
                self.presentLogin()
            }
        })
    }
    func presentLogin() {
        let authViewController = authUI.authViewController()
        present(authViewController, animated: true, completion: nil)
    }
    
    func setupButtons() {
        navigationItem.title = "Virtual Tourist"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Login", style: .plain, target: self, action: #selector(login))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(logout))
//        if user == nil {
//            navigationItem.leftBarButtonItem?.isEnabled = false
//            navigationItem.rightBarButtonItem?.isEnabled = true
//        } else {
//            navigationItem.leftBarButtonItem?.isEnabled = true
//            navigationItem.rightBarButtonItem?.isEnabled = false
//        }
    }
    
    
    @objc func login() {
        if user == nil {
            presentLogin()
        } else {
            let alertVC = UIAlertController(title: "Login Failed", message: "You are Already Logged In", preferredStyle: .alert)
            alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alertVC, animated: true, completion: nil)
        }
    }
    
    @objc func logout() {
        if user == nil {
            let alertVC = UIAlertController(title: "Logout Failed", message: "You are Already Logged Out", preferredStyle: .alert)
            alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alertVC, animated: true, completion: nil)
        } else {
            do {
                try authUI.signOut()
                user = nil
            } catch {
                let alertVC = UIAlertController(title: "Logout Failed", message: "Sorry Logout failled: \(error.localizedDescription)", preferredStyle: .alert)
                alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alertVC, animated: true, completion: nil)
            }
        }
    }
    
    func authUI(_ authUI: FUIAuth, didSignInWith user: User?, error: Error?) {
        guard error != nil else {return}
//        if let user = user {
          // The user's ID, unique to the Firebase project.
          // Do NOT use this value to authenticate with your backend server,
          // if you have one. Use getTokenWithCompletion:completion: instead.
            // TODO: make this the unique user id in firestoe
//          let uid = user.uid
//          let email = user.email
//          let photoURL = user.photoURL
          // ...
//        }
    }
    
}

