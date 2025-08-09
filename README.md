# Homebrew Tap for iOS Deploy Platform

This is the official Homebrew tap for the iOS Deploy Platform.

## Installation

```bash
# Add the tap
brew tap snooky23/tools

# Install the platform
brew install ios-deploy-platform

# Initialize your iOS project
cd /path/to/your/ios/project
ios-deploy init
```

## Quick Start

```bash
# Deploy to TestFlight
ios-deploy deploy \
  team_id="YOUR_TEAM_ID" \
  app_identifier="com.yourapp" \
  apple_id="your@email.com" \
  api_key_id="YOUR_KEY_ID" \
  api_issuer_id="your-issuer-uuid" \
  app_name="Your App" \
  scheme="YourScheme"
```

## Documentation

- **Manual**: `man ios-deploy`
- **Help**: `ios-deploy help`
- **GitHub**: https://github.com/snooky23/ios-deploy-platform

## Features

- ⚡ **3-minute deployments** with complete automation
- 🎯 **100% TestFlight success rate** with production verification
- 🔐 **Smart certificate management** with auto-detection
- 🏢 **Multi-team support** with directory isolation
- 📊 **Enhanced TestFlight confirmation** with real-time status
- 🧠 **Intelligent version management** with conflict prevention