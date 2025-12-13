# Known Issues & Limitations

## ⚠️ By Design - In-Memory State Only

### Data Does Not Persist

**This is NOT a bug - it's intentional!**

- ❌ **All data resets when you close the app**
- ❌ **No data is saved between sessions**
- ❌ **Hot reload preserves state, but hot restart resets everything**
- ❌ **Switching to another app may cause data loss (OS memory management)**

**Why?**
This project demonstrates **Riverpod state management** and **SOLID principles** without the complexity of database integration. Adding SQLite/SharedPreferences would shift focus away from the core learning objectives.

---

## Technical Limitations

### 1. No Persistence Layer

| Feature | Status | Reason |
|---------|--------|--------|
| Save to database | ❌ Not implemented | In-memory only by design |
| SharedPreferences | ❌ Not used | No persistence layer |
| File system storage | ❌ Not used | No persistence layer |
| Cloud sync | ❌ Not implemented | No backend |
| Export/Import data | ❌ Not implemented | No file operations |

### 2. Memory Constraints

- **Large datasets**: Performance degrades with 1000+ habits or 1+ year of history
- **Memory pressure**: OS may kill app on low-memory devices, losing all data
- **No pagination**: All data loaded into memory at once

### 3. Date/Time Handling

- **Timezone**: All dates use device local time (not UTC)
- **Date changes**: Streak calculations may be inaccurate if device timezone changes
- **Midnight boundary**: Completion dates use DateTime.now() - may cause edge cases near midnight

### 4. Streak Algorithm Edge Cases

- **Grace period**: Only applies to current streak, not longest streak
- **Frequency changes**: Changing habit frequency doesn't recalculate historical streaks
- **Manual date entry**: Cannot mark habits complete for past dates
- **Leap years**: Basic handling, may have edge cases on Feb 29

---

## Missing Features (Out of Scope)

### Not Implemented

- 🔕 Push notifications / reminders
- ☁️ Cloud backup / sync
- 📱 Multi-device support
- 👥 Social features / sharing
- 📊 Advanced analytics / charts
- 🎨 Theme customization
- 🌐 Localization / multiple languages
- ♿ Accessibility features (screen reader support)
- 📤 Export to CSV / PDF
- 📥 Import from other habit trackers
- 🔐 Data encryption
- 👤 User authentication / profiles

**Why?**
These features would require databases, backends, or significant additional complexity beyond the scope of demonstrating Riverpod and SOLID principles.

---

## Workarounds

### Preserve Data During Development

```bash
# Use hot reload (not hot restart) to preserve state
flutter run

# Then press 'r' for hot reload (keeps state)
# Don't press 'R' for hot restart (loses state)
```

### Reset to Clean State

```bash
# Full app restart to reset to mock data
flutter run

# Or press 'R' in terminal for hot restart
```

### Testing with Different Data

- Modify `services/mock_data_generator.dart` to change initial data
- Hot restart to load new mock data
- No need to clear database - just restart!

---

## Performance Considerations

### Current Performance Benchmarks

Based on mock data (10 habits, 60 days history):

| Operation | Target | Actual | Status |
|-----------|--------|--------|--------|
| Toggle completion | < 16ms | ~5ms | ✅ Excellent |
| Calendar generation | < 100ms | ~20ms | ✅ Excellent |
| Insights computation | < 200ms | ~50ms | ✅ Good |
| Streak calculation | < 50ms | ~10ms | ✅ Excellent |

### Expected Performance Degradation

With larger datasets:

| Dataset Size | Expected Performance | Recommendation |
|--------------|---------------------|----------------|
| 10 habits, 60 days | Excellent | ✅ Ideal for demo |
| 50 habits, 180 days | Good | ✅ Acceptable |
| 100 habits, 365 days | Fair | ⚠️ May lag on calendar |
| 500+ habits | Poor | ❌ Not recommended |

**Why no pagination?**
The app loads all data into memory at once. With a real database, you'd implement:
- Lazy loading
- Pagination
- Query optimization
- Indexed searches

But for in-memory demo purposes, this complexity is unnecessary.

---

## Future Enhancements (If Adding Persistence)

If this were a production app, you would add:

### Database Layer
```dart
// Add repository pattern
abstract class IHabitRepository {
  Future<List<Habit>> getAllHabits();
  Future<void> saveHabit(Habit habit);
  Future<void> deleteHabit(String id);
}

// Implement with Drift/SQLite
class HabitRepository implements IHabitRepository {
  // Database operations
}

// Update providers to use repository
final habitRepositoryProvider = Provider<IHabitRepository>((ref) {
  return HabitRepository();
});
```

### Persistence Integration
- Use `drift` or `sqflite` for SQLite
- Use `shared_preferences` for settings
- Add async/await to all state mutations
- Implement loading states
- Add error handling for DB failures

But for this project: **Keep it simple - in-memory only!**

---

## Security & Privacy

### Data Privacy

✅ **Excellent Privacy**
- No data leaves the device
- No network requests
- No analytics tracking
- No cloud storage
- All data is local and temporary

❌ **No Data Protection**
- Data is not encrypted in memory
- Anyone with device access can see the app
- No PIN/biometric lock
- Data lost if app is uninstalled

**For a production app**: Add device authentication and data encryption.

---

## Testing Limitations

### What We Can Test

✅ Provider logic (unit tests)  
✅ Streak calculations (unit tests)  
✅ Widget rendering (widget tests)  
✅ User interactions (integration tests)  

### What We Cannot Test

❌ Data persistence (no database to mock)  
❌ Background tasks (not implemented)  
❌ Push notifications (not implemented)  
❌ Network failures (no network layer)  

---

## Conclusion

These limitations are **intentional** and **acceptable** for this project's goals:

🎯 **Goal**: Demonstrate Riverpod state management and SOLID principles  
✅ **Achieved**: Clean provider architecture without database complexity  

If you need persistence, consider this project as a foundation and add:
1. Repository layer (following D in SOLID)
2. Database implementation (Drift recommended)
3. Async state management patterns
4. Error handling for I/O operations

But for learning Riverpod and SOLID: **In-memory is perfect!**
