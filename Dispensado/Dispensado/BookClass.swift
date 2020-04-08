//
//  Meal.swift
//  Dispensado
//
//  Created by Joao Flores on 01/12/19.
//  Copyright © 2019 Joao Flores. All rights reserved.
//

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
    
    //MARK: Archiving Paths
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("meals")
    
    //MARK: Types
    
    struct PropertyKey {
        static let name = "name"
        static let photo = "photo"
        static let currentMiss = "currentMiss"
        static let maxMiss = "maxMiss"
        static let lessons = "lessons"
        static let observations = "observations"
    }
    
    //MARK: Initialization
    
    init?(name: String, photo: UIImage?, currentMiss: Int, maxMiss: Int, lessons: Int, observations: String) {
        
        // The name must not be empty
        guard !name.isEmpty else {
            return nil
        }
        
        // Initialization should fail if there is no name or if the rating is negative.
        if name.isEmpty {
            return nil
        }
        
        // Initialize stored properties.
        self.name = name
        self.photo = photo
        self.currentMiss = currentMiss
        self.maxMiss = maxMiss
        self.lessons = lessons
        self.observations = observations
        
        
    }
    
    //MARK: NSCoding
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: PropertyKey.name)
        aCoder.encode(photo, forKey: PropertyKey.photo)
        
        aCoder.encode(currentMiss, forKey: PropertyKey.currentMiss)
        aCoder.encode(maxMiss, forKey: PropertyKey.maxMiss)
        aCoder.encode(lessons, forKey: PropertyKey.lessons)
        aCoder.encode(observations, forKey: PropertyKey.observations)
        
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        
        // The name is required. If we cannot decode a name string, the initializer should fail.
        guard let name = aDecoder.decodeObject(forKey: PropertyKey.name) as? String else {
            os_log("Unable to decode the name for a Meal object.", log: OSLog.default, type: .debug)
            return nil
        }
        
        guard let observations = aDecoder.decodeObject(forKey: PropertyKey.observations) as? String else {
            os_log("Unable to decode the name for a Meal object. OBS", log: OSLog.default, type: .debug)
            return nil
        }
        
        // Because photo is an optional property of Meal, just use conditional cast.
        let photo = aDecoder.decodeObject(forKey: PropertyKey.photo) as? UIImage
        
        let currentMiss = aDecoder.decodeInteger(forKey: PropertyKey.currentMiss)
        
        let maxMiss = aDecoder.decodeInteger(forKey: PropertyKey.maxMiss)
        
        let lessons = aDecoder.decodeInteger(forKey: PropertyKey.lessons)
        
        // Must call designated initializer.
        self.init(name: name, photo: photo, currentMiss: currentMiss, maxMiss: maxMiss, lessons: lessons, observations: observations)
        
    }
}
