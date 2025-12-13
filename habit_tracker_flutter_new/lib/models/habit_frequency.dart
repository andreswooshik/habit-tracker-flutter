/// Enum representing different habit frequencies
/// Includes logic for determining if a habit is scheduled for a given date
enum HabitFrequency {
  /// Habit should be done every single day
  everyDay('Every Day'),
  
  /// Habit should be done on weekdays only (Monday-Friday)
  weekdays('Weekdays'),
  
  /// Habit should be done on weekends only (Saturday-Sunday)
  weekends('Weekends'),
  
  /// Habit should be done on custom selected days
  custom('Custom');

  final String displayName;

  const HabitFrequency(this.displayName);

  /// Determines if the habit is scheduled for the given date
  /// 
  /// [date] - The date to check
  /// [customDays] - List of weekday numbers (1=Monday, 7=Sunday) for custom frequency
  /// 
  /// Returns true if the habit should be tracked on this date
  bool isScheduledFor(DateTime date, List<int>? customDays) {
    switch (this) {
      case HabitFrequency.everyDay:
        return true;
      
      case HabitFrequency.weekdays:
        // Monday (1) through Friday (5)
        return date.weekday >= DateTime.monday && date.weekday <= DateTime.friday;
      
      case HabitFrequency.weekends:
        // Saturday (6) and Sunday (7)
        return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
      
      case HabitFrequency.custom:
        // Check if the weekday is in the custom days list
        return customDays?.contains(date.weekday) ?? false;
    }
  }

  /// Returns the number of expected completions per week for this frequency
  int get expectedPerWeek {
    switch (this) {
      case HabitFrequency.everyDay:
        return 7;
      case HabitFrequency.weekdays:
        return 5;
      case HabitFrequency.weekends:
        return 2;
      case HabitFrequency.custom:
        return 0; // Variable based on customDays
    }
  }

  /// Returns a human-readable description of the frequency
  String getDescription(List<int>? customDays) {
    switch (this) {
      case HabitFrequency.everyDay:
        return 'Every day of the week';
      case HabitFrequency.weekdays:
        return 'Monday through Friday';
      case HabitFrequency.weekends:
        return 'Saturday and Sunday';
      case HabitFrequency.custom:
        if (customDays == null || customDays.isEmpty) {
          return 'No days selected';
        }
        final dayNames = customDays.map(_getDayName).join(', ');
        return dayNames;
    }
  }

  /// Converts weekday number to name
  static String _getDayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return 'Unknown';
    }
  }
}
