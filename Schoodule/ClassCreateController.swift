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

class ClassCreateController: FormViewController {
    
    // schedule and couOrse being made from the controller
    var initialSchedule: Schedule?
    var initialCourse: Course?
    
    private var scheduleTypes = ["Everyday", "Weekdays", "Weekends", "Specific Day", "Even Days", "Odd Days"]
    private var avaiableDays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    private var scheduleNames: [String] {
        return ["New Schedule...", "Everyday"] + scheduleList.schedules.compactMap { $0.name }
    }
    
    // editable list of schedules that gets passed back to root view
    var scheduleList: ScheduleList!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let newScheduleCondition = Condition.function(["schedule-name"], { form in
            return ((form.rowBy(tag: "schedule-name") as? PickerRow)?.value ?? "") != "New Schedule..."
        })
        let scheduleTypeCondition = Condition.function(["schedule-type"], { form in
            return ((form.rowBy(tag: "schedule-type") as? PickerInlineRow)?.value ?? "") != "Specific Day"
        })
        
        form +++ Section("Course")
            <<< TextRow() { row in
                row.tag = "course-name"
                row.title = "Name"
                row.placeholder = "Physics"

                if let courseName = initialCourse?.name {
                    row.value = courseName
                }
            }
            <<< TextRow() {
                $0.tag = "course-ocation"
                $0.title = "Location"
                $0.placeholder = "Room 102"
                
                if let courseName = initialCourse?.location {
                    $0.value = courseName
                }
            }
            <<< TimeInlineRow() {
                $0.tag = "start-time"
                $0.minuteInterval = 5
                $0.title = "Start Time"

                if let courseStartDate = initialCourse?.timeframe.start.date {
                    $0.value = courseStartDate
                } else {
                    $0.value = Date()
                }
            }
            <<< TimeInlineRow() {
                $0.tag = "end-time"
                $0.minuteInterval = 5
                $0.title = "End Time"
                
                if let courseEndDate = initialCourse?.timeframe.end.date {
                    $0.value = courseEndDate
                } else {
                    $0.value = Date().addingTimeInterval(2700)
                }
            }
            +++ Section("Schedule")
            <<< PickerRow<String>() {
                $0.tag = "schedule-name"
                $0.options = scheduleNames
                $0.value = "New Schedule..."
                }.cellSetup({ (cell, row) in
                    cell.height = {
                        return 100
                    }
                })
            
            <<< PickerInlineRow<String>() {
                $0.tag = "schedule-type"
                $0.title = "Type"
                $0.options = scheduleTypes
                $0.hidden = newScheduleCondition
                
                if let scheduleType = initialSchedule?.scheduleType {
                    $0.value = scheduleType.title
                }
            }
            <<< SegmentedRow<String>() {
                $0.options = avaiableDays
                $0.value = "Mon"
                $0.tag = "segmented-days"
                $0.hidden = scheduleTypeCondition
            }
            <<< DateInlineRow() {
                $0.tag = "start-date"
                $0.title = "Start Date"
                $0.hidden = newScheduleCondition

                if let scheduleStartDate = initialSchedule?.term.start {
                    $0.value = scheduleStartDate
                } else {
                    $0.value = Date()
                }
            }
            <<< DateInlineRow() {
                $0.tag = "end-date"
                $0.title = "End Date"
                $0.value = Date()
                $0.hidden = newScheduleCondition

                if let scheduleEndDate = initialSchedule?.term.end {
                    $0.value = scheduleEndDate
                } else {
                    $0.value = Date()
                }
                }.cellUpdate({ (cell, row) in
                    for view in cell.contentView.subviews {
                        view.backgroundColor = .clear
                    }
                })
        
        for row in form.allRows {
            row.baseCell.backgroundColor = .clear
        }
        for view in self.view.subviews {
            if let tableView = view as? UITableView {
                //tableView.backgroundColor = UIColor.lightGray
            }
        }
    }
    
    func presentMissingInfoAlert(input: String) {
        let alertView = SCLAlertView(appearance: SCLAlertView.SCLAppearance())
        alertView.showError("Missing Information", subTitle: "Please input the \(input).")
    }
    
    @IBAction func save(_ sender: UIBarButtonItem) {
        let handler = ScheduleFormHandler(form: form)
        handler.handleSave()
        
        if !handler.canSave {
            return
        }
        
        let courseNameRow: TextRow = form.rowBy(tag: "course-name")!
        let locationRow: TextRow = form.rowBy(tag: "course-location")!
        let startTimeRow: TimeInlineRow = form.rowBy(tag: "start-time")!
        let endTimeRow: TimeInlineRow = form.rowBy(tag: "end-time")!
        
        let scheduleNameRow: PickerInlineRow<String> = form.rowBy(tag: "schedule-name")!
        
        if scheduleNameRow.value == "New Schedule..." {
            
        } else {
            
        }
        
        let scheduleTypeRow: PickerInlineRow<String> = form.rowBy(tag: "schedule-type")!
        let startDateRow: DateInlineRow = form.rowBy(tag: "start-date")!
        let endDateRow: DateInlineRow = form.rowBy(tag: "end-date")!
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
        let course = Course(name: courseName, themeIndex: 0, timeframe: timeframe, location: locationRow.value)
        let term = Term(start: startDateRow.value!, end: endDateRow.value!)
        
        let scheduleType: ScheduleType
        switch scheduleTypeString {
        case "Everyday":
            scheduleType = SpecificDay(days: Day.everyday)
        case "Weekdays":
            scheduleType = SpecificDay(days: Day.weekdays)
        case "Weekends":
            scheduleType = SpecificDay(days: Day.weekends)
        case "Even Days":
            scheduleType = EvenDay(startDate: startDateRow.value!)
        case "Odd Days":
            scheduleType = OddDay(startDate: startDateRow.value!)
        case "Specific Day":
            scheduleType = SpecificDay(days: [.monday])
        default:
            return
        }
        
        // TODO: Time Checks, Date Checks and make red if time is wrong

//        // remove oldSchedule and replace with same schedule but without the initial course
//        if var oldSchedule = self.initialSchedule, let index = scheduleList.schedules.firstIndex(of: oldSchedule) {
//            oldSchedule.classList.remove(element: initialCourse)
//            scheduleList.schedules[index] = oldSchedule
//        }
//
//        var newSchedule: Schedule
//        if let foundSchedule = scheduleList.getScheduleWith(scheduleType: scheduleType, term: term) {
//            // if found, remove from scheduleList to be replaced with new one
//            scheduleList.schedules.remove(element: foundSchedule)
//            newSchedule = foundSchedule
//        } else {
//            newSchedule = Schedule(scheduleType: scheduleType, term: term)
//        }
//
//        if let schedule = initialSchedule, schedule.classList.count == 1 {
//            scheduleList.schedules.remove(element: initialSchedule)
//        }
//
//        newSchedule.classList.append(course)
//        scheduleList.schedules.append(newSchedule)
//
//        if let root = navigationController?.viewControllers[0] as? MainTableViewController {
//            root.storage.scheduleList = scheduleList
//        }
//
//        navigationController?.popViewController(animated: true)
    }
    
}


