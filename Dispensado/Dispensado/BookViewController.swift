//
//  BookViewController.swift
//  Dispensado
//
//  Created by Joao Flores on 01/12/19.
//  Copyright © 2019 Joao Flores. All rights reserved.
//

import UIKit
import os.log
import StoreKit

class BookViewController: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    //MARK: Properties
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    //    novos texts
    @IBOutlet weak var missTextField: UILabel!
    @IBOutlet weak var lessonsTextField: UITextField!
    
    @IBOutlet weak var obsTextView: UITextView!
    
    @IBOutlet weak var missesState: UIView!
    
    var currentMiss = 0
    var maxMiss = 0
    
    var book: BookClass?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        
        obsTextView.layer.cornerRadius = 10
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: Selector(("dismissKeyboardFunc")))
        
        
        view.addGestureRecognizer(tap)
        
        obsTextView.delegate = self as? UITextViewDelegate
        nameTextField.delegate = self
        
        if let meal = book {
            navigationItem.title = meal.name
            nameTextField.text = meal.name
            photoImageView.image = meal.photo
            
            missTextField.text = "\(meal.currentMiss) / \(meal.maxMiss)"
            
            currentMiss = meal.currentMiss
            maxMiss = meal.maxMiss
            
            lessonsTextField.text = String(meal.lessons)
            obsTextView.text = meal.observations
            missesState.alpha = 1
        } else {
            missesState.alpha = 0
        }
        
        updateSaveButtonState()
    }
    
    //MARK: UITextFieldDelegate
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
        saveButton.isEnabled = false
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        updateSaveButtonState()
        navigationItem.title = textField.text
    }
    
    //MARK: UIImagePickerControllerDelegate
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
//    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
//
//        guard let selectedImage = info[UIImagePickerControllerOriginalImage] as? UIImage else {
//            fatalError("Expected a dictionary containing an image, but was provided the following: \(info)")
//        }
//
//        photoImageView.image = selectedImage
//
//        dismiss(animated: true, completion: nil)
//    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        var image : UIImage!
        
        if let img = info[UIImagePickerController.InfoKey.editedImage] as? UIImage
        {   image = img    }
        else if let img = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        {   image = img    }
        
        photoImageView.image = image
        
        dismiss(animated: true, completion: nil)
    }
    
    //MARK: Navigation
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        let isPresentingInAddMealMode = presentingViewController is UINavigationController
        
        if isPresentingInAddMealMode {
            dismiss(animated: true, completion: nil)
        }
        else if let owningNavigationController = navigationController{
            owningNavigationController.popViewController(animated: true)
        }
        else {
            fatalError("The MealViewController is not inside a navigation controller.")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        guard let button = sender as? UIBarButtonItem, button === saveButton else {
            os_log("The save button was not pressed, cancelling", log: OSLog.default, type: .debug)
            return
        }
        
        let name = nameTextField.text ?? ""
        let photo = photoImageView.image
        let lessons = Int(lessonsTextField.text ?? "0")
        let observations = obsTextView.text ?? ""
        maxMiss = Int(Double(lessons ?? 0) * 4.5)
        
        book = BookClass(name: name, photo: photo, currentMiss: currentMiss, maxMiss: maxMiss, lessons: lessons ?? 0, observations: observations)
    }
    
    //MARK: Actions
    @IBAction func selectImageFromPhotoLibrary(_ sender: UITapGestureRecognizer) {
        
//        nameTextField.resignFirstResponder()
//
//        let imagePickerController = UIImagePickerController()
//
//        imagePickerController.sourceType = .photoLibrary
//
//        imagePickerController.delegate = self
//        present(imagePickerController, animated: true, completion: nil)
        
        let imagePicker =  UIImagePickerController()
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func subMiss(_ sender: Any) {
        if(currentMiss > 0) {
            currentMiss = currentMiss - 1
            missTextField.text = "\(currentMiss) / \(maxMiss)"
        }
    }
    
    @IBAction func addMiss(_ sender: Any) {
        currentMiss = currentMiss + 1
        missTextField.text = "\(currentMiss) / \(maxMiss)"
    }
    //MARK: Private Methods
    
    private func updateSaveButtonState() {
        let text = nameTextField.text ?? ""
        saveButton.isEnabled = !text.isEmpty
    }
    
    @objc func dismissKeyboardFunc() {
        maxMiss = Int(Double(Int(lessonsTextField.text ?? "0") ?? 0) * 4.5)
        
        if book != nil {
            missTextField.text = "\(currentMiss) / \(maxMiss)"
        }
        
        view.endEditing(true)
    }
}

