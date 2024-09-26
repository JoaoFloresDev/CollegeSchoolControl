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

// Atualize seu método para abrir a galeria com múltipla seleção usando PHPickerViewController


// Implementação do delegate PHPickerViewController
@available(iOS 14, *)
extension BookViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true, completion: nil)
        
        for result in results {
            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (image, error) in
                guard let self = self, let selectedImage = image as? UIImage else { return }
                
                if let imagePath = self.saveImage(selectedImage) {
                    DispatchQueue.main.async {
                        self.book?.imagePaths.append(imagePath)
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

    // Função para permitir tirar múltiplas fotos
    private func takeMultiplePhotos() {
        let alertController = UIAlertController(title: "Tirar outra foto?", message: nil, preferredStyle: .alert)
        
        let takePhotoAction = UIAlertAction(title: "Sim", style: .default) { _ in
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                let imagePickerController = UIImagePickerController()
                imagePickerController.sourceType = .camera
                imagePickerController.delegate = self
                imagePickerController.allowsEditing = true
                self.present(imagePickerController, animated: true, completion: nil)
            }
        }
        
        let finishAction = UIAlertAction(title: "Finalizar", style: .cancel, handler: nil)
        
        alertController.addAction(takePhotoAction)
        alertController.addAction(finishAction)
        
        present(alertController, animated: true, completion: nil)
    }

    // Modifique o delegate do UIImagePickerController para permitir tirar múltiplas fotos
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let selectedImage = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
            if let imagePath = saveImage(selectedImage) {
                book?.imagePaths.append(imagePath)
                collectionView.reloadData() // Atualizar a collection view
            }
        }
        dismiss(animated: true) {
            // Reabrir a câmera para tirar outra foto
            self.takeMultiplePhotos()
        }
    }
}

extension BookViewController: UICollectionViewDelegate, UICollectionViewDataSource, CustomCollectionViewCellDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (book?.imagePaths.count ?? 0) + 1 // +1 para o ícone de adicionar
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CustomCollectionViewCell", for: indexPath) as! CustomCollectionViewCell
        
        cell.delegate = self
        cell.indexPath = indexPath
        
        if indexPath.item == 0 {
            // Exibir o ícone de adição na primeira célula
            cell.imageView.image = UIImage(systemName: "plus.circle")
            cell.imageView.tintColor = .systemBlue
            cell.imageView.contentMode = .scaleAspectFit
        } else {
            // Carregar a imagem associada ao caminho de imagem salvo
            if let imagePath = book?.imagePaths[indexPath.item - 1], let image = loadImage(from: imagePath) {
                cell.imageView.image = image
            } else {
                cell.imageView.image = UIImage(named: "premiumIcon") // Imagem placeholder
            }
        }
        
        return cell
    }
    
    // Delegate que será chamado quando a célula for clicada
    func didTapCell(at indexPath: IndexPath) {
        if indexPath.item == 0 {
            presentImagePickerOptions() // Abrir opções para escolher uma imagem
        } else {
            guard let book = book else { return }
            
            // Prepare a lista de imagens para exibir em tela cheia
            var images: [UIImage] = []
            for imagePath in book.imagePaths {
                if let image = loadImage(from: imagePath) {
                    images.append(image)
                }
            }
            
            // Apresentar a tela de visualização em tela cheia com swipe horizontal
            let photoPageVC = PhotoPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
            photoPageVC.images = images
            photoPageVC.currentIndex = indexPath.item - 1 // Exclui a célula de "adicionar foto"
            
            photoPageVC.modalPresentationStyle = .fullScreen
            present(photoPageVC, animated: true, completion: nil)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item == 0 {
            presentImagePickerOptions()
        } else {
            print("Item \(indexPath.item) selecionado")
        }
    }
    
    // Abre a câmera
    private func openCamera() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let imagePickerController = UIImagePickerController()
            imagePickerController.sourceType = .camera
            imagePickerController.delegate = self
//            imagePickerController.allowsEditing = true
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
//            imagePickerController.allowsEditing = true
            present(imagePickerController, animated: true, completion: nil)
        }
    }
}

