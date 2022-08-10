//
//  ViewController.swift
//  MyCars
//
//  Created by Roman Belov on 24.07.2022.
//

import UIKit
import CoreData

class ViewController: UIViewController {
    
    var context: NSManagedObjectContext!
    var car: Car!
    
    lazy var dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale(identifier: "ru_RU")
        df.setLocalizedDateFormatFromTemplate("dd.MM.yyyy")
        return df
    }()
    
    @IBOutlet weak var segmentedControl: UISegmentedControl! {
        didSet {
            
            if let isDataLoaded = UserDefaults.standard.value(forKey: "isDataLoaded") as? Bool, !isDataLoaded {
                getDataFromFile()
                UserDefaults.standard.set(true, forKey: "isDataLoaded")
                UserDefaults.standard.synchronize()
            } else {
                updateUI(segmentedControlIndex: segmentedControl.selectedSegmentIndex)
            }
            
            let whiteTitleTextAttribute = [NSAttributedString.Key.foregroundColor: UIColor.white]
            let blackTitleTextAttribute = [NSAttributedString.Key.foregroundColor: UIColor.black]
            
            UISegmentedControl.appearance().setTitleTextAttributes(whiteTitleTextAttribute, for: .normal)
            UISegmentedControl.appearance().setTitleTextAttributes(blackTitleTextAttribute, for: .selected)
        }
    }
    @IBOutlet weak var markLabel: UILabel!
    @IBOutlet weak var modelLabel: UILabel!
    @IBOutlet weak var carImageView: UIImageView!
    @IBOutlet weak var lastTimeStartedLabel: UILabel!
    @IBOutlet weak var numberOfTripsLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var myChoiceImageView: UIImageView!
    
    @IBAction func segmentedCtrlPressed(_ sender: UISegmentedControl) {
        updateUI(segmentedControlIndex: sender.selectedSegmentIndex)
    }
    
    @IBAction func startEnginePressed(_ sender: UIButton) {
        car.timesDriven += 1
        car.lastStarted = Date()
        saveContext()
        insertDataFrom(selectedCar: car)
    }
    
    @IBAction func rateItPressed(_ sender: UIButton) {
        let alertController = UIAlertController(title: "Rate it", message: "Rate this car please", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default) { _ in
            if let rating = alertController.textFields?.first?.text {
                self.updateRating(rating: (rating as NSString).floatValue)
            }
        }
        alertController.addTextField { tf in
            tf.keyboardType = .numberPad
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func myChoicePressed(_ sender: Any) {
        changeChoice()
    }
    
    private func updateRating(rating: Float) {
        car.rating = rating
        
        do {
            try context.save()
            insertDataFrom(selectedCar: car)
        } catch let error as NSError {
            let alertController = UIAlertController(title: "Wrong value", message: "Wrong input", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alertController.addAction(okAction)
            present(alertController, animated: true, completion: nil)
            print(error.localizedDescription)
        }
    }
    
    private func getDataFromFile() {
        
        var dataArray = [[String: Any]]()
        if let path = Bundle.main.url(forResource: "data", withExtension: "plist") {
            do {
                let dataPlistData = try Data(contentsOf: path)
                
                if let arr = try PropertyListSerialization.propertyList(from: dataPlistData, options: [], format: nil) as? [[String: Any]] {
                    dataArray = arr
                }
            } catch {
                print(error)
            }
        }
                
        for carDictionary in dataArray {
            let car = Car(context: context)
            
            car.mark = carDictionary["mark"] as? String
            car.model = carDictionary["model"] as? String
            car.rating = carDictionary["rating"] as! Float
            car.lastStarted = carDictionary["lastStarted"] as? Date
            car.timesDriven = carDictionary["timesDriven"] as! Int16
            car.myChoice = carDictionary["myChoice"] as! Bool
            
            if let imageName = carDictionary["imageName"] as? String, let image = UIImage(named: imageName) {
                let imageData = image.pngData()
                car.imageData = imageData
            }
            
            if let colorDictionary = carDictionary["tintColor"] as? [String: Float] {
                car.tintColor = getColor(colorDictionary: colorDictionary)
            }
        }
        
        saveContext()
    }
    
    private func getColor(colorDictionary: [String: Float]) -> UIColor {
        guard let red = colorDictionary["red"], let green = colorDictionary["green"], let blue = colorDictionary["blue"] else { return UIColor() }
        return UIColor(red: CGFloat(red / 255), green: CGFloat(green / 255), blue: CGFloat(blue / 255), alpha: 1.0)
    }
    
    private func insertDataFrom(selectedCar: Car) {
        if let imageData = selectedCar.imageData, let image = UIImage(data: imageData) {
            carImageView.image = image
        }
        markLabel.text = selectedCar.mark
        modelLabel.text = selectedCar.model
        myChoiceImageView.isHidden = !selectedCar.myChoice
        ratingLabel.text = "Rating: \(selectedCar.rating) / 10"
        numberOfTripsLabel.text = "Number of trips: \(selectedCar.timesDriven)"
        
        if let date = selectedCar.lastStarted {
            lastTimeStartedLabel.text = "Last time started: \(dateFormatter.string(from: date))"
        }
        segmentedControl.backgroundColor = selectedCar.tintColor as? UIColor
    }
    
    private func updateUI(segmentedControlIndex: Int) {
        let fetchRequest: NSFetchRequest<Car> = Car.fetchRequest()
        let mark = segmentedControl.titleForSegment(at: segmentedControlIndex)
        fetchRequest.predicate = NSPredicate(format: "mark == %@", mark!)
        
        do {
            let results = try context.fetch(fetchRequest)
            car = results.first
            insertDataFrom(selectedCar: car!)
        } catch let error as NSError {
            print(error)
        }
    }
    
    private func changeChoice() {
        let fetchRequest: NSFetchRequest<Car> = Car.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "myChoice == true")
        
        do {
            let resultCar = try context.fetch(fetchRequest)
            resultCar.first?.myChoice = false
            car.myChoice = true
            insertDataFrom(selectedCar: car)
            saveContext()
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
    private func saveContext() {
        do {
            try context.save()
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
}

