# 📱 Contactly – Contact Management App

<p align="center">
  A simple, modern, and user-friendly contact management application built with Flutter.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-Framework-02569B?logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-Language-0175C2?logo=dart&logoColor=white" alt="Dart">
  <img src="https://img.shields.io/badge/SQLite-Database-003B57?logo=sqlite&logoColor=white" alt="SQLite">
  <img src="https://img.shields.io/badge/Platform-Android-green" alt="Android">
</p>

---

## 📖 About The Project

**Contactly** is a Flutter-based contact management application designed to make organizing personal contacts simple and efficient.

Users can add, view, update, delete, search, and mark contacts as favorites. The application uses SQLite for local data storage, allowing contact information to remain available on the device.

## ✨ Features

- **Add Contacts:** Save names, phone numbers, email addresses, and addresses.
- **View Contacts:** Display saved contacts in an organized list.
- **Edit Contacts:** Update existing contact information.
- **Delete Contacts:** Remove unwanted contacts.
- **Search Contacts:** Find contacts quickly by name.
- **Favorite Contacts:** Mark important contacts as favorites.
- **Filter Contacts:** Switch between all contacts and favorites.
- **Local Database:** Store contact information using SQLite.
- **Modern UI:** Clean interface with a consistent purple theme.

## 🛠️ Technologies Used

| Technology | Purpose |
|---|---|
| Flutter | Cross-platform UI development |
| Dart | Application programming language |
| SQLite | Local database |
| sqflite | SQLite database integration |
| Android Studio | Development environment |
| Git & GitHub | Version control |

## 📸 Screenshots



### Home Screen

![Contactly Home Screen](assets/screenshots/home.png)

### Add Contact

![Add Contact Screen](assets/screenshots/add_contact.png)

### Favorites

![Favorites Screen](assets/screenshots/favorites.png)

## 📂 Project Structure

```text
contact_app/
│
├── lib/
│   ├── database/
│   │   └── database_helper.dart
│   ├── models/
│   │   └── contact.dart
│   ├── screens/
│   │   ├── contact_form_screen.dart
│   │   └── contact_list_screen.dart
│   ├── app_colors.dart
│   └── main.dart
│
├── assets/
│   └── screenshots/
│       ├── home.png
│       ├── add_contact.png
│       └── favorites.png
│
├── pubspec.yaml
└── README.md
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK
- Dart SDK
- Android Studio or Visual Studio Code
- Android Emulator or a compatible Android device

### Installation

**1. Clone the repository**



```bash
git clone https://github.com/shafin-23/Contact-App
```

**2. Navigate to the project directory**

```bash
cd contact_app
```

**3. Install dependencies**

```bash
flutter pub get
```

**4. Run the application**

```bash
flutter run
```

## 🎯 Project Objective

The main objective of Contactly is to demonstrate Flutter application development, SQLite database integration, CRUD operations, and a clean user interface through a practical contact management application.

## 👨‍💻 Developer

**Md. Shafin Shadman**

- GitHub: [shafin-23](https://github.com/shafin-23)

---

<p align="center">
  **Built with Flutter 💜**
</p>
