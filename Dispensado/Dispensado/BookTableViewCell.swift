//
//  BookTableViewCell.swift
//  Dispensado
//
//  Created by Joao Flores on 20/04/20.
//  Copyright © 2020 Joao Flores. All rights reserved.
//

import UIKit

class BookTableViewCell: UITableViewCell {
    
    //MARK: Properties
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var missLabel: UILabel!

    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var lessBUtton: UIButton!
    
    let backgroundShadowView = UIView()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        nameLabel.numberOfLines = 1
        missLabel.tintColor = .systemGray
        setupShadowAndRoundedCorners()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    func cropBounds(viewlayer: CALayer, cornerRadius: Float) {
        let imageLayer = viewlayer
        imageLayer.cornerRadius = CGFloat(cornerRadius)
        imageLayer.masksToBounds = true
    }
    
    private func setupShadowAndRoundedCorners() {
        // Configuração da sombra
        backgroundShadowView.backgroundColor = .white
        backgroundShadowView.layer.shadowColor = UIColor.black.cgColor
        backgroundShadowView.layer.shadowOffset = CGSize(width: 0, height: 0)
        backgroundShadowView.layer.shadowOpacity = 0.2
        backgroundShadowView.layer.shadowRadius = 5.0
        
        // Adiciona a view de sombra como uma subview e envia para o fundo
        addSubview(backgroundShadowView)
        sendSubviewToBack(backgroundShadowView)
        
        // Configuração dos cantos arredondados para a backgroundShadowView
        backgroundShadowView.layer.cornerRadius = 16.0
        backgroundShadowView.clipsToBounds = false

        // Garante que a sombra apareça corretamente
        layer.masksToBounds = false
        
        // Ajusta o layout da view de sombra para corresponder ao layout da célula
        backgroundShadowView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backgroundShadowView.topAnchor.constraint(equalTo: self.topAnchor, constant: 8),
            backgroundShadowView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -8),
            backgroundShadowView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16),
            backgroundShadowView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -16),
        ])
    }
}

