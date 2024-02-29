//
//  DiamondView.swift
//  Calculator Notes
//
//  Created by Joao Victor Flores da Costa on 20/09/23.
//  Copyright © 2023 MakeSchool. All rights reserved.
//

import Foundation
import UIKit
import SnapKit



class DiamondView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        backgroundColor = .clear
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        // Criar uma imagem de gradiente
        let gradientColors = [UIColor(hex: "FBFBFC").cgColor, UIColor.systemGray4.cgColor]
        let gradientLocations: [NSNumber] = [0, 1]
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = gradientColors
        gradientLayer.locations = gradientLocations
        gradientLayer.frame = rect
        UIGraphicsBeginImageContext(gradientLayer.bounds.size)
        gradientLayer.render(in: UIGraphicsGetCurrentContext()!)
        let gradientImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // Configuração do estilo do pentágono
        context.setFillColor(UIColor(patternImage: gradientImage!).cgColor)
        
        // Calcula os pontos para o pentágono
        let bottomPoint = CGPoint(x: rect.midX, y: rect.maxY)
        let topLeftPoint = CGPoint(x: rect.minX, y: rect.minY)
        let topRightPoint = CGPoint(x: rect.maxX, y: rect.minY)
        let middleLeftPoint = CGPoint(x: rect.minX, y: rect.maxY - 24)
        let middleRightPoint = CGPoint(x: rect.maxX, y: rect.maxY - 24)
        
        // Desenha o pentágono
        context.beginPath()
        context.move(to: bottomPoint)
        context.addLine(to: middleRightPoint)
        context.addLine(to: topRightPoint)
        context.addLine(to: topLeftPoint)
        context.addLine(to: middleLeftPoint)
        context.closePath()
        
        // Preenche o pentágono
        context.fillPath()
    }
}

extension UIColor {
    /// Inicializa uma nova cor usando um valor hexadecimal.
    ///
    /// - Parameters:
    ///   - hex: Um valor hexadecimal de 6 ou 8 caracteres.
    ///   - alpha: O valor alfa da cor, entre 0 e 1. O padrão é 1.
    /// - Returns: Uma instância da cor correspondente.
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        let hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        let hexClean = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        Scanner(string: hexClean).scanHexInt64(&rgb)
        
        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
