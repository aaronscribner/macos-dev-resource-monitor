# DevResourceMonitor

A native macOS application for monitoring CPU and memory usage of software engineering tools.

## Features

- **Menu Bar App**: Quick access to resource stats from the menu bar
- **Detailed Window**: Full dashboard with charts and process lists
- **Category Tracking**: Pre-configured categories for dev tools (IDEs, containers, databases, etc.)
- **Visualizations**:
  - Pie charts for current CPU and memory usage by category
  - Bar charts for historical usage over time
- **Threshold Alerts**: Get notified when CPU or memory exceeds thresholds
- **Process Snapshots**: Records all running processes when thresholds are exceeded
- **Trend Analysis**: Compare this week vs. last week usage
- **Custom Categories**: Define your own app categories and process mappings
- **Process Management**: Terminate resource-heavy processes directly from the app

## Default Categories

- **IDEs & Editors**: VS Code, JetBrains suite, Xcode, Sublime, Vim, Neovim, Cursor, Zed
- **Containers & VMs**: Docker, Podman, Colima, OrbStack, UTM, Parallels, VMware
- **Dev Tools**: Terminal, iTerm2, Warp, Git, Node.js, Python, Ruby, Go, Rust, Java
- **Databases**: PostgreSQL, MySQL, MongoDB, Redis, TablePlus, DBeaver
- **Browsers (Dev)**: Chrome, Firefox, Safari, Arc, Brave, Edge
- **Build & CI**: Gradle, Maven, Webpack, Vite, npm, yarn, pnpm
- **Communication**: Slack, Discord, Zoom, Teams

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 15.0 or later (for building)

## Building

### Option 1: Using XcodeGen

1. Install XcodeGen: `brew install xcodegen`
2. Generate the project: `xcodegen generate`
3. Open `DevResourceMonitor.xcodeproj` in Xcode
4. Build and run (⌘R)

### Option 2: Using Swift Package Manager

```bash
cd DevResourceMonitor
swift build
```

### Option 3: Create Xcode Project Manually

1. Create a new macOS App project in Xcode
2. Select SwiftUI as the interface
3. Copy all Swift files from `DevResourceMonitor/` into the project
4. Add the `Resources/` folder to the project
5. Configure the Info.plist and entitlements
6. Build and run

## Usage

### Menu Bar

Click the gauge icon in the menu bar to see:
- Current CPU and memory usage
- Breakdown by category
- Threshold status
- Quick access to the detailed window

### Dashboard

The main window provides:
- Circular gauges for CPU and memory
- Pie charts showing usage by category
- List of top resource consumers
- Toggle between grouped and detailed views

### History

View historical data with:
- Time range selection (1H, 6H, 24H, 7D, 30D)
- Stacked bar charts for CPU and memory
- Peak and average statistics

### Processes

Browse all processes with:
- Search filtering
- Category filtering
- Grouped or detailed views
- Ability to terminate processes

### Threshold Events

When thresholds are exceeded:
- All running processes are captured
- View the snapshot to analyze what was consuming resources
- Identify the culprits causing high usage

### Trends

Analyze usage patterns:
- Compare this week vs. last week
- See which categories/apps are increasing or decreasing usage
- Identify trends before they become problems

## Settings

- **General**: Update interval, display options, history retention
- **Thresholds**: CPU and memory threshold levels, cooldown period
- **Notifications**: Enable/disable alerts, sound, silent logging
- **Categories**: Add custom categories, define process mappings

## Data Storage

Data is stored in `~/Library/Application Support/DevResourceMonitor/`:
- `monitor.db` - SQLite database containing all data (snapshots, events, settings, categories)

**Retention**: History data is automatically cleaned up after 7 days to keep the database size manageable.

## Architecture

```
DevResourceMonitor/
├── App/                    # Main app entry point
├── Models/                 # Data models (ProcessInfo, ResourceSnapshot, etc.)
├── Services/               # Business logic (ProcessMonitor, HistoryManager, etc.)
├── ViewModels/             # State management (MonitorViewModel, etc.)
├── Views/                  # SwiftUI views
│   ├── MenuBar/           # Menu bar popover
│   ├── MainWindow/        # Dashboard, History, Processes, Events, Trends
│   ├── Settings/          # Settings tabs
│   └── Components/        # Reusable UI components
└── Utilities/              # Extensions, formatters, constants
```

## License

MIT License
