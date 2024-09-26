//
//  BookViewController.swift
//  Dispensado
//
//  Created by Joao Flores on 01/12/19.
//  Copyright © 2019 Joao Flores. All rights reserved.
//

import AVFoundation
import Photos
import UIKit
import os.log
import GoogleMobileAds
import SnapKit
import PhotosUI
import Lightbox

extension BookViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true, completion: nil)
        
        for result in results {
            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (image, error) in
                guard let self = self, let selectedImage = image as? UIImage else { return }
                
                if let imagePath = self.saveImage(selectedImage) {
                    DispatchQueue.main.async {
                        self.book?.imagePaths.append(imagePath) // Add the image path to the book object
                        self.collectionView.reloadData()
                    }
                }
            }
        }
    }
    
    private func openCameraWithPermission() {
        checkCameraPermission { granted in
            DispatchQueue.main.async {
                if granted {
                    self.takeMultiplePhotos()
                } else {
                    self.showPermissionDeniedAlert(for: "Câmera")
                }
            }
        }
    }

    private func takeMultiplePhotos() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let imagePickerController = UIImagePickerController()
            imagePickerController.sourceType = .camera
            imagePickerController.delegate = self
            self.present(imagePickerController, animated: true, completion: nil)
        }
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let selectedImage = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
            if let imagePath = saveImage(selectedImage) {
                book?.imagePaths.append(imagePath)
                collectionView.reloadData()
            }
        }
        dismiss(animated: true) {
            let alertController = UIAlertController(title: "Tirar outra foto?", message: nil, preferredStyle: .alert)
            
            let takePhotoAction = UIAlertAction(title: "Sim", style: .default) { _ in
                self.takeMultiplePhotos()
            }
            let finishAction = UIAlertAction(title: "Finalizar", style: .cancel, handler: nil)
            alertController.addAction(takePhotoAction)
            alertController.addAction(finishAction)
            
            self.present(alertController, animated: true, completion: nil)
        }
    }
}

extension BookViewController: UICollectionViewDelegate, UICollectionViewDataSource, CustomCollectionViewCellDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (book?.imagePaths.count ?? 0) + 1 // +1 for the add icon
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CustomCollectionViewCell", for: indexPath) as! CustomCollectionViewCell
        
        cell.delegate = self
        cell.indexPath = indexPath

        if indexPath.item == 0 {
            cell.imageView.image = UIImage(systemName: "photo.badge.plus")
            cell.imageView.tintColor = .systemBlue
            cell.imageView.contentMode = .scaleAspectFit
        } else {
            if let imagePath = book?.imagePaths[indexPath.item - 1], let image = loadImage(from: imagePath) {
                cell.imageView.image = image
                cell.imageView.contentMode = .scaleAspectFill
            } else {
                cell.imageView.image = UIImage(named: "premiumIcon")
                cell.imageView.contentMode = .scaleAspectFit
            }
        }
        
        return cell
    }
    
    func showImageAdditionInfoAlert() {
        let alertController = UIAlertController(
            title: "Salve a nova matéria",
            message: "Você poderá adicionar imagens após criar a matéria.",
            preferredStyle: .alert
        )
        
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func didTapCell(at indexPath: IndexPath) {
        if indexPath.item == 0 {
            if !createMode {
                presentImagePickerOptions()
            } else {
                showImageAdditionInfoAlert()
            }
        } else {
            guard let book = book else { return }

            // Prepare Lightbox images
            var images: [LightboxImage] = []
            for imagePath in book.imagePaths {
                if let image = loadImage(from: imagePath) {
                    let lightboxImage = LightboxImage(image: image)
                    images.append(lightboxImage)
                }
            }

            let startIndex = indexPath.item - 1 // Exclude the "add photo" cell

            // Create LightboxController
            let lightboxController = LightboxController(images: images, startIndex: startIndex)
            lightboxController.pageDelegate = self
            lightboxController.dismissalDelegate = self

            // Use dynamic background
            lightboxController.dynamicBackground = true

            // Present controller
            present(lightboxController, animated: true, completion: nil)
        }
    }
    
    // Open the camera
    private func openCamera() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let imagePickerController = UIImagePickerController()
            imagePickerController.sourceType = .camera
            imagePickerController.delegate = self
            present(imagePickerController, animated: true, completion: nil)
        } else {
            print("Câmera não disponível")
        }
    }
    
    private func openPhotoLibrary() {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let imagePickerController = UIImagePickerController()
            imagePickerController.sourceType = .photoLibrary
            imagePickerController.delegate = self
            present(imagePickerController, animated: true, completion: nil)
        }
    }
}

