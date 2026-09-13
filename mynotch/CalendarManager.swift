//
//  CalendarManager.swift
//  mynotch
//

import Foundation
import SwiftUI
import AppKit
import Combine
import EventKit

struct DayItem: Identifiable {
    let id = UUID()
    let date: Date
    let dayOfWeek: String
    let dayNumber: String
    let isToday: Bool
}

final class CalendarManager: ObservableObject {
    static let shared = CalendarManager()
    
    @Published var monthName: String = ""
    @Published var days: [DayItem] = []
    @Published var selectedDay: Date = Date()
    @Published var todayEventsText: String = "Loading events..."
    
    private var timer: Timer?
    private let eventStore = EKEventStore()
    
    private init() {
        refreshCalendar()
        requestAccessAndFetchEvents()
        
        // Refresh every minute to keep current
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.refreshCalendar()
            self?.fetchTodayEvents()
        }
    }
    
    private func requestAccessAndFetchEvents() {
        if #available(macOS 14.0, *) {
            eventStore.requestFullAccessToEvents { [weak self] granted, error in
                DispatchQueue.main.async {
                    if granted {
                        self?.fetchTodayEvents()
                    } else {
                        self?.todayEventsText = "Calendar access denied"
                    }
                }
            }
        } else {
            eventStore.requestAccess(to: .event) { [weak self] granted, error in
                DispatchQueue.main.async {
                    if granted {
                        self?.fetchTodayEvents()
                    } else {
                        self?.todayEventsText = "Calendar access denied"
                    }
                }
            }
        }
    }
    
    private func fetchTodayEvents() {
        guard EKEventStore.authorizationStatus(for: .event) == .fullAccess || EKEventStore.authorizationStatus(for: .event) == .authorized else {
            todayEventsText = "No calendar access"
            return
        }
        
        let calendar = Calendar.current
        let today = Date()
        let startOfDay = calendar.startOfDay(for: today)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return }
        
        let predicate = eventStore.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: nil)
        let events = eventStore.events(matching: predicate)
        
        // Filter out all-day events if preferred, or keep them
        let activeEvents = events.filter { !$0.isAllDay }
        
        if activeEvents.isEmpty {
            todayEventsText = "Nothing for today"
        } else {
            // Find the next upcoming event
            let upcoming = activeEvents.first { $0.startDate > today } ?? activeEvents.first!
            
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            let timeStr = formatter.string(from: upcoming.startDate)
            
            todayEventsText = "\(upcoming.title ?? "Event") at \(timeStr)"
        }
    }
    
    func refreshCalendar() {
        let calendar = Calendar.current
        let today = Date()
        
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMM"
        self.monthName = monthFormatter.string(from: today)
        
        var generatedDays: [DayItem] = []
        // Generate 7 days centered on today (-3 days to +3 days)
        for offset in -3...3 {
            if let date = calendar.date(byAdding: .day, value: offset, to: today) {
                let isToday = calendar.isDateInToday(date)
                
                let dayFormatter = DateFormatter()
                dayFormatter.dateFormat = isToday ? "EEE" : "EEEEE" // "SUN" for today, "T", "F", "S" for others
                let dayOfWeek = dayFormatter.string(from: date).uppercased()
                
                let numFormatter = DateFormatter()
                numFormatter.dateFormat = "d"
                let dayNumber = numFormatter.string(from: date)
                
                generatedDays.append(DayItem(
                    date: date,
                    dayOfWeek: dayOfWeek,
                    dayNumber: dayNumber,
                    isToday: isToday
                ))
            }
        }
        self.days = generatedDays
    }
    
    func openCalendarApp() {
        HapticFeedback.lightTap()
        if let url = URL(string: "ical://") {
            NSWorkspace.shared.open(url)
        } else {
            NSWorkspace.shared.openApplication(
                at: URL(fileURLWithPath: "/System/Applications/Calendar.app"),
                configuration: NSWorkspace.OpenConfiguration()
            )
        }
    }
}
