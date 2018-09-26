//
//  SchooduleComplicationController.swift
//  Schoodule
//
//  Created by Nicholas Grana on 1/28/18.
//  Copyright © 2018 Nicholas Grana. All rights reserved.
//

import ClockKit

class SchooduleComplicationController: NSObject, CLKComplicationDataSource {
    
    //let initialClassWarning: TimeInterval = -3600
    
    var storage: Storage {
        return ExtensionDelegate.storage
    }
    
    var todaySchedule: [Course] {
        return storage.schedule.todayCourses
    }
    
    var sortedSchedule: [Course] {
        return todaySchedule.sorted()
    }
    
    var scheduleStart: Date? {
        return sortedSchedule.first?.event.startDate
    }
    
    var scheduleEnd: Date? {
        return sortedSchedule.last?.event.endDate
    }
    
    // given a date and compliation type, this will send back the current complication template
    func complicationTemplate(_ complication: CLKComplication, from date: Date? = nil) -> CLKComplicationTemplate? {
        print("UPDATING COMPLICATIONS")
        
        var complicationType: ComplicationStore.PeriodComplication = .blank
        var dateProvider: CLKRelativeDateTextProvider? = nil
        var courseProvider: Course? = nil
        var location: String? = nil
        
        if let date = date {
            if let course = storage.schedule.classFrom(date: date) {
                
                dateProvider = CLKRelativeDateTextProvider(date: course.event.endDate, style: .naturalAbbreviated, units: [.minute, .hour])
                courseProvider = course
                complicationType = .current
                
            } else if let nextClass = storage.schedule.nextClassFrom(date: date) {
                let nextClassIndex = sortedSchedule.firstIndex(of: nextClass)
                
                if nextClassIndex == 0 {
                    
                    dateProvider = CLKRelativeDateTextProvider(date: nextClass.event.startDate, style: .naturalAbbreviated, units: [.minute, .hour])
                    complicationType = .first
                    location = nextClass.event.location
                    
                } else if nextClassIndex == todaySchedule.count - 1 {
                    
                    dateProvider = CLKRelativeDateTextProvider(date: nextClass.event.startDate, style: .naturalAbbreviated, units: [.minute, .hour])
                    complicationType = .last
                    location = nextClass.event.location
                    
                } else {
                    
                    dateProvider = CLKRelativeDateTextProvider(date: nextClass.event.startDate, style: .naturalAbbreviated, units: [.minute, .hour])
                    complicationType = .next
                    location = nextClass.event.location
                    
                }
            }
        }

        return ComplicationStore(family: complication.family, course: courseProvider, dateProvider: dateProvider, location: location, type: complicationType).template
    }
    
    
    
    
    
    
    // MARK: Time Travel Support
    
    // supports backwards and forwards for seeing schedule
    func getSupportedTimeTravelDirections(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimeTravelDirections) -> Void) {
        handler([.backward, .forward])
    }
    
    // block time travel for anything after the last schedule entry
    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        handler(scheduleEnd?.addingTimeInterval(62))
    }
    
    // block time travel for anything before the start of the schedule
    func getTimelineStartDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        handler(nil)
       //handler(scheduleStart?.addingTimeInterval(-62))
    }
    
    

    
    
    
    // MARK: Timeline Creation
    
    // returns the sample template with default values when first installing complication
    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        handler(ComplicationStore(family: complication.family, course: nil, dateProvider: nil, location: "Location", type: .placeholder).template)
    }
    
    // returns the template for the current date
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void)
    {
        // send current template as long as it is within range of the schedule, otherwise send a blank one
        let now = Date()

        if let template = complicationTemplate(complication, from: now), let end = scheduleEnd, let start = scheduleStart, now > start && now < end {
            if let course = storage.schedule.classFrom(date: Date()) {
                handler(CLKComplicationTimelineEntry(date: course.event.startDate, complicationTemplate: template))
            } else {
                handler(CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template))
            }
        } else {
            handler(CLKComplicationTimelineEntry(date: Date(), complicationTemplate: complicationTemplate(complication)!))
        }
        
    }
    
    // gets all the entries before the date
    func getTimelineEntries(for complication: CLKComplication, before date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        allTimelineEntries(complication: complication, for: date, handler: handler, with: >, sendNext: false)
    }
    
    // gets all the entries after the date
    func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        allTimelineEntries(complication: complication, for: date, handler: handler, with: <, sendNext: true)
    }
    
    func allTimelineEntries(complication: CLKComplication, for date: Date, handler: ([CLKComplicationTimelineEntry]?) -> Void, with comparision: ((Date, Date) -> Bool), sendNext: Bool) {
        var timelineEntires = [CLKComplicationTimelineEntry]()
        print(#function)
        guard let scheduleStart = self.scheduleStart, let scheduleEnd = self.scheduleEnd else {
            return
        }
        
        if comparision(date, scheduleStart.addingTimeInterval(-61)) {
            // adds start entry to disable timer when it goes before
            timelineEntires.append(CLKComplicationTimelineEntry(date: scheduleStart.addingTimeInterval(-61), complicationTemplate: complicationTemplate(complication)!))
        }
        if comparision(date, scheduleStart) {
            // first class
            timelineEntires.append(CLKComplicationTimelineEntry(date: scheduleStart, complicationTemplate: complicationTemplate(complication, from: scheduleStart)!))
        }
        
        for course in sortedSchedule {
            let current = storage.schedule.classFrom(date: Date())
            
            if let template = complicationTemplate(complication, from: course.event.startDate) {
                if (!comparision(date, course.event.startDate) && !comparision(date, course.event.endDate)) {

                    if sendNext && current == course {
                        if scheduleEnd != course.event.endDate {
                            // do not add class, but add next class entry
                            let nextClassTimelineEntry = CLKComplicationTimelineEntry(date: course.event.endDate, complicationTemplate: complicationTemplate(complication, from: course.event.endDate.addingTimeInterval(5))!)
                            timelineEntires.append(nextClassTimelineEntry)
                        }
                    }

                    continue
                }
                
                let timelineEntry: CLKComplicationTimelineEntry
                
                timelineEntry = CLKComplicationTimelineEntry(date: course.event.startDate, complicationTemplate: template)
                timelineEntires.append(timelineEntry)
                
                // if not the last class, put an entry to tell the time until the next class
                if scheduleEnd != course.event.endDate {
                    let nextClassTimelineEntry = CLKComplicationTimelineEntry(date: course.event.endDate, complicationTemplate: complicationTemplate(complication, from: course.event.endDate.addingTimeInterval(5))!)
                    timelineEntires.append(nextClassTimelineEntry)
                }
            } else {
                continue
            }
        }
        
        if comparision(date, scheduleEnd.addingTimeInterval(61)) {
            // adds final entry to disable timer when it goes past
            timelineEntires.append(CLKComplicationTimelineEntry(date: scheduleEnd.addingTimeInterval(61), complicationTemplate: complicationTemplate(complication)!))
        }
        
        handler(timelineEntires)
    }

}

