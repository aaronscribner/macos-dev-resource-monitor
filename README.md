# DevResourceMonitor

A native macOS menu bar application for monitoring CPU and memory usage of software engineering tools. Track resource consumption by your IDEs, containers, databases, and other dev tools in real-time.

## Features

- **Menu Bar Integration**: Quick access to resource stats from the menu bar
- **Real-time Monitoring**: Live CPU and memory tracking with configurable update intervals
- **Category-based Tracking**: Pre-configured categories for common dev tools
- **Visual Dashboard**:
  - Circular gauges for overall CPU/memory
  - Per-core CPU usage charts
  - Pie charts showing usage breakdown by category
  - Historical bar charts over time
- **Threshold Alerts**: Get notified when CPU or memory exceeds configurable thresholds
- **Process Snapshots**: Automatically captures all running processes when thresholds are exceeded
- **Trend Analysis**: Compare this week vs. last week to identify usage patterns
- **Custom Categories**: Define your own categories and process mappings
- **Process Management**: Terminate resource-heavy processes directly from the app

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 15.0+ and XcodeGen (for building from source)

## Installation

### Option 1: Download DMG

1. Download the latest DMG from [Releases](https://github.com/aaronscribner/macos-dev-resource-monitor/releases)
2. Open the DMG and drag DevResourceMonitor to Applications
3. Launch from Applications folder

### Option 2: Build from Source

```bash
# Clone the repository
git clone https://github.com/aaronscribner/macos-dev-resource-monitor.git
cd macos-dev-resource-monitor

# Build and create DMG (requires xcodegen)
make dmg

# Or just build
make build

# Or run directly
make run
```

#### Build Requirements

- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`
- Xcode 15.0 or later
- Command Line Tools: `xcode-select --install`

## Usage

### Menu Bar

Click the gauge icon in the menu bar to see:
- Current CPU and memory usage percentages
- Resource breakdown by category
- Top consuming applications
- Quick access to the detailed window and settings

### Dashboard Tab

The main dashboard provides:
- Circular gauges for total CPU and memory usage
- Per-core CPU utilization chart
- Pie charts showing usage distribution by category
- List of top resource consumers with kill buttons
- Toggle between grouped (by app) and detailed (by process) views

### History Tab

View historical resource usage:
- Time range selection: 1 Hour, 6 Hours, 24 Hours, 7 Days, 30 Days
- Stacked bar charts for CPU and memory by category
- Peak and average statistics for the selected period

### Processes Tab

Browse all monitored processes:
- Search by process name
- Filter by category
- Sort by CPU, memory, or name
- Grouped or detailed view modes
- Terminate processes with confirmation

### Events Tab

Review threshold breach events:
- List of all recorded threshold violations
- Detailed process snapshot at time of breach
- Identify which processes were consuming resources

### Trends Tab

Analyze usage patterns over time:
- This week vs. last week comparison
- Category-level trend analysis
- Identify increasing or decreasing usage patterns

## Default Categories

| Category | Applications |
|----------|-------------|
| **IDEs & Editors** | VS Code, JetBrains suite, Xcode, Sublime, Vim, Neovim, Cursor, Zed |
| **Containers & VMs** | Docker, Podman, Colima, OrbStack, UTM, Parallels, VMware |
| **Dev Tools** | Terminal, iTerm2, Warp, Git, Node.js, Python, Ruby, Go, Rust, Java |
| **Databases** | PostgreSQL, MySQL, MongoDB, Redis, TablePlus, DBeaver |
| **Browsers** | Chrome, Firefox, Safari, Arc, Brave, Edge |
| **Build & CI** | Gradle, Maven, Webpack, Vite, npm, yarn, pnpm |
| **Communication** | Slack, Discord, Zoom, Teams |

## Configuration

Access settings via the gear icon or `Cmd + ,`:

### General
- **Update Interval**: How often to refresh data (5-60 seconds)
- **History Retention**: How long to keep historical data (1-30 days)
- **Display Options**: Choose grouped or detailed view mode

### Thresholds
- **CPU Threshold**: Alert when total CPU exceeds this percentage (default: 80%)
- **Memory Threshold**: Alert when memory usage exceeds this percentage (default: 85%)
- **Cooldown Period**: Minimum time between alerts (default: 5 minutes)

### Notifications
- **Enable Notifications**: Toggle system notifications on/off
- **Sound**: Play sound with notifications
- **Silent Logging**: Record events without showing notifications

### Categories
- Add custom categories
- Define process name patterns for categorization
- Assign colors for visualization

## Data Storage

Data is stored in `~/Library/Application Support/DevResourceMonitor/`:

| File | Description |
|------|-------------|
| `monitor.db` | SQLite database containing snapshots, events, settings, and categories |

Historical data is automatically cleaned up based on your retention settings to manage database size.

## Architecture

```
DevResourceMonitor/
├── App/                    # Main app entry point
├── Models/                 # Data models
│   ├── ProcessInfo.swift       # Process data structure
│   ├── ResourceSnapshot.swift  # Point-in-time resource capture
│   ├── AppCategory.swift       # Category definitions
│   ├── ThresholdEvent.swift    # Threshold breach records
│   └── Settings.swift          # User preferences
├── Services/               # Business logic
│   ├── ProcessMonitor.swift    # Fetches process data via ps
│   ├── HistoryManager.swift    # Manages historical data
│   ├── DatabaseManager.swift   # SQLite persistence
│   ├── ThresholdMonitor.swift  # Monitors for threshold breaches
│   ├── NotificationService.swift # System notifications
│   └── ProcessKiller.swift     # Process termination
├── ViewModels/             # State management
│   ├── MonitorViewModel.swift  # Main app state
│   ├── HistoryViewModel.swift  # History tab state
│   ├── TrendsViewModel.swift   # Trends tab state
│   └── SettingsViewModel.swift # Settings state
├── Views/                  # SwiftUI views
│   ├── MenuBar/               # Menu bar popover
│   ├── MainWindow/            # Tab views (Dashboard, History, etc.)
│   ├── Settings/              # Settings tabs
│   └── Components/            # Reusable UI components
├── Utilities/              # Helpers
│   ├── Extensions.swift       # Swift extensions
│   ├── Formatters.swift       # Number/date formatting
│   └── Constants.swift        # App constants
└── Resources/              # Assets and configuration
```

## Troubleshooting

### App doesn't appear in menu bar
- Check System Settings > Control Center > Menu Bar Only to ensure there's space
- Try quitting and relaunching the app

### High CPU usage from the app itself
- Increase the update interval in Settings > General
- Reduce history retention period

### Notifications not appearing
- Check System Settings > Notifications > DevResourceMonitor
- Ensure notifications are enabled in app settings
- Verify the app has notification permissions

### Database errors
- Delete `~/Library/Application Support/DevResourceMonitor/monitor.db` to reset
- The app will recreate the database on next launch

## Building for Distribution

```bash
# Create a DMG for distribution
make dmg

# The DMG will be created at release/DevResourceMonitor-1.0.dmg
```

Note: For distribution outside the App Store, users may need to right-click and select "Open" on first launch, or allow the app in System Settings > Privacy & Security.

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

MIT License

## Acknowledgments

- Built with SwiftUI and Swift Charts
- Uses SQLite for local data persistence
- Inspired by the need to track runaway Docker containers and IDE memory leaks
