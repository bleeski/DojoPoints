import Foundation

enum TimeBucket: String, CaseIterable, Identifiable {
    case daily = "Day"
    case weekly = "Week"
    case monthly = "Month"
    case yearToDate = "YTD"
    case lifetime = "Lifetime"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .daily: return "Today"
        case .weekly: return "This Week"
        case .monthly: return "This Month"
        case .yearToDate: return "Year to Date"
        case .lifetime: return "All Time"
        }
    }
    
    func dateRange() -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .daily:
            let start = calendar.startOfDay(for: now)
            let end = calendar.date(byAdding: .day, value: 1, to: start)!
            return (start, end)
            
        case .weekly:
            // Week starts on Sunday
            var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
            components.weekday = 1 // Sunday
            let start = calendar.date(from: components)!
            let end = calendar.date(byAdding: .weekOfYear, value: 1, to: start)!
            return (start, end)
            
        case .monthly:
            let start = calendar.dateInterval(of: .month, for: now)!.start
            let end = calendar.dateInterval(of: .month, for: now)!.end
            return (start, end)
            
        case .yearToDate:
            let start = calendar.dateInterval(of: .year, for: now)!.start
            return (start, now)
            
        case .lifetime:
            return (Date.distantPast, Date.distantFuture)
        }
    }
}
