# Assist

**Assist** is a double-sided marketplace application connecting customers with service providers (workers). Built with **Flutter** and **Firebase**, it features role-based access, real-time booking management, and comprehensive worker verification.

## 📱 Features

### For Customers
*   **Service Discovery:** Browse varying categories of services.
*   **Booking System:** Schedule jobs with preferred providers.
*   **Real-time Tracking:** Monitor booking status.
*   **Secure Authentication:** Email & Google Sign-In.
*   **Localization:** Complete support for English and Urdu.

### For Workers (Service Providers)
*   **Job Management:** Accept/Reject incoming job requests.
*   **Verification:** Upload documents (CNIC, Photos) for admin approval.
*   **Earnings:** Track completed jobs and income.
*   **Insights:** View demand hints based on booking history.

### Admin
*   **User Management:** Oversee platform users.
*   **Verification Queue:** Approve or reject worker documents.

## 🛠 Tech Stack

*   **Frontend:** Flutter (Mobile/Web)
*   **Backend:** Firebase (Auth, Firestore, Storage)
*   **State Management:** Custom Controller Pattern (Stream-based)
*   **Routing:** `go_router`
*   **Localization:** `flutter_localizations`
*   **UI Components:** `flutter_staggered_grid_view`, `rubber`

##  Getting Started

### Prerequisites
*   Flutter SDK (3.10.1 or higher)
*   Firebase Project (configured with `google-services.json`)

### Installation

1.  **Clone the repository:**
    ```bash
    git clone <repository-url>
    cd <project-folder>
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Run the app:**
    
    # For Androiddas
    flutter run -d android
    ```
    # For Android
    flutter run -d chrome
    '''

##  Project Structure

```
lib/
├── auth/           # Authentication screens (Login, Signup, Role Selection)
├── common/         # Shared widgets and generic pages (Profile, Settings)
├── controllers/    # Business logic and state management
├── models/         # Data models (AppUser, Booking)
├── services/       # Firebase and API handling
├── user/           # Customer-specific screens (Bookings, Home)
├── worker/         # Worker-specific screens (Earnings, Jobs, Verification)
└── main.dart       # Application entry point
```

##  Localization

The app supports **English (en)** and **Urdu (ur)**.
To switch languages, use the toggle on the **Login Screen** or in **Settings**.

## Theme

Includes a custom **Light** and **Dark** mode implementation.
The theme automatically adapts to system settings or can be toggled manually.

---