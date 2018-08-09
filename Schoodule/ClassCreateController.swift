//
//  ClassCreateController.swift
//  Schoodule
//
//  Created by Nicholas Grana on 5/4/18.
//  Copyright © 2018 Nicholas Grana. All rights reserved.
//

import UIKit
import Eureka
import SCLAlertView
import ColorPickerRow
import UIColor_Hex_Swift

class ClassCreateController: FormViewController {
    
    var initialSchedule: Schedule?
    var initialCourse: Course?
    
    var gradient: Gradient! {
        didSet {
            tableView.backgroundColor = gradient.darkColor.withAlphaComponent(0.8)
            navigationController?.navigationBar.barTintColor = gradient.darkColor
        }
    }
    
    private var scheduleTypes = ["Everyday", "Weekdays", "Specific Day", "Even Days", "Odd Days"]
    private var avaiableDays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    private var scheduleNames: [String] {
        return ["New Schedule...", "Everyday"] + scheduleList.schedules.compactMap { $0.title }
    }
    
    // editable list of schedules that gets passed back to root view
    var scheduleList: ScheduleList!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        gradient = initialCourse?.gradient ?? Gradient.gradients.first!
        
        let scheduleTypeCondition = Condition.function(["schedule-type"], { form in
            return ((form.rowBy(tag: "schedule-type") as? PickerRow)?.value ?? "") != "Specific Day"
        })
        
        
        
        form +++ Section("Course")
            <<< TextRow() { row in
                row.tag = "course-name"
                row.title = "Name"
                row.placeholder = "Physics"
                
                if let courseName = initialCourse?.name {
                    row.value = courseName
                }
                }.cellUpdate({ (cell, row) in
                    cell.titleLabel?.textColor = .white
                })
            <<< TextRow() {
                $0.tag = "course-instructor"
                $0.title = "Instructor"
                $0.placeholder = "Mr Hew"
                
                if let courseInstructor = initialCourse?.instructor {
                    $0.value = courseInstructor
                }
                }.cellUpdate({ (cell, row) in
                    cell.titleLabel?.textColor = .white
                })
            <<< TextRow() {
                $0.tag = "course-location"
                $0.title = "Location"
                $0.placeholder = "Room 102"
                
                if let courseName = initialCourse?.location {
                    $0.value = courseName
                }
                }.cellUpdate({ (cell, row) in
                    cell.titleLabel?.textColor = .white
                })
            <<< TimeRow() {
                $0.tag = "start-time"
                $0.minuteInterval = 5
                $0.title = "Start Time"
                
                if let courseStartDate = initialCourse?.timeframe.start.date {
                    $0.value = courseStartDate
                } else {
                    $0.value = Date()
                }
                }.cellUpdate({ (cell, row) in
                    cell.textLabel?.textColor = .white
                })
            <<< TimeRow() {
                $0.tag = "end-time"
                $0.minuteInterval = 5
                $0.title = "End Time"
                
                if let courseEndDate = initialCourse?.timeframe.end.date {
                    $0.value = courseEndDate
                } else {
                    $0.value = Date().addingTimeInterval(2700)
                }
                }.cellUpdate({ (cell, row) in
                    cell.textLabel?.textColor = .white
                })
            +++ Section("Schedule")
            <<< PickerInlineRow<String>() {
                $0.tag = "schedule-type"
                $0.title = "Type"
                $0.options = scheduleTypes
                
                if let scheduleType = initialSchedule?.scheduleType {
                    $0.value = scheduleType.title
                }
                }.cellUpdate({ (cell, row) in
                    cell.textLabel?.textColor = .white
                })
            <<< SegmentedRow<String>() {
                $0.options = avaiableDays
                $0.value = "Mon"
                $0.tag = "segmented-days"
                $0.hidden = scheduleTypeCondition
            }
            <<< DateRow() {
                $0.tag = "start-date"
                $0.title = "Start Date"
                
                if let scheduleStartDate = initialSchedule?.term.start {
                    $0.value = scheduleStartDate
                } else {
                    $0.value = Date()
                }
                }.cellUpdate({ (cell, row) in
                    cell.textLabel?.textColor = .white
                })
            <<< DateRow() {
                $0.tag = "end-date"
                $0.title = "End Date"
                $0.value = Date()
                
                if let scheduleEndDate = initialSchedule?.term.end {
                    $0.value = scheduleEndDate
                } else {
                    $0.value = Date()
                }
                }.cellUpdate({ (cell, row) in
                    cell.textLabel?.textColor = .white
                })
            <<< ColorPickerRow("colors") { (row) in
                row.title = "Color"
                row.isCircular = true
                row.showsCurrentSwatch = true
                row.showsPaletteNames = false
                row.value = gradient.darkColor
                }
                .cellSetup { (cell, row) in
                    cell.palettes = [ColorPalette(name: "All", palette: Gradient.gradients.map { ColorSpec(hex: $0.darkColor.hexString(), name: "") })]
                }.onChange({ (picker) in
                    guard let newDarkColor = picker.value else {
                        return
                    }
                    
                    for grad in Gradient.gradients {
                        if grad.darkColor == newDarkColor {
                            self.gradient = grad
                        }
                    }
                }).cellUpdate({ (cell, row) in
                    cell.textLabel?.textColor = .white
                })
        
        for row in form.allRows {
            row.baseCell.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        }
        
        self.view.backgroundColor = .white
        tableView.separatorColor = .clear
    }
    
    func presentMissingInfoAlert(input: String) {
        let alertView = SCLAlertView(appearance: SCLAlertView.SCLAppearance())
        alertView.showError("Missing Information", subTitle: "Please input the \(input).")
    }
    
    @IBAction func save(_ sender: UIButton) {
        save()
    }
    
    func save() {
        let handler = ScheduleFormHandler(form: form)
        handler.handleSave()
        
        if !handler.canSave {
            return
        }
        
        let courseNameRow: TextRow = form.rowBy(tag: "course-name")!
        let instructorRow: TextRow = form.rowBy(tag: "course-instructor")!
        let locationRow: TextRow = form.rowBy(tag: "course-location")!
        let startTimeRow: TimeRow = form.rowBy(tag: "start-time")!
        let endTimeRow: TimeRow = form.rowBy(tag: "end-time")!
        let scheduleTypeRow: PickerInlineRow<String> = form.rowBy(tag: "schedule-type")!
        let startDateRow: DateRow = form.rowBy(tag: "start-date")!
        let endDateRow: DateRow = form.rowBy(tag: "end-date")!
        let specificDaysPicker: SegmentedRow<String> = form.rowBy(tag: "segmented-days")!
        
        // TODO: make sure name, location, starttime and end time values are not nil & custom alert view
        guard let courseName = courseNameRow.value else {
            presentMissingInfoAlert(input: "course name")
            return
        }
        
        guard let scheduleTypeString = scheduleTypeRow.value else {
            presentMissingInfoAlert(input: "schedule type")
            return
        }
        
        let timeframe = Timeframe(start: Time(from: startTimeRow.value!), end: Time(from: endTimeRow.value!))
        let course = Course(name: courseName, gradient: gradient, timeframe: timeframe, teacher: instructorRow.value, location: locationRow.value)
        let term = Term(start: startDateRow.value!, end: endDateRow.value!)
        
        guard let scheduleType = SpecificDay.scheduleFromValue(scheduleTypeRow.value!, startDateRow.value) else {
            return
        }
        
        // TODO: Time Checks, Date Checks and make red if time is wrong
        
        // remove oldSchedule and replace with same schedule but without the initial course
        if var oldSchedule = self.initialSchedule, let index = scheduleList.schedules.firstIndex(of: oldSchedule) {
            oldSchedule.classList.remove(element: initialCourse)
            scheduleList.schedules[index] = oldSchedule
        }
        
        var newSchedule: Schedule
        if let foundSchedule = scheduleList.getScheduleWith(scheduleType: scheduleType, term: term) {
            // if found, remove from scheduleList to be replaced with new one
            scheduleList.schedules.remove(element: foundSchedule)
            newSchedule = foundSchedule
        } else {
            newSchedule = Schedule(scheduleType: scheduleType, term: term)
        }
        
        if let schedule = initialSchedule, schedule.classList.count == 1 {
            scheduleList.schedules.remove(element: initialSchedule)
        }
        
        newSchedule.classList.append(course)
        scheduleList.schedules.append(newSchedule)
        
        if let root = navigationController?.viewControllers.first as? MainTableViewController {
            root.storage.scheduleList = scheduleList
        }
        
        navigationController?.popViewController(animated: true)
    }
}


