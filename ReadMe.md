# SpotIt 📍 | Civic Issue Reporting & Community App

![SpotIt Banner](placeholder_for_banner_image.png)

## 📖 Overview
SpotIt is a modern, reactive Flutter application designed to empower citizens to report local civic issues (such as potholes, water leaks, and fallen trees) directly to municipal authorities. Beyond just reporting, SpotIt fosters local communities through a "Neighborhood Network," allowing residents of specific wards to connect, view live incident maps, and track the real-time resolution progress of community reports.

## ✨ Features
* **Intelligent Issue Reporting:** Seamlessly report issues with GPS coordinate mapping, image evidence uploads, and an "AI Fill" assistant for quick descriptions.
* **Interactive Community Map:** View live reports plotted on an interactive map (`flutter_map`) with dynamic CartoDB dark-mode tiles.
* **Live Status Tracking:** Monitor issue resolution via an interactive, 4-step progress timeline.
* **Neighborhood Network:** Connect with verified neighbors in your specific ward and view a localized activity feed.
* **Admin Command Center:** Dedicated role-based access for municipal engineers to review issues and update resolution statuses in real-time.
* **Dynamic Dark Mode:** A sleek, fully reactive dark mode implemented globally across the app via `ValueNotifier`.


## 🛠 Tech Stack

| Domain | Technology |
| :--- | :--- |
| **Frontend Framework** | Flutter |
| **Language** | Dart |
| **Backend / BaaS** | Firebase |
| **Database** | Cloud Firestore (NoSQL) |
| **Authentication** | Firebase Authentication |
| **Maps & Routing** | `flutter_map`, `latlong2`, OpenStreetMap |
| **State Management** | `ValueNotifier`, `StatefulBuilder` |

## 📂 Project Structure
```text
lib/
│
├── main.dart                  # App entry point, Routing, Global Theme Notifier
├── models/                    
│   ├── issue.dart             # Issue data model (Title, Location, Status, etc.)
│   └── user_profile.dart      # User data model (Ward, Role, Demographics)
│
├── screens/                   
│   ├── admin_screen.dart      # Role-based municipal command center
│   ├── home_screen.dart       # Main dashboard & live statistics
│   ├── issue_tracking.dart    # Interactive timeline & admin controls
│   ├── map_screen.dart        # OpenStreetMap implementation
│   ├── my_issues_screen.dart  # Filterable community/personal feed
│   ├── profile_screen.dart    # User settings, auth actions, neighborhood network
│   └── report_screen.dart     # Form submission with Geolocation & Image Picker
│
└── services/                  
    └── firebase_service.dart  # Abstraction layer for Firestore & Auth CRUD