class BookViewController: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, GADInterstitialDelegate {
    var images: [UIImage?] = Array(repeating: nil, count: 10)
    //MARK: Properties
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    //    novos texts
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
    
    
    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 10
        layout.itemSize = CGSize(width: 100, height: 100)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(CustomCollectionViewCell.self, forCellWithReuseIdentifier: "CustomCollectionViewCell")
        collectionView.backgroundColor = .clear
        return collectionView
    }()
    
    // Carregar a imagem a partir de um caminho
    private func loadImage(from imagePath: String) -> UIImage? {
        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(imagePath)
        return UIImage(contentsOfFile: fileURL.path)
    }
    
    // Salvar a imagem no sistema de arquivos
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
    
    // Salvar imagem selecionada
//    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
//        if let selectedImage = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
//            if let imagePath = saveImage(selectedImage) {
//                book?.imagePaths.append(imagePath)
//                collectionView.reloadData() // Atualizar a collection view
//            }
//        }
//        dismiss(animated: true, completion: nil)
//    }
//    
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
    
    //    MARK: - LifeCycle
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
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(dividerBar.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(120)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UserDefaults.standard.set(true, forKey:"FirtsUse")
        
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        
        interstitial = GADInterstitial(adUnitID: "ca-app-pub-8858389345934911/2509258121")
        interstitial.delegate = self
        interstitial = createAndLoadInterstitial()
        let request = GADRequest()
        interstitial.load(request)
        
        obsTextView.layer.cornerRadius = 10
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: Selector(("dismissKeyboardFunc")))
        
        view.addGestureRecognizer(tap)
        
        obsTextView.delegate = self as? UITextViewDelegate
        nameTextField.delegate = self
        
        if let bookControll = book {
            navigationItem.title = bookControll.name
            nameTextField.text = bookControll.name
//            photoImageView.image = bookControll.photo ?? UIImage(named: "IconPlaceholder")
            
            missTextField.text = String(format: "%02d", bookControll.currentMiss)
            totalMiss.text = String(format: "%02d", bookControll.maxMiss)
            
            currentMiss = bookControll.currentMiss
            maxMiss = bookControll.maxMiss
            
            lessonsTextField.text = String(bookControll.lessons)
            obsTextView.text = bookControll.observations
        }
        
