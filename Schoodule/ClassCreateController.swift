//
//  ClassCreateController.swift
//  Schoodule
//
//  Created by Nicholas Grana on 5/4/18.
//  Copyright © 2018 Nicholas Grana. All rights reserved.
//

import UIKit 

class ClassCreateController: UIViewController, UIPickerViewDataSource {
    
    @IBOutlet var nameField: UITextField!
    @IBOutlet var locationField: UITextField!
    @IBOutlet var startTimeSelector: UIDatePicker!
    @IBOutlet var endTimeSelector: UIDatePicker!
    @IBOutlet var colorIndexPicker: UIPickerView!
    @IBOutlet var startDateSelector: UIDatePicker!
    @IBOutlet var endDateSelector: UIDatePicker!
    
    var scheduleList: ScheduleList = ScheduleList()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        colorIndexPicker.dataSource = self
    }
    
    @IBAction func save(_ sender: UIBarButtonItem) {
        let timeframe = Timeframe(start: Time(from: startTimeSelector.date), end: Time(from: endTimeSelector.date))
        let period = Class(name: nameField.text!, themeIndex: 0, timeframe: timeframe, location: nil)

        let dateframe = SpecificDay(days: [.monday, .tuesday])
        
        // let schedulesToAdd = scheduleList.getSchedulesWith(timeConstraints: [dateframe])
            
        var schedule = Schedule()
        schedule.setConstraints([dateframe])
        schedule.append(new: period)
        // scheduleList.schedules.append(schedule)
        
        for c in navigationController!.viewControllers {
            if c is MainTableViewController {
                (c as! MainTableViewController).storage.scheduleList.schedules.append(schedule)
            }
        }

        navigationController?.popViewController(animated: true)
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return UIColor.themes.count
    }
}