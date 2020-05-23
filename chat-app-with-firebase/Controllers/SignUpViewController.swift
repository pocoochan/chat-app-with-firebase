//
//  SignUpViewController.swift
//  chat-app-with-firebase
//
//  Created by saya on 2020/05/19.
//  Copyright © 2020 saya. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseStorage

class SignUpViewController: UIViewController {
    @IBOutlet weak var profileImageButton: UIButton!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var userNameTextField: UITextField!
    @IBOutlet weak var resisterButton: UIButton!
    @IBOutlet weak var alredyHaveAccountButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailTextField.delegate = self
        passwordTextField.delegate = self
        userNameTextField.delegate = self
        
        profileImageButton.layer.cornerRadius = 85
        profileImageButton.layer.borderWidth = 1
        profileImageButton.layer.borderColor = UIColor.rgb(red: 240, green: 240, blue: 240).cgColor
        
        resisterButton.layer.cornerRadius = 12
   
        profileImageButton.addTarget(self, action: #selector(tappedProfileImageButton), for: .touchUpInside)
             resisterButton.addTarget(self, action: #selector(tappedResisterButton), for: .touchUpInside)
        
        resisterButton.isEnabled = false
        resisterButton.backgroundColor = .rgb(red: 100, green: 100, blue: 100)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    @objc private func tappedProfileImageButton() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = true
        
        self.present(imagePickerController, animated: true, completion: nil)
    }
    
    @objc func tappedResisterButton() {
        guard let image = profileImageButton.imageView?.image else { return }
        guard let uploadImage = image.jpegData(compressionQuality: 0.3) else { return }
        
        let fileName = NSUUID().uuidString
        let storageRef = Storage.storage().reference().child("profile_image").child(fileName)
        
        storageRef.putData(uploadImage, metadata: nil) { (metadata, err) in
            if let err = err {
                print("Firestoreへの情報の保存に失敗しました。\(err)")
                return
            } else {
                print("Firestoreへの情報の保存に成功しました。")
                storageRef.downloadURL { (url, err) in
                    if let err = err {
                        print("Firestorageからの取得に失敗しました。\(err)")
                        return
                    }
                    
                    guard let urlString = url?.absoluteString else { return }
                    print("urlString: ", urlString)
                    self.createUserToFirestore(prifileImageUrl: urlString)
                }
            }
        }
        

    }
    
    private func createUserToFirestore(prifileImageUrl: String) {
        guard let email = emailTextField.text else { return }
        guard let password = passwordTextField.text else { return }
        
        Auth.auth().createUser(withEmail: email, password: password) { (res, err) in
            if let err = err {
                print("認証情報の保存に失敗しました。\(err)")
                return
            } else {
                print("認証情報の保存に成功しました。")
            }
            
            guard let uid = res?.user.uid else { return }
            guard let username = self.userNameTextField.text else { return }
            let docData = [
                "email": email,
                "username": username,
                "createdAt": Timestamp(),
                "prifileImageUrl": prifileImageUrl
                ] as [String: Any]
            
            Firestore.firestore().collection("users").document(uid).setData(docData) {
                (err) in
                if let err = err {
                    print("Firestoreへの情報の保存に失敗しました。\(err)")
                    return
                }
                
                print("Firestoreへの情報の保存が成功しました。")
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    
}

extension SignUpViewController: UITextFieldDelegate{
    func textFieldDidChangeSelection(_ textField: UITextField) {
        
        let emailIsEmpty = emailTextField.text?.isEmpty ?? false
        let passwardIsEmpty = passwordTextField.text?.isEmpty ?? false
        let usernameIsEmpty = userNameTextField.text?.isEmpty ?? false
        
        if emailIsEmpty || passwardIsEmpty || usernameIsEmpty {
            resisterButton.isEnabled = false
            resisterButton.backgroundColor = .rgb(red: 100, green: 100, blue: 100)
        } else {
            resisterButton.isEnabled = true
            resisterButton.backgroundColor = .rgb(red: 0, green: 185, blue: 0)
        }
    }

}

extension SignUpViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let editImage = info[.editedImage] as? UIImage {
            profileImageButton.setImage(editImage.withRenderingMode(.alwaysOriginal), for: .normal)
        } else if let originalImage = info[.originalImage] as? UIImage {
            profileImageButton.setImage(originalImage.withRenderingMode(.alwaysOriginal), for: .normal)
        }
        
        profileImageButton.imageView?.contentMode = .scaleAspectFill
        profileImageButton.clipsToBounds = true
        
        dismiss(animated: true, completion: nil)
    }
    
}