//        cropBounds(viewlayer: photoImageView.layer, cornerRadius: 10)
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
        if let book = book {
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
    
    //    MARK: - LifeCycle
    func cropBounds(viewlayer: CALayer, cornerRadius: Float) {
        
        let imageLayer = viewlayer
        imageLayer.cornerRadius = CGFloat(cornerRadius)
        imageLayer.masksToBounds = true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        navigationItem.title = textField.text
    }
    
    //MARK: - UIImagePickerControllerDelegate
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
        
        var name = nameTextField.text ?? "Sem nome"
        if name.isEmpty {
            name = "Sem nome"
        }
        let photo = photoImage
        let lessons = Int(lessonsTextField.text ?? "0") ?? 0
        let observations = obsTextView.text ?? ""
        maxMiss = Int(Double(lessons))

        // Passando os valores corretos para imagePaths
        let imagePaths = book?.imagePaths ?? []
        
        // Atualizando o objeto book com as novas informações
        book = BookClass(name: name, photo: photo, currentMiss: currentMiss, maxMiss: maxMiss, lessons: lessons, observations: observations, imagePaths: imagePaths)

        SKStoreReviewController.requestReview()
    }
    @IBOutlet weak var createButton: UIBarButtonItem!
    
    
    //MARK: - Actions
    
    @IBAction func subMiss(_ sender: Any) {
        if(currentMiss > 0) {
            currentMiss = currentMiss - 1
            
            missTextField.text = String(format: "%02d", currentMiss)
            totalMiss.text = String(format: "%02d", maxMiss)
            
            if(currentMiss > maxMiss) {
                missTextField.textColor = UIColor.red
                totalMiss.textColor = UIColor.red
                dividerBar.textColor = UIColor.red
            }
            else {
                missTextField.textColor = UIColor.black
                totalMiss.textColor = UIColor.black
                dividerBar.textColor = UIColor.black
            }
        }
    }
    
    @IBAction func addMiss(_ sender: Any) {
        
        currentMiss = currentMiss + 1
        missTextField.text = String(format: "%02d", currentMiss)
        totalMiss.text = String(format: "%02d", maxMiss)
        
        if(currentMiss > maxMiss) {
            missTextField.textColor = UIColor.red
            totalMiss.textColor = UIColor.red
            dividerBar.textColor = UIColor.red
        }
        else {
            missTextField.textColor = UIColor.black
            totalMiss.textColor = UIColor.black
            dividerBar.textColor = UIColor.black
        }
    }
    
    //MARK: - Private Methods
    @objc func dismissKeyboardFunc() {
        maxMiss = Int(Double(Int(lessonsTextField.text ?? "0") ?? 0))
        
        if book != nil {
            missTextField.text = String(format: "%02d", currentMiss)
            totalMiss.text = String(format: "%02d", maxMiss)
            
            if(currentMiss > maxMiss) {
                missTextField.textColor = UIColor.red
                totalMiss.textColor = UIColor.red
                dividerBar.textColor = UIColor.red
            }
            else {
                missTextField.textColor = UIColor.black
                totalMiss.textColor = UIColor.black
                dividerBar.textColor = UIColor.black
            }
        }
        
        view.endEditing(true)
    }
    
    /// Tells the delegate an ad request succeeded.
    func interstitialDidReceiveAd(_ ad: GADInterstitial) {
        print("interstitialDidReceiveAd")
    }
    
    /// Tells the delegate an ad request failed.
    func interstitial(_ ad: GADInterstitial, didFailToReceiveAdWithError error: GADRequestError) {
        print("interstitial:didFailToReceiveAdWithError: \(error.localizedDescription)")
    }
    
    /// Tells the delegate that an interstitial will be presented.
    func interstitialWillPresentScreen(_ ad: GADInterstitial) {
        print("interstitialWillPresentScreen")
    }
    
    /// Tells the delegate the interstitial is to be animated off the screen.
    func interstitialWillDismissScreen(_ ad: GADInterstitial) {
        print("interstitialWillDismissScreen")
    }
    
    /// Tells the delegate that a user click will open another app
    /// (such as the App Store), backgrounding the current app.
    func interstitialWillLeaveApplication(_ ad: GADInterstitial) {
        print("interstitialWillLeaveApplication")
    }
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
            // Acesso já concedido
            completion(true)
        case .notDetermined:
            // O usuário ainda não foi solicitado, pedimos a permissão
            AVCaptureDevice.requestAccess(for: .video) { granted in
                completion(granted)
            }
        case .denied, .restricted:
            // Acesso negado ou restrito
            completion(false)
        @unknown default:
            completion(false)
        }
    }
    
    private func checkPhotoLibraryPermission(completion: @escaping (Bool) -> Void) {
        let photoAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
        
        switch photoAuthorizationStatus {
        case .authorized:
            // Acesso já concedido
            completion(true)
        case .notDetermined:
            // O usuário ainda não foi solicitado, pedimos a permissão
            PHPhotoLibrary.requestAuthorization { status in
                completion(status == .authorized)
            }
        case .denied, .restricted:
            // Acesso negado ou restrito
            completion(false)
        @unknown default:
            completion(false)
        }
    }
    private func openPhotoLibraryWithPermission() {
        checkPhotoLibraryPermission { granted in
            DispatchQueue.main.async {
                if granted {
                    if #available(iOS 14.0, *) {
                        var configuration = PHPickerConfiguration()
                        configuration.filter = .images // Apenas imagens
                        configuration.selectionLimit = 0 // Ilimitado
                        let picker = PHPickerViewController(configuration: configuration)
                        picker.delegate = self
                        self.present(picker, animated: true, completion: nil)
                    } else {
                        // Fallback para iOS 13 ou anterior usando UIImagePickerController
                        self.openPhotoLibrary()
                    }
                } else {
                    self.showPermissionDeniedAlert(for: "Galeria de Fotos")
                }
            }
        }
    }
    // Abre a câmera se a permissão foi concedida
//    private func openCameraWithPermission() {
//        checkCameraPermission { granted in
//            DispatchQueue.main.async {
//                if granted {
//                    self.openCamera()
//                } else {
//                    self.showPermissionDeniedAlert(for: "Câmera")
//                }
//            }
//        }
//    }
//    
//    // Abre a galeria se a permissão foi concedida
//    private func openPhotoLibraryWithPermission() {
//        checkPhotoLibraryPermission { granted in
//            DispatchQueue.main.async {
//                if granted {
//                    self.openPhotoLibrary()
//                } else {
//                    self.showPermissionDeniedAlert(for: "Galeria de Fotos")
//                }
//            }
//        }
//    }
    
    // Mostra alerta informando que a permissão foi negada
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
