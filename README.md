📄 Overview
===========

Golden Ticket Enterprise is an advanced, full-stack ticketing system built with Flutter and .NET technologies. This powerful platform is designed to streamline employee support and enhance staff collaboration, providing an intuitive and efficient way to manage employee issues using AI models.

📚 Description
===========
With real-time features like chat and notifications, Golden Ticket Enterprise ensures that users can always stay up-to-date with ongoing issues and resolved tickets. By integrating cutting-edge AI technology, the system leverages the GPT4o model to provide an intelligent, AI-powered chat support bot. This chat support bot offers users immediate assistance, automating problem resolution and reducing the need for human intervention for frequently asked questions or common issues.

The system also features a ticket management system, role-based access controls, and powerful reporting/analytics tools to monitor and assess team performance. Whether it's managing customer queries, internal project management, or generating insightful reports, Golden Ticket Enterprise ensures that your team can work smarter, not harder.

🛠 Tech Stack: Flutter, .NET 8, SignalR, Hive, MySQL Server

⚡ Key Features:
===========
- Real-time data updates

- Ticket management system

- Reporting and analytics

- GPT4o Large Language Model (LLM) 

- AI FAQ support

⚠️ Requirements
===========
✔️ .NET - 8.0

✔️ MySQL Database - 8.0.41

✔️ Android Studio Koala Feature Drop | 2024.1.2 Patch 1

✔️ Flutter 3.27.4

✔️ Dart SDK 3.6.2 (stable)

✔️ IIS

✔️ IIS WebSocket Extension

✔️ .NET Hosting Bundle

🚀 Installation
===========
Follow these steps to set up the project locally:

**1. Clone the repository**
```
bash
Copy
Edit
git clone https://github.com/your-username/your-repo.git
cd your-repo
```
**2. Setup secret.json for .NET Project**

GoldenTicket/Config/secret.json Example
> OpenAIKeys are the Github Access Tokens
```json
{
    "ConnectionString": "Server=10.10.10.10;User=someUsername;Password=somePassword;Database=someDatabase;",
    "AdminUsername": "AdminGT",
    "AdminPassword": "citillion2019",
    "AdminFirstName": "John Mar",
    "AdminMiddleName": "",
    "AdminLastName": "Doe"
}
```

**3. Setup Backend**
Navigate to the server project.

Restore NuGet packages.

Run database migrations.

❗Don't Run your backend server just yet! Flutter application must be setup before launching

**4. Setup Flutter App**
Navigate to the Flutter project directory.

**Setup your secret file**
lib/secret.dart example
```dart
const String kAppName = 'Golden Ticket Enterprise';

const String kSessionKey = "gt_session";

const String kLocalStorageKey = 'VPOt8VdETP1ix6zhPN0FGRPgoWRuMMd';
late final String kLocalStoragePath;
const Set<String> kLocalStorageBoxNames = {'session'};

// Base URL of your backend server
// Note for building: Before Building make sure to delete wwwroot/app folder in your .NET folder, then build project the IP with your server IP
// Note for building: Before r
// Note for deployment: NEVER USE LOCALHOST URL FOR PRODUCTION USE YOUR SERVER IP
const String kBaseURL = "190.20.20.10";

// only modify this if you know what you're doing!
const String kGTHub = 'GTHub';
const String kLogin = 'api/GTAuth/Login';
const String kValidate = 'api/GTAuth/Verify';
```

Install dependencies:
flutter pub get

Build Project
flutter build web -o C:/Path/To/Your/wwwroot/app


📈 Running the Application
===========
Once all setup is done you can now you can run your .NET Project
dotnet watch

🔓 Accessing your application (locally)
===========
To access web application go to any browser of your choice and type the url
localhost

📦 Publishing
===========
❗Before Publishing the .NET Project as Folder make sure:
- Flutter application's secret is configured and built for the server IP
- Publish as Folder
- Publishing Settings as follows (Don't forget to add your connection string):
![image](https://github.com/user-attachments/assets/6edad5ca-7837-4514-b00c-f5750f17093f)

📝 Notes
===========
- ✅ Make sure you have the correct Flutter and .NET SDK versions installed.

- 🛡️ Configure your secret files properly for .NET and Flutter

- ⚡ Deployment Settings provided below.

- 🐛 If you encounter issues, check the common problems in the Issues section or create a new one.

- 🔥 Full-text search is enabled for FAQ fields (Title, Description, Solution).

- 💽 If you are deploying on IIS make sure you have the Websocket extension installed otherwise SignalR won't work

📬 Contact
===========
> Feel free to reach out to us if you have questions!
- 📧 josephvictorrozul@gmail.com (Flutter, .NET related questions)
- 📧 jhericomedina213@gmail.com (.NET, AI Model related questions)
