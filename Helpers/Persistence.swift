import Foundation
import SwiftData

class PersistenceHelper {
    static func getTotalPoints(for child: Child, in bucket: TimeBucket, from events: [PointEvent]) -> Int {
        let filteredEvents = filterEvents(events, for: bucket)
        return filteredEvents
            .filter { $0.child?.id == child.id }
            .reduce(0) { $0 + $1.points }
    }
    
    static func getFamilyTotalPoints(in bucket: TimeBucket, from events: [PointEvent]) -> Int {
        let filteredEvents = filterEvents(events, for: bucket)
        return filteredEvents.reduce(0) { $0 + $1.points }
    }
    
    static func getPointsByCategory(for child: Child? = nil, in bucket: TimeBucket, from events: [PointEvent]) -> [(BehaviorCategory, Int)] {
        let filteredEvents = filterEvents(events, for: bucket)
        let relevantEvents = child != nil ? filteredEvents.filter { $0.child?.id == child?.id } : filteredEvents
        
        var categoryPoints: [BehaviorCategory: Int] = [:]
        
        for event in relevantEvents {
            if let category = event.behavior?.category {
                categoryPoints[category, default: 0] += max(0, event.points) // Only count positive points for pie chart
            }
        }
        
        return categoryPoints
            .map { ($0.key, $0.value) }
            .sorted { $0.1 > $1.1 }
    }
    
    static func getPointsOverTime(for child: Child? = nil, in bucket: TimeBucket, from events: [PointEvent]) -> [(Date, Int)] {
        let filteredEvents = filterEvents(events, for: bucket)
        let relevantEvents = child != nil ? filteredEvents.filter { $0.child?.id == child?.id } : filteredEvents
        
        // Group by day and accumulate
        let calendar = Calendar.current
        var dailyPoints: [Date: Int] = [:]
        
        for event in relevantEvents {
            let dayStart = calendar.startOfDay(for: event.timestamp)
            dailyPoints[dayStart, default: 0] += event.points
        }
        
        // Convert to cumulative points
        let sortedDays = dailyPoints.keys.sorted()
        var cumulativePoints = 0
        var result: [(Date, Int)] = []
        
        for day in sortedDays {
            cumulativePoints += dailyPoints[day] ?? 0
            result.append((day, cumulativePoints))
        }
        
        return result
    }
    
    private static func filterEvents(_ events: [PointEvent], for bucket: TimeBucket) -> [PointEvent] {
        let calendar = Calendar.current
        let now = Date()
        
        switch bucket {
        case .daily:
            let startOfDay = calendar.startOfDay(for: now)
            return events.filter { $0.timestamp >= startOfDay }
            
        case .weekly:
            guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start else { return events }
            return events.filter { $0.timestamp >= weekStart }
            
        case .monthly:
            guard let monthStart = calendar.dateInterval(of: .month, for: now)?.start else { return events }
            return events.filter { $0.timestamp >= monthStart }
            
        case .yearToDate:
            guard let yearStart = calendar.dateInterval(of: .year, for: now)?.start else { return events }
            return events.filter { $0.timestamp >= yearStart }
            
        case .lifetime:
            return events
        }
    }
}
