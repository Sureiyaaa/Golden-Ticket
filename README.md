📄 Overview
Golden Ticket Enterprise is an advanced, full-stack ticketing system built with Flutter and .NET technologies. This powerful platform is designed to streamline employee support and enhance staff collaboration, providing an intuitive and efficient way to manage employee issues using AI models.

📚 Description
Dive deeper into your project details:

🛠 Tech Stack: Flutter, .NET 8, SignalR, Hive, MySQL Server

⚡ Key Features:
Real-time chat and notifications

Ticket management system

Reporting and analytics

Role-based access control

GPT4o Large Language Model (LLM)

AI FAQ support

⚠️ Requirements
Ensure that the following are set up before you begin:

Flutter SDK

.NET SDK (version 8 or above)

MySQL Server (for database management)

API keys for GPT4o integration

🚀 Installation
Follow these steps to set up the project locally:

1. Clone the repository
bash
Copy
Edit
git clone https://github.com/your-username/your-repo.git
cd your-repo
2. Setup secret.json for .NET Project
Example: GoldenTicket/Config/secret.json

json
Copy
Edit
{
    "OpenAIKey": 
    [
        "apikey1",
        "apikey2"
    ],
    "ConnectionString": "Server=serverIp;User=databaseUser;Password=databasePassword;Database=databaseName;",
    "AdminUsername": "Admin",
    "AdminPassword": "admin",
    "AdminFirstName": "John",
    "AdminMiddleName": "Jane",
    "AdminLastName": "Doe"
}
3. Setup Backend
Navigate to the server project.

Restore NuGet packages.

Run database migrations.

After Migrations: Open MySQL Workbench and execute the following query:
(Replace databasename with your actual database name)

sql
Copy
Edit
ALTER TABLE databasename.tblFAQ ADD FULLTEXT(Title, Description, Solution);
❗ Don't Run your backend server just yet!
The Flutter application must be set up before launching.

4. Setup Flutter App
Navigate to the Flutter project directory.

Setup your secret file
Example: lib/secret.dart

dart
Copy
Edit
const String kAppName = 'Golden Ticket Enterprise';
const String kSessionKey = "gt_session";
const String kLocalStorageKey = 'VPOt8VdETP1ix6zhPN0FGRPgoWRuMMd';
late final String kLocalStoragePath;
const Set<String> kLocalStorageBoxNames = {'session'};

// Base URL of your backend server
const String kBaseURL = "yourip"; // 0.0.0.0
const String kGTHub = 'GTHub';
const String kLogin = 'api/GTAuth/Login';
Install dependencies:

bash
Copy
Edit
flutter pub get
Build the project:

bash
Copy
Edit
flutter build web -o C:/Path/To/Your/wwwroot/app
📈 Running the Application
Once all setup is done, you can now run your .NET project:

bash
Copy
Edit
dotnet watch
🔓 Accessing your application (locally)
To access the web application, go to any browser of your choice and type the URL:

text
Copy
Edit
localhost
📦 Publishing
❗ Before publishing the .NET project as a folder, make sure:

The Flutter application's secret is configured and built for the server IP.

Publish as Folder.

Publishing Settings as follows (Don’t forget to add your connection string):



📝 Notes
✅ Make sure you have the correct Flutter and .NET SDK versions installed.

🛡️ Configure your secret files properly for .NET and Flutter.

⚡ Deployment settings are provided below.

🐛 If you encounter issues, check the common problems in the Issues section or create a new one.

🔥 Full-text search is enabled for FAQ fields (Title, Description, Solution).

💽 If you are deploying on IIS, make sure you have the WebSocket extension installed, as SignalR won't work without it.

📬 Contact
Feel free to reach out to us if you have questions!

📧 Joseph Victor Rozul (Flutter, .NET related questions) - josephvictorrozul@gmail.com

📧 Jherico Medina (.NET, AI Model related questions) - jhericomedina213@gmail.com
