//
//  BookTableViewController.swift
//  Dispensado
//
//  Created by Joao Flores on 20/04/20.
//  Copyright © 2020 Joao Flores. All rights reserved.
//

import UIKit
import os.log
import StoreKit // Import StoreKit for SKStoreReviewController
import SnapKit

class BookTableViewController: UITableViewController {
    
    // MARK: - Properties
    @IBOutlet weak var premiumView: UIView!
    
    var books = [BookClass]()
    
    lazy var placeholderImageView = PlaceholderView(
        title: "Boas aulas!",
        subtitle: "Adicione novas matérias clicando no botão +",
        image: UIImage(named: "placeholder")
    )
    
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
        
        if !(RazeFaceProducts.store.isProductPurchased("NoAds.College") || (UserDefaults.standard.object(forKey: "NoAds.College") != nil)) {
            if check30DaysPassed() {
                açãoDoBotãoEsquerda()
            }
        }
        
        self.tableView.backgroundView = placeholderImageView
        placeholderImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(240)
            make.centerX.equalToSuperview()
        }
        
        // Add the following code to implement the review request after 20 app launches
        requestAppReviewIfAppropriate()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addBackgroundIfNeed()
    }

    // MARK: - App Review Request Implementation
    
    private func requestAppReviewIfAppropriate() {
        let launchCountKey = "launchCount"
        let hasRequestedReviewKey = "hasRequestedReview"
        
        var launchCount = UserDefaults.standard.integer(forKey: launchCountKey)
        launchCount += 1
        UserDefaults.standard.set(launchCount, forKey: launchCountKey)
        
        let hasRequestedReview = UserDefaults.standard.bool(forKey: hasRequestedReviewKey)
        
        if launchCount >= 30 && !hasRequestedReview {
        showReviewAlert()
        }
    }
    
    private func showReviewAlert() {
        let alert = UIAlertController(
            title: "Gostaria de nos avaliar?",
            message: "Sua avaliação é muito importante para nós!",
            preferredStyle: .alert
        )
        
        let rateAction = UIAlertAction(title: "Avaliar", style: .default) { _ in
            let appID = "1508371263" // Replace with your actual App Store app ID
            if let url = URL(string: "itms-apps://itunes.apple.com/app/id\(appID)?action=write-review"),
               UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
            UserDefaults.standard.set(true, forKey: "hasRequestedReview") // Marcar que já solicitamos a avaliação
        }
        
        let cancelAction = UIAlertAction(title: "Cancelar", style: .cancel) { _ in
            UserDefaults.standard.set(true, forKey: "hasRequestedReview") // Marcar que já solicitamos, para não perguntar novamente
        }
        
        alert.addAction(rateAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    func saveTodayDate() {
        let now = Date()
        UserDefaults.standard.set(now, forKey: "LastSavedDate")
    }

    func check30DaysPassed() -> Bool {
        if let lastSavedDate = UserDefaults.standard.object(forKey: "LastSavedDate") as? Date {
            let dayDifference = Calendar.current.dateComponents([.day], from: lastSavedDate, to: Date()).day ?? 0
            if dayDifference >= 14 {
                saveTodayDate()
                return true
            } else {
                return false
            }
        }
        saveTodayDate()
        return false
    }
    
    @objc
    func açãoDoBotãoEsquerda() {
        let storyboard = UIStoryboard(name: "Purchase", bundle: nil)
        let purchaseVC = storyboard.instantiateViewController(withIdentifier: "Purchase")
        self.present(purchaseVC, animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source

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
            cell.photoImageView.image = photo
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
        
        if meal.currentMiss > meal.maxMiss {
            cell.missLabel.textColor = UIColor.red
            cell.dividerBar.textColor = UIColor.red
            cell.totalMiss.textColor = UIColor.red
        } else {
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
            addBackgroundIfNeed()
        }
    }

    func addBackgroundIfNeed() {
        if books.isEmpty {
            placeholderImageView.isHidden = false
        } else {
            placeholderImageView.isHidden = true
        }
    }
    
    // MARK: - Navigation

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
            print("Unrecognized segue identifier.")
        }
    }

    // MARK: - Actions

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
            addBackgroundIfNeed()
        }
    }

    // MARK: - Private Methods

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
        // Remove all constraints that reference the view
        var superview = self.superview

        while let view = superview {
            for constraint in view.constraints where constraint.firstItem as? UIView == self || constraint.secondItem as? UIView == self {
                view.removeConstraint(constraint)
            }
            superview = view.superview
        }

        // Remove all constraints of the view itself
        self.removeConstraints(self.constraints)
    }
}
