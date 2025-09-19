# Food Nutrition Tracker App

[![Flutter](https://img.shields.io/badge/Flutter-3.0-blue)](https://flutter.dev)

## Overview

Food Tracker App is a mobile application built with Flutter to track daily food intake and calculate nutrition macros (Calories, Carbs, Protein, Fat). Designed for simplicity and usability, it provides users with essential nutrition tracking without cluttered interfaces.

---

## Features

* **Food Database**

  * Add and view foods with nutrition information per 100 grams.
  * Persist food items locally using SQLite.

* **Daily Food Log**

  * Log food consumption by selecting a food item and entering intake in grams.
  * Automatic calculation of Calories, Carbs, Protein, and Fat.
  * Daily totals card displays aggregate macros for the selected date.
  * Calendar picker to view logs for any day.

* **Weekly Summary**

  * Consolidates daily logs into a weekly overview.
  * Shows macro totals for each day.

* **Persistent Storage**

  * All data is stored in SQLite, ensuring logs are saved across app sessions.

---

## How It Works

1. **FoodDB** stores the nutrition data for each food per 100 grams.
2. **Food Log** calculates intake nutrition using:

   ```
   macro_in_intake = macro_per_100g * (intake_grams / 100)
   ```

   Example: 50g of rice with 80g carbs per 100g → `80 * 50/100 = 40g carbs`.
3. **Daily Totals Card** aggregates calories, carbs, protein, and fat for the selected date.
4. **Weekly Summary** groups daily logs to provide a weekly overview.

---

## Project Structure

```
lib/
├── db/
│   └── food_database.dart      # SQLite helper for food and logs
├── models/
│   ├── food_item.dart          # Food item model
│   └── food_log.dart           # Food log model
├── screens/
│   ├── food_db.dart            # Food database screen
│   ├── food_log.dart           # Daily food log screen
│   └── weekly_summary.dart     # Weekly summary screen
└── main.dart                   # App entry point
```

---

## Getting Started

### Prerequisites

* Flutter SDK 3.0 or above
* Android Studio, VS Code, or any Flutter-compatible IDE
* Device or emulator for testing

### Installation

```bash
git clone <repository_url>
cd <repository_name>
flutter pub get
flutter run
```

---

## Future Enhancements

* Pie chart visualization for macro split.
* Edit/delete logs from daily log.
* Integration with online nutrition databases for auto-fetching nutrition data.
* Monthly summary and export options.

---

## License

MIT License