extension BookViewController: LightboxControllerPageDelegate, LightboxControllerDismissalDelegate {
    func lightboxController(_ controller: LightboxController, didMoveToPage page: Int) {
        // Handle page change if needed
    }
    
    func lightboxControllerWillDismiss(_ controller: LightboxController) {
        // Handle dismissal if needed
    }
}

class BookViewController: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, GADInterstitialDelegate {
    var images: [UIImage?] = Array(repeating: nil, count: 10)
    // MARK: Properties
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    // New labels
    @IBOutlet weak var missTextField: UILabel!
    @IBOutlet weak var totalMiss: UILabel!
    @IBOutlet weak var dividerBar: UILabel!
    
    @IBOutlet weak var lessonsTextField: UITextField!
    @IBOutlet weak var obsTextView: UITextView!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    var currentMiss = 0
    var maxMiss = 0
    
    var book: BookClass?
    var interstitial: GADInterstitial!
    var firstAdd = true
    var photoImage: UIImage?
    
    private let photosLabel: UILabel = {
        let label = UILabel()
        label.text = "Fotos da Aula"
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textColor = .black
        label.textAlignment = .left
        return label
    }()
    
    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 10
        layout.itemSize = CGSize(width: 80, height: 80)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(CustomCollectionViewCell.self, forCellWithReuseIdentifier: "CustomCollectionViewCell")
        collectionView.backgroundColor = .clear
        return collectionView
    }()
    
    // Load image from a path
    private func loadImage(from imagePath: String) -> UIImage? {
        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(imagePath)
        return UIImage(contentsOfFile: fileURL.path)
    }
    
    // Save image to file system
    private func saveImage(_ image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        let fileName = UUID().uuidString + ".jpg"
        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(fileName)
        do {
            try data.write(to: fileURL)
            return fileName
        } catch {
            print("Erro ao salvar imagem:", error)
            return nil
        }
    }
    
    func createAndLoadInterstitial() -> GADInterstitial {
        let interstitial = GADInterstitial(adUnitID: "ca-app-pub-8858389345934911/2509258121")
        interstitial.delegate = self
        interstitial.load(GADRequest())
        return interstitial
    }
    
    func interstitialDidDismissScreen(_ ad: GADInterstitial) {
        interstitial = createAndLoadInterstitial()
    }
    
    private let doneButton: UIButton = {
        let button = UIButton()
        button.setTitle("Calcular máximo de faltas", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        return button
    }()
    
    // MARK: - LifeCycle
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if RazeFaceProducts.store.isProductPurchased("NoAds.College") || (UserDefaults.standard.object(forKey: "NoAds.College") != nil) {
            print("comprado")
        } else {
            let launchCountKey = "launchCount"
            var launchCount = UserDefaults.standard.integer(forKey: launchCountKey)
            launchCount += 1
            UserDefaults.standard.set(launchCount, forKey: launchCountKey)
            
            if launchCount >= 5 {
                if interstitial.isReady {
                    interstitial.present(fromRootViewController: self)
                    UserDefaults.standard.set(0, forKey: launchCountKey)
                }
            }
        }
    }
    
    private func setupCollectionView() {
        view.addSubview(photosLabel)
        photosLabel.snp.makeConstraints { make in
            make.top.equalTo(dividerBar.snp.bottom).offset(30)
            make.leading.equalToSuperview().inset(16)
        }
        
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(photosLabel.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(100)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UserDefaults.standard.set(true, forKey: "FirtsUse")
        
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        
        interstitial = createAndLoadInterstitial()
        let request = GADRequest()
        interstitial.load(request)
        
        obsTextView.layer.cornerRadius = 10
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboardFunc))
        view.addGestureRecognizer(tap)
        
        obsTextView.delegate = self
        nameTextField.delegate = self
        
        if let bookControll = book {
            navigationItem.title = bookControll.name
            nameTextField.text = bookControll.name
            
            missTextField.text = String(format: "%02d", bookControll.currentMiss)
            totalMiss.text = String(format: "%02d", bookControll.maxMiss)
            
            currentMiss = bookControll.currentMiss
            maxMiss = bookControll.maxMiss
            
            lessonsTextField.text = String(bookControll.lessons)
            obsTextView.text = bookControll.observations
        }
        
        doneButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        
        view.addSubview(doneButton)
        doneButton.snp.makeConstraints { make in
            make.top.equalTo(lessonsTextField.snp.bottom)
            make.trailing.equalToSuperview().offset(-16)
        }
        doneButton.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        collectionView.register(CustomCollectionViewCell.self, forCellWithReuseIdentifier: "CustomCollectionViewCell")
        setupCollectionView()
        collectionView.isUserInteractionEnabled = true
        
        if let _ = book {
            createButton.isEnabled = false
            createButton.tintColor = UIColor.clear
        } else {
            createMode = true
            createButton.isEnabled = true
            createButton.tintColor = UIColor.systemBlue
        }
    }
    
    var createMode = false
    
    @objc private func doneButtonTapped() {
        let controller = CalculatorViewController()
        dismissKeyboardFunc()
        controller.delegate = self
        let navigation = UINavigationController(rootViewController: controller)
        present(navigation, animated: true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        missTextField.text = String(format: "%02d", currentMiss)
        totalMiss.text = String(format: "%02d", maxMiss)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        navigationItem.title = textField.text
        missTextField.text = String(format: "%02d", currentMiss)
        totalMiss.text = String(format: "%02d", maxMiss)
    }
    
    // MARK: - UIImagePickerControllerDelegate
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if createMode {
            guard let button = sender as? UIBarButtonItem, button === createButton else {
                os_log("The save button was not pressed, cancelling", log: OSLog.default, type: .debug)
                return
            }
        }
        
        // Verify if the name was provided, otherwise, set it to "Sem nome"
        var name = nameTextField.text ?? "Sem nome"
        if name.isEmpty {
            name = "Sem nome"
        }
        
        let photo = photoImage // The captured photo
        let lessons = Int(lessonsTextField.text ?? "0") ?? 0 // Number of lessons
        let observations = obsTextView.text ?? "" // User observations
        
        // Update `maxMiss` based on the entered lessons
        maxMiss = lessons
        
        // Update the `totalMiss` label with the new `maxMiss` value
        totalMiss.text = String(format: "%02d", maxMiss)
        
        // Pass the correct values to `imagePaths`
        let imagePaths = book?.imagePaths ?? []
        
        // Update the `book` object with the new information
        book = BookClass(name: name, photo: photo, currentMiss: currentMiss, maxMiss: maxMiss, lessons: lessons, observations: observations, imagePaths: imagePaths)
        
        // Request app review if applicable
        SKStoreReviewController.requestReview()
    }

    @IBOutlet weak var createButton: UIBarButtonItem!
    
    // MARK: - Actions
    
    @IBAction func subMiss(_ sender: Any) {
        if currentMiss > 0 {
            currentMiss -= 1
            missTextField.text = String(format: "%02d", currentMiss)
            totalMiss.text = String(format: "%02d", maxMiss)
            
            if currentMiss > maxMiss {
                missTextField.textColor = .red
                totalMiss.textColor = .red
                dividerBar.textColor = .red
            } else {
                missTextField.textColor = .black
                totalMiss.textColor = .black
                dividerBar.textColor = .black
            }
        }
    }
    
    @IBAction func addMiss(_ sender: Any) {
        currentMiss += 1
        missTextField.text = String(format: "%02d", currentMiss)
        totalMiss.text = String(format: "%02d", maxMiss)
        
        if currentMiss > maxMiss {
            missTextField.textColor = .red
            totalMiss.textColor = .red
            dividerBar.textColor = .red
        } else {
            missTextField.textColor = .black
            totalMiss.textColor = .black
            dividerBar.textColor = .black
        }
    }
    
    // MARK: - Private Methods
    @objc func dismissKeyboardFunc() {
        maxMiss = Int(lessonsTextField.text ?? "0") ?? 0
        
        missTextField.text = String(format: "%02d", currentMiss)
        totalMiss.text = String(format: "%02d", maxMiss)
        
        if currentMiss > maxMiss {
            missTextField.textColor = .red
            totalMiss.textColor = .red
            dividerBar.textColor = .red
        } else {
            missTextField.textColor = .black
            totalMiss.textColor = .black
            dividerBar.textColor = .black
        }
        
        view.endEditing(true)
    }
    
    // GADInterstitialDelegate methods...
    // Include your existing ad delegate methods here
}

