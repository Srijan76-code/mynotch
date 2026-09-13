//
//  CalendarWidgetView.swift
//  mynotch
//

import SwiftUI

struct CalendarWidgetView: View {
    @ObservedObject var calendarManager = CalendarManager.shared
    @State private var isHovered = false
    
    var body: some View {
        Button(action: {
            calendarManager.openCalendarApp()
        }) {
            VStack(alignment: .leading, spacing: 8) {
                // Month Header + 7-day horizontal strip
                HStack(alignment: .center, spacing: 10) {
                    // Month Name (e.g. "Sep")
                    Text(calendarManager.monthName)
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.trailing, 2)
                    
                    // 7-day strip
                    HStack(spacing: 8) {
                        ForEach(calendarManager.days) { day in
                            VStack(spacing: 3) {
                                Text(day.dayOfWeek)
                                    .font(.system(size: 8.5, weight: day.isToday ? .bold : .semibold, design: .rounded))
                                    .foregroundColor(day.isToday ? Color(red: 0.95, green: 0.45, blue: 0.35) : Color.white.opacity(0.35))
                                
                                Text(day.dayNumber)
                                    .font(.system(size: 13, weight: day.isToday ? .bold : .medium, design: .rounded))
                                    .foregroundColor(day.isToday ? Color(red: 0.0, green: 0.55, blue: 1.0) : Color.white.opacity(0.75))
                            }
                            .frame(minWidth: 16)
                        }
                    }
                }
                
                Spacer(minLength: 4)
                
                // Bottom: Event Status Pill
                HStack(spacing: 6) {
                    Image(systemName: "calendar.badge.checkmark")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text(calendarManager.todayEventsText)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 4)
                .padding(.horizontal, 10)
                .background(Color.white.opacity(isHovered ? 0.08 : 0.04))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .padding(.leading, 4)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                isHovered = hovering
            }
        }
    }
}
