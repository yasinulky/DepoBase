# DepoBase - Warehouse Tracking System

DepoBase is a comprehensive warehouse management and stock tracking mobile application built with Flutter. It is designed to streamline inventory operations for small to medium-sized businesses, allowing efficient tracking of products, stock movements, and team collaboration.

## 🚀 Features

*   **📦 Stock Management:** Easily add, update, and delete products. Track stock quantities with entry and exit movements.
*   **📷 Smart Scanning:**
    *   **Barcode/QR Scanner:** Quickly find products or add stock using the integrated scanner.
    *   **OCR (Text Recognition):** Capture product details directly from the camera using ML Kit.
*   **☁️ Cloud & Offline Sync:**
    *   **Firebase Integration:** Real-time data synchronization across multiple devices.
    *   **SQLite Support:** Robust offline capability ensures you can work without an internet connection.
*   **📊 Excel Integration:**
    *   **Import:** Bulk add products by uploading Excel files.
    *   **Export:** Generate reports and export your inventory data to Excel.
*   **👥 Team Collaboration:** Invite team members to manage the warehouse together with role-based access.
*   **🔔 Alerts:** Get notified when stock levels are low.
*   **📱 Modern UI:** Clean, intuitive, and responsive design optimized for mobile devices.

## 🛠️ Technology Stack

This project allows us to explore and demonstrate advanced Flutter development capabilities:

*   **Framework:** [Flutter](https://flutter.dev/) (Dart)
*   **Backend & Auth:** [Firebase](https://firebase.google.com/) (Firestore, Authentication)
*   **Local Database:** [SQLite](https://pub.dev/packages/sqflite) (sqflite)
*   **State Management:** [Provider](https://pub.dev/packages/provider)
*   **Key Packages:**
    *   `mobile_scanner`: For barcode and QR code scanning.
    *   `google_mlkit_text_recognition`: For OCR capabilities.
    *   `excel` & `file_picker`: For handling spreadsheet data.
    *   `flutter_slidable`: For interactive list items.
    *   `shared_preferences`: For local settings storage.

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