extension BookViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        bottomConstraint.constant = 330
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        bottomConstraint.constant = 20
    }
}

extension BookViewController: CalculatorViewControllerDelegate {
    func populateNewValue(withValue: Int) {
        lessonsTextField.text = "\(withValue)"
        totalMiss.text = "\(withValue)"
        maxMiss = withValue
    }
}

extension BookViewController {
    private func presentImagePickerOptions() {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: "Escolha uma opção", message: nil, preferredStyle: .actionSheet)
            
            let cameraAction = UIAlertAction(title: "Tirar Foto", style: .default) { _ in
                self.openCameraWithPermission()
            }
            
            let galleryAction = UIAlertAction(title: "Escolher da Galeria", style: .default) { _ in
                self.openPhotoLibraryWithPermission()
            }
            
            let cancelAction = UIAlertAction(title: "Cancelar", style: .cancel, handler: nil)
            
            alertController.addAction(cameraAction)
            alertController.addAction(galleryAction)
            alertController.addAction(cancelAction)
            
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    private func checkCameraPermission(completion: @escaping (Bool) -> Void) {
        let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch cameraAuthorizationStatus {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                completion(granted)
            }
        case .denied, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }
    }
    
    private func checkPhotoLibraryPermission(completion: @escaping (Bool) -> Void) {
        let photoAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
        
        switch photoAuthorizationStatus {
        case .authorized, .limited:
            completion(true)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { status in
                completion(status == .authorized || status == .limited)
            }
        case .denied, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }
    }
    
    private func openPhotoLibraryWithPermission() {
        checkPhotoLibraryPermission { granted in
            DispatchQueue.main.async {
                if granted {
                    var configuration = PHPickerConfiguration()
                    configuration.filter = .images
                    configuration.selectionLimit = 0
                    let picker = PHPickerViewController(configuration: configuration)
                    picker.delegate = self
                    self.present(picker, animated: true, completion: nil)
                } else {
                    self.showPermissionDeniedAlert(for: "Galeria de Fotos")
                }
            }
        }
    }
    
    private func showPermissionDeniedAlert(for feature: String) {
        let alert = UIAlertController(title: "\(feature) Acesso Negado",
                                      message: "Por favor, permita o acesso à \(feature) nas configurações do dispositivo.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Abrir Configurações", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
            }
        })
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}
