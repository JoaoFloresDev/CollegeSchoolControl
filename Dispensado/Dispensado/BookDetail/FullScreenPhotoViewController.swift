//
//  FullScreenPhotoViewController.swift
//  College
//
//  Created by Joao Victor Flores da Costa on 25/09/24.
//  Copyright © 2024 Joao Flores. All rights reserved.
//

import AVFoundation
import Photos
import UIKit
import os.log
import GoogleMobileAds
import SnapKit

import UIKit
import SnapKit

class FullScreenPhotoViewController: UIViewController, UIScrollViewDelegate {
    
    private let scrollView = UIScrollView()
    private let imageView = UIImageView()
    var image: UIImage?
    private var currentRotationAngle: CGFloat = 0 // Variável para armazenar o ângulo atual da rotação
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        // Configurar scrollView
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 4.0
        view.addSubview(scrollView)
        
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // Configurar imageView
        imageView.contentMode = .scaleAspectFit
        imageView.image = image
        scrollView.addSubview(imageView)
        
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView.snp.width)
            make.height.equalTo(scrollView.snp.height)
        }
        
        // Gesto de Duplo Clique
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTapGesture)
        
        // Gesto de Voltar (um toque)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissFullScreen))
        view.addGestureRecognizer(tapGesture)
        
        // Gesto de Voltar (botão)
        let backButton = UIButton(type: .system)
        backButton.setTitle("Voltar", for: .normal)
        backButton.setTitleColor(.white, for: .normal)
        backButton.addTarget(self, action: #selector(dismissFullScreen), for: .touchUpInside)
        view.addSubview(backButton)
        
        backButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.leading.equalToSuperview().offset(16)
        }
        
        tapGesture.require(toFail: doubleTapGesture) // Certifique-se de que o double tap não cancela o single tap
        
        // Botão de compartilhar
        let shareButton = UIButton(type: .system)
        shareButton.setTitle("Share", for: .normal)
        shareButton.setTitleColor(.white, for: .normal)
        shareButton.addTarget(self, action: #selector(shareImage), for: .touchUpInside)
        view.addSubview(shareButton)
        
        shareButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }
    }
    
    // Método para fazer o zoom com o double tap
    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        if scrollView.zoomScale == scrollView.minimumZoomScale {
            let zoomRect = zoomRectForScale(scale: scrollView.maximumZoomScale, center: gesture.location(in: imageView))
            scrollView.zoom(to: zoomRect, animated: true)
        } else {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        }
    }
    
    // Calcular o retângulo de zoom
    private func zoomRectForScale(scale: CGFloat, center: CGPoint) -> CGRect {
        let width = scrollView.frame.size.width / scale
        let height = scrollView.frame.size.height / scale
        let originX = center.x - (width / 2.0)
        let originY = center.y - (height / 2.0)
        return CGRect(x: originX, y: originY, width: width, height: height)
    }
    
    // Método de UIScrollViewDelegate para definir a view a ser ampliada
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    // Método para dispensar a tela cheia
    @objc private func dismissFullScreen() {
        dismiss(animated: true, completion: nil)
    }
    
    // Método para compartilhar a imagem
    @objc private func shareImage() {
        guard let image = image else { return }
        let activityController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        present(activityController, animated: true, completion: nil)
    }
    
    // Método para rotacionar a imagem
    @objc private func rotateImage() {
        // Mantém o centro e a escala de zoom ao rotacionar
        currentRotationAngle += CGFloat(Double.pi / 2) // Rotaciona 90 graus
        
        // Calcular o centro atual antes de rotacionar
        let currentCenter = scrollView.convert(imageView.center, to: scrollView)
        
        // Aplicar a rotação
        UIView.animate(withDuration: 0.3) {
            self.imageView.transform = CGAffineTransform(rotationAngle: self.currentRotationAngle)
        } completion: { _ in
            // Após a rotação, ajustar as proporções da imageView para que o zoom funcione corretamente
            self.updateImageViewConstraintsAfterRotation()
            
            // Reaplica o centro após a rotação
            self.imageView.center = self.scrollView.convert(currentCenter, from: self.scrollView)
        }
    }
    
    // Método para atualizar as constraints da imageView após a rotação
    private func updateImageViewConstraintsAfterRotation() {
        // Certifique-se de ajustar a largura e altura da imageView após a rotação
        imageView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView.snp.height) // Trocando largura por altura
            make.height.equalTo(scrollView.snp.width) // Trocando altura por largura
        }
    }
}


class PhotoPageViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    var images: [UIImage] = []
    var currentIndex: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        delegate = self
        
        if let initialViewController = viewControllerForIndex(currentIndex) {
            setViewControllers([initialViewController], direction: .forward, animated: true, completion: nil)
        }
    }
    
    func viewControllerForIndex(_ index: Int) -> FullScreenPhotoViewController? {
        guard index >= 0 && index < images.count else {
            return nil
        }
        
        let fullScreenVC = FullScreenPhotoViewController()
        fullScreenVC.image = images[index]
        return fullScreenVC
    }
    
    // MARK: - UIPageViewControllerDataSource
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let currentVC = viewController as? FullScreenPhotoViewController,
              let currentIndex = images.firstIndex(of: currentVC.image!) else { return nil }
        let previousIndex = currentIndex - 1
        return viewControllerForIndex(previousIndex)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let currentVC = viewController as? FullScreenPhotoViewController,
              let currentIndex = images.firstIndex(of: currentVC.image!) else { return nil }
        let nextIndex = currentIndex + 1
        return viewControllerForIndex(nextIndex)
    }
}
