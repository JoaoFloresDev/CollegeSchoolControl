//
//  ImageStorageService.swift
//  College
//
//  Created by Joao Victor Flores da Costa on 25/09/24.
//  Copyright © 2024 Joao Flores. All rights reserved.
//

import Foundation
import UIKit

class ImageStorageService {
    
    private let fileManager = FileManager.default
    private var imagesDirectoryURL: URL? {
        // Obtém o diretório de documentos do aplicativo para armazenar as imagens permanentemente
        return fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
    }
    
    // MARK: - Salvar imagem localmente com uma chave
    func saveImage(_ image: UIImage, forKey key: String) -> Bool {
        guard let data = image.jpegData(compressionQuality: 1.0) else { return false }
        guard let directory = imagesDirectoryURL else { return false }
        
        // Criando um caminho exclusivo para a imagem com base na chave e em um identificador de tempo
        let timestamp = Int(Date().timeIntervalSince1970)
        let imagePath = directory.appendingPathComponent("\(key)_\(timestamp).jpg")
        
        do {
            try data.write(to: imagePath)
            return true
        } catch {
            print("Erro ao salvar a imagem: \(error)")
            return false
        }
    }
    
    // MARK: - Recuperar todas as imagens associadas a uma chave
    func retrieveImages(forKey key: String) -> [UIImage] {
        guard let directory = imagesDirectoryURL else { return [] }
        
        do {
            // Recupera todos os arquivos no diretório de documentos
            let fileURLs = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            
            // Filtra os arquivos que começam com a chave fornecida
            let imageFiles = fileURLs.filter { $0.lastPathComponent.hasPrefix(key) }
            
            // Carrega as imagens
            var images: [UIImage] = []
            for imageFile in imageFiles {
                if let imageData = try? Data(contentsOf: imageFile),
                   let image = UIImage(data: imageData) {
                    images.append(image)
                }
            }
            return images
        } catch {
            print("Erro ao recuperar imagens: \(error)")
            return []
        }
    }
}
