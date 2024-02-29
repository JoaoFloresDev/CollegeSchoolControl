//
//  BookTableViewController.swift
//  Dispensado
//
//  Created by Joao Flores on 20/04/20.
//  Copyright © 2020 Joao Flores. All rights reserved.
//

import UIKit
import os.log
import StoreKit
import SnapKit

class BookTableViewController: UITableViewController {
    
    //MARK: Properties
    @IBOutlet weak var premiumView: UIView!
    
    var books = [BookClass]()

    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        } 
        
        navigationItem.leftBarButtonItem = editButtonItem
        
        if let savedBooks = loadBooks() {
            books += savedBooks
        }
        
        let botaoEsquerda = UIBarButtonItem(title: "Pro", style: .plain, target: self, action: #selector(açãoDoBotãoEsquerda))
        self.navigationItem.leftBarButtonItem = botaoEsquerda
    }

    @objc 
    func açãoDoBotãoEsquerda() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        if let viewController = storyboard.instantiateViewController(withIdentifier: "MasterViewController") as? UIViewController {
            self.present(viewController, animated: true, completion: nil)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    //MARK: - Table view data source

    @IBOutlet weak var purchaseButton: UIButton!
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return books.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cellIdentifier = "MealTableViewCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? BookTableViewCell  else {
            fatalError("The dequeued cell is not an instance of MealTableViewCell.")
        }
        
        let meal = books[indexPath.row]
        
        cell.nameLabel.text = meal.name
        if let photo = meal.photo {
            cell.photoImageView.image = meal.photo
            cell.photoImageView.isHidden = false
        } else {
            cell.photoImageView.isHidden = true
        }
        
        cell.missLabel.text = String(format: "%02d", meal.currentMiss)
        cell.totalMiss.text = String(format: "%02d", meal.maxMiss)
        
        cell.addButton.tag = indexPath.row
        cell.lessBUtton.tag = indexPath.row
        
        cell.addButton.addTarget(self, action: #selector(buttonAddTapped(_:)), for: .touchUpInside)
        cell.lessBUtton.addTarget(self, action: #selector(buttonLessTapped(_:)), for: .touchUpInside)
        if(meal.currentMiss > meal.maxMiss)  {
            cell.missLabel.textColor = UIColor.red
            cell.dividerBar.textColor = UIColor.red
            cell.totalMiss.textColor = UIColor.red
        }
        else {
            cell.missLabel.textColor = UIColor.black
            cell.dividerBar.textColor = UIColor.black
            cell.totalMiss.textColor = UIColor.black
        }
        
        cell.cropBounds(viewlayer: cell.photoImageView.layer, cornerRadius: 10)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    @objc
    func buttonAddTapped(_ sender: UIButton) {
        var book = books[sender.tag]
        book.currentMiss += 1
        books[sender.tag] = book
        tableView.reloadRows(at: [IndexPath(row: sender.tag, section: 0)], with: .none)
        saveBooks()
    }
    
    @objc private func buttonLessTapped(_ sender: UIButton) {
        var book = books[sender.tag]
        if book.currentMiss <= 0 {
            return
        }
        book.currentMiss -= 1
        books[sender.tag] = book
        tableView.reloadRows(at: [IndexPath(row: sender.tag, section: 0)], with: .none)
        saveBooks()
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            books.remove(at: indexPath.row)
            saveBooks()
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }

    //MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        switch(segue.identifier ?? "") {
            
        case "AddItem":
            os_log("Adding a new meal.", log: OSLog.default, type: .debug)
            
        case "ShowDetail":
            guard let mealDetailViewController = segue.destination as? BookViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            guard let selectedMealCell = sender as? BookTableViewCell else {
                fatalError("Unexpected sender: \(String(describing: sender))")
            }
            
            guard let indexPath = tableView.indexPath(for: selectedMealCell) else {
                fatalError("The selected cell is not being displayed by the table")
            }
            
            let selectedMeal = books[indexPath.row]
            mealDetailViewController.book = selectedMeal
            
        default:
            print("Vai compra heheeee")
        }
    }

    
    //MARK: Actions
    
    @IBAction func unwindToBookList(sender: UIStoryboardSegue) {
        if let sourceViewController = sender.source as? BookViewController, let meal = sourceViewController.book {
            
            if let selectedIndexPath = tableView.indexPathForSelectedRow {
                books[selectedIndexPath.row] = meal
                tableView.reloadRows(at: [selectedIndexPath], with: .none)
            }
            else {
                let newIndexPath = IndexPath(row: books.count, section: 0)
                books.append(meal)
                tableView.insertRows(at: [newIndexPath], with: .automatic)
            }
            
            saveBooks()
        }
    }
    
    //MARK: Private Methods
    
    private func saveBooks() {
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(books, toFile: BookClass.ArchiveURL.path)
        if isSuccessfulSave {
            os_log("Successfully saved.", log: OSLog.default, type: .debug)
        } else {
            os_log("Failed to save...", log: OSLog.default, type: .error)
        }
    }
    
    private func loadBooks() -> [BookClass]?  {
        return NSKeyedUnarchiver.unarchiveObject(withFile: BookClass.ArchiveURL.path) as? [BookClass]
    }

}

extension UIView {
    func removerTodasConstraints() {
        // Remove todas as constraints que referenciam a view
        var superview = self.superview
        
        while let view = superview {
            for constraint in view.constraints where constraint.firstItem as? UIView == self || constraint.secondItem as? UIView == self {
                view.removeConstraint(constraint)
            }
            superview = view.superview
        }
        
        // Remove todas as constraints da própria view
        self.removeConstraints(self.constraints)
    }
}
