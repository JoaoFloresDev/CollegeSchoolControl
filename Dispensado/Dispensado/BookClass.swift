import UIKit
import os.log

class BookClass: NSObject, NSCoding {
    
    //MARK: Properties
    
    var name: String
    var photo: UIImage?
    var currentMiss: Int
    var maxMiss: Int
    var lessons: Int
    var observations: String
    var imagePaths: [String] // Lista de caminhos para as imagens associadas
    
    //MARK: Archiving Paths
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("books")
    
    //MARK: Types
    
    struct PropertyKey {
        static let name = "name"
        static let photo = "photo"
        static let currentMiss = "currentMiss"
        static let maxMiss = "maxMiss"
        static let lessons = "lessons"
        static let observations = "observations"
        static let imagePaths = "imagePaths" // Chave para as imagens
    }
    
    //MARK: Initialization
    
    init?(name: String, photo: UIImage?, currentMiss: Int, maxMiss: Int, lessons: Int, observations: String, imagePaths: [String]) {
        
        // O nome não pode estar vazio
        guard !name.isEmpty else {
            return nil
        }
        
        // Inicializar propriedades armazenadas
        self.name = name
        self.photo = photo
        self.currentMiss = currentMiss
        self.maxMiss = maxMiss
        self.lessons = lessons
        self.observations = observations
        self.imagePaths = imagePaths
    }
    
    //MARK: NSCoding
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: PropertyKey.name)
        aCoder.encode(photo, forKey: PropertyKey.photo)
        aCoder.encode(currentMiss, forKey: PropertyKey.currentMiss)
        aCoder.encode(maxMiss, forKey: PropertyKey.maxMiss)
        aCoder.encode(lessons, forKey: PropertyKey.lessons)
        aCoder.encode(observations, forKey: PropertyKey.observations)
        aCoder.encode(imagePaths, forKey: PropertyKey.imagePaths) // Salvando as imagens
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        
        // O nome é obrigatório, se não conseguir decodificar, falha.
        guard let name = aDecoder.decodeObject(forKey: PropertyKey.name) as? String else {
            os_log("Unable to decode the name for a Book object.", log: OSLog.default, type: .debug)
            return nil
        }
        
        guard let observations = aDecoder.decodeObject(forKey: PropertyKey.observations) as? String else {
            os_log("Unable to decode the observations for a Book object.", log: OSLog.default, type: .debug)
            return nil
        }
        
        let photo = aDecoder.decodeObject(forKey: PropertyKey.photo) as? UIImage
        let currentMiss = aDecoder.decodeInteger(forKey: PropertyKey.currentMiss)
        let maxMiss = aDecoder.decodeInteger(forKey: PropertyKey.maxMiss)
        let lessons = aDecoder.decodeInteger(forKey: PropertyKey.lessons)
        let imagePaths = aDecoder.decodeObject(forKey: PropertyKey.imagePaths) as? [String] ?? []
        
        // Chamando o inicializador designado.
        self.init(name: name, photo: photo, currentMiss: currentMiss, maxMiss: maxMiss, lessons: lessons, observations: observations, imagePaths: imagePaths)
    }
}
