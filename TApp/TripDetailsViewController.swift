//
//  TripDetailsViewController.swift
//  TApp
//
//  Created by Zack Hurwitz on 5/5/18.
//  Copyright © 2018 Liam Breen. All rights reserved.
//

import UIKit
import SnapKit
import SwiftyJSON
import Alamofire
import BrightFutures
import YelpAPI

class TripDetailsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UpdateTripDelegate {
    
    func updateTrip(trip: Trip, number: Int) {
        self.trip = trip
        self.tripNumber = number
        updateTripDelegate.updateTrip(trip: trip, number: number)
    }
    
    var updateTripDelegate: UpdateTripDelegate!
    var trip: Trip!
    var tripNumber: Int!
    var editButton: UIButton!
    var doneButton: UIButton!
    var restSuggestionsButton: UIButton!
    
    var tableView: UITableView!
    
    var days: [Int] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        title = trip.startLocation + " -> " + trip.endLocation
        
        editButton = UIButton()
        editButton.setTitle("Edit Trip", for: .normal)
        editButton.setTitleColor(niceColor, for: .normal)
        editButton.titleLabel?.font = UIFont.systemFont(ofSize: 24)
        editButton.addTarget(self, action: #selector(editButtonPressed), for: .touchUpInside)
        
        doneButton = UIButton()
        doneButton.setTitle("Done", for: .normal)
        doneButton.setTitleColor(niceColor, for: .normal)
        doneButton.titleLabel?.font = UIFont.systemFont(ofSize: 24)
        doneButton.addTarget(self, action: #selector(doneButtonPressed), for: .touchUpInside)
        
        restSuggestionsButton = UIButton()
        restSuggestionsButton.setTitle("Restaurant Suggestions", for: .normal)
        restSuggestionsButton.setTitleColor(niceColor, for: .normal)
        restSuggestionsButton.titleLabel?.font = UIFont.systemFont(ofSize: 24)
        restSuggestionsButton.titleLabel?.numberOfLines = 0
        restSuggestionsButton.titleLabel?.textAlignment = .center
        restSuggestionsButton.addTarget(self, action: #selector(restSuggestionsButtonPressed), for: .touchUpInside)
        
        view.addSubview(editButton)
        view.addSubview(doneButton)
        view.addSubview(restSuggestionsButton)
        
        var interval = self.trip.endDate.timeIntervalSince(self.trip.startDate)
        var numdays = 0
        
        while interval > 0 {
            interval = interval - 86400
            numdays = numdays + 1
            days.append(numdays)
        }
        
        tableView = UITableView()
        tableView.bounces = true
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "tableCell")
        tableView.backgroundColor = .white
        tableView.tableFooterView = UIView()
        tableView.allowsSelection = false
        
        tableView.dataSource = self
        tableView.delegate = self
        
        view.addSubview(tableView)
        
        //yelpSearch()
        
        setupConstraints()
    }

    func setupConstraints() {
        editButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.trailing.equalToSuperview().offset(-16)
            make.width.equalTo(0).offset(editButton.intrinsicContentSize.width)
        }
        
        doneButton.snp.makeConstraints { make in
            make.top.equalTo(editButton.snp.top)
            make.leading.equalToSuperview().offset(16)
        }
        
        restSuggestionsButton.snp.makeConstraints { make in
            make.top.equalTo(editButton.snp.top).offset(8)
            make.centerX.equalToSuperview()
            make.leading.equalTo(doneButton.snp.trailing).offset(2)
            make.trailing.equalTo(editButton.snp.leading).offset(-2)
        }
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: editButton.bottomAnchor, constant: 24),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
    }
    
    @objc func restSuggestionsButtonPressed() {
        let makeVC = MakeScheduleViewController()
        self.updateTripDelegate = makeVC
        updateTripDelegate.updateTrip(trip: trip, number: tripNumber)
        
        navigationController?.pushViewController(makeVC, animated: true)
    }
    
    @objc func editButtonPressed() {
        let editVC = EditTripViewController()
        editVC.trip = trip
        editVC.tripNumber = tripNumber
        editVC.updateTripDelegate = self
        present(editVC, animated: true, completion: nil)
    }
    
    @objc func doneButtonPressed() {
        updateTripDelegate.updateTrip(trip: trip, number: tripNumber)
        dismiss(animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return days.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "tableCell")
        let day: Date = Date(timeInterval: TimeInterval(86400 * indexPath.row), since: trip.startDate)
        cell!.textLabel!.text = dateDescriptionModifier(description: String(describing: day))
        cell?.textLabel?.textColor = backgroundOrange
        cell?.textLabel?.textAlignment = .center
        cell?.textLabel?.font = UIFont.systemFont(ofSize: 54)
        cell?.backgroundColor = .white
        cell!.setNeedsUpdateConstraints()
        return cell!
    }
    
    
    func yelpSearch () {
        
        CDYelpFusionKitManager.shared.apiClient.searchBusinesses(byTerm: "Food",
                                                                 location: "San Francisco",
                                                                 latitude: nil,
                                                                 longitude: nil,
                                                                 radius: 10000,
                                                                 categories: nil,
                                                                 locale: .english_unitedStates,
                                                                 limit: 5,
                                                                 offset: 0,
                                                                 sortBy: .rating,
                                                                 priceTiers: nil,
                                                                 openNow: true,
                                                                 openAt: nil,
                                                                 attributes: nil) { (response) in

                                                                    if let response = response,
                                                                        let businesses = response.businesses,
                                                                        businesses.count > 0 {
                                                                        for business in businesses {
                                                                            print(business.name)
                                                                        }
                                                                    }
        }
    }
    
    func dateDescriptionModifier(description: String) -> String {
        print(description)
        let year: String = description.substring(to: description.index(of: "-")!)
        print(year)
        let monthIndex = description.index(description.startIndex, offsetBy: 5)
        let endIndex = description.index(description.startIndex, offsetBy: 2)
        let month: String = description.substring(from: monthIndex).substring(to: endIndex)
        print(month)
        let dayIndex = description.index(description.startIndex, offsetBy: 8)
        let day: String = description.substring(from: dayIndex).substring(to: endIndex)
        print(day)
        return "\(month)/\(day)/\(year)"
    }
    
}
