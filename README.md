# DepoBase - Warehouse Tracking System

DepoBase is a comprehensive warehouse management and stock tracking mobile application built with Flutter. It is designed to streamline inventory operations for small to medium-sized businesses, allowing efficient tracking of products, stock movements, and team collaboration.

## 🎯 Project Goals

We developed DepoBase to solve common inventory management pain points:
*   **Minimize Human Error:** Manual stock counting is prone to mistakes. We automated this with barcode and text recognition.
*   **Work Anywhere:** Warehouse internet connections can be unreliable. Our **offline-first** architecture (SQLite) ensures work never stops, while Firebase syncs everything when back online.
*   **Speed Up Operations:** Fast product entry and stock updates mean less time counting and more time fulfilling orders.
*   **Team Synchronization:** Enable warehouse staff and office managers to see the same real-time data.

## 🚀 Features & Capabilities

*   **📦 Stock Management**
    *   *Goal:* Maintain 100% accurate inventory levels.
    *   Track quantity changes, monitor low stock levels, and organize products by category and location.
*   **📷 Smart Scanning (QR/Barcode & OCR)**
    *   *Goal:* Speed up data entry and retrieval.
    *   Use the device camera to scan barcodes for instant product lookup.
    *   Use **OCR (Text Recognition)** to "read" product info from labels, removing the need for manual typing.
*   **☁️ Cloud & Offline Sync**
    *   *Goal:* Reliability and accessibility.
    *   **SQLite (Local DB):** Ensures the app is blazing fast and fully functional even in dead zones.
    *   **Firebase (Cloud):** Syncs data across all team devices instantly when a connection is available.
*   **📊 Excel Integration**
    *   *Goal:* Easy migration and reporting.
    *   **Import:** Bulk upload legacy inventory data from Excel files in seconds.
    *   **Export:** Generate shareable reports for stakeholders who don't use the app.
*   **👥 Team Collaboration**
    *   *Goal:* Better coordination.
    *   secure login and role-based access control for different team members.

## 🛠️ Technology Stack

This project allows us to explore and demonstrate advanced Flutter development capabilities:

*   **Framework:** [Flutter](https://flutter.dev/) (Dart) - *For a beautiful, native cross-platform experience.*
*   **Backend & Auth:** [Firebase](https://firebase.google.com/) (Firestore, Authentication) - *For secure, real-time cloud data.*
*   **Local Database:** [SQLite](https://pub.dev/packages/sqflite) (sqflite) - *For robust offline persistence.*
*   **State Management:** [Provider](https://pub.dev/packages/provider) - *For clean and efficient state handling.*
*   **Key Packages:**
    *   `mobile_scanner`: *Barcode/QR scanning.*
    *   `google_mlkit_text_recognition`: *On-device machine learning for text recognition.*
    *   `excel` & `file_picker`: *Data import/export.*

## 🏁 Getting Started

### Prerequisites

*   Flutter SDK installed (version 3.10.7 or higher)
*   Android Studio or VS Code configured for Flutter
*   A Firebase project set up (specifically for Cloud Firestore and Authentication)

### Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/yourusername/depobase.git
    cd depobase
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Firebase Configuration:**
    *   This project uses `flutterfire_cli`. Ensure you have your `firebase_options.dart` configured or replace it with your own project's configuration.

4.  **Run the App:**
    ```bash
    flutter run
    ```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

*Developed with ❤️ using Flutter*
