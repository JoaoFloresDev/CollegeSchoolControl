//
//  CustomCollectionViewCell.swift
//  College
//
//  Created by Joao Victor Flores da Costa on 25/09/24.
//  Copyright © 2024 Joao Flores. All rights reserved.
//

import Foundation
import AVFoundation
import Photos
import UIKit
import os.log
import GoogleMobileAds
import SnapKit

protocol CustomCollectionViewCellDelegate: AnyObject {
    func didTapCell(at indexPath: IndexPath)
}

class CustomCollectionViewCell: UICollectionViewCell {
    weak var delegate: CustomCollectionViewCellDelegate?
    var indexPath: IndexPath?
    
    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 10
        imageView.layer.masksToBounds = true
        imageView.clipsToBounds = true // Garante que a imagem não ultrapasse os limites
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        
        // Configuração do layout com SnapKit
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview() // Garante que o imageView preencha toda a célula
        }
        
        // Adicionar gesto de toque à célula
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        contentView.addGestureRecognizer(tapGesture)
        
        // Adicionar sombra
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.3
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4
        layer.masksToBounds = false
    }
    
    @objc private func handleTap() {
        if let indexPath = indexPath {
            delegate?.didTapCell(at: indexPath)
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

