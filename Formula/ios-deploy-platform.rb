class IosDeployPlatform < Formula
  desc "Enterprise-grade iOS TestFlight automation with intelligent certificate management"
  homepage "https://github.com/snooky23/ios-deploy-platform"
  url "https://github.com/snooky23/ios-deploy-platform/archive/refs/tags/v2.3.0.tar.gz"
  license "MIT"
  version "2.3.0"
  sha256 "d0fae043fd57b322bc1f8372c6abb5a6581d29f29240c0bfa44d0973af5eb45e"

  # Dependencies
  depends_on "cocoapods" => :optional
  depends_on "fastlane"
  depends_on :macos
  depends_on "ruby@3.2"
  depends_on "xcode-install" => :optional

  # Ruby gem dependencies will be handled via bundler
  resource "bundler" do
    url "https://rubygems.org/downloads/bundler-2.4.22.gem"
    sha256 "747ba50b0e67df25cbd3b48f95831a77a4d53a581d55f063972fcb146d142c5f"
  end

  def install
    # Install the main application to libexec to avoid conflicts
    libexec.install Dir["*"]
    
    # Create the main CLI wrapper script
    (bin/"ios-deploy").write ios_deploy_script
    
    # Make the wrapper executable
    chmod 0755, bin/"ios-deploy"
    
    # Create man page directory and install documentation
    man1.mkpath
    (man1/"ios-deploy.1").write man_page_content
    
    # Install Ruby gems using bundler
    system "#{Formula["ruby@3.2"].opt_bin}/gem", "install", "bundler", "--no-document"
    
    # Set up Ruby environment
    ENV["GEM_HOME"] = libexec/"vendor"
    ENV["BUNDLE_PATH"] = libexec/"vendor"
    
    # Install gems from Gemfile
    cd libexec do
      system "#{Formula["ruby@3.2"].opt_bin}/bundle", "install", "--deployment", "--without", "development"
    end
    
    # Create configuration directory
    (etc/"ios-deploy").mkpath
    
    # Install example configuration
    (etc/"ios-deploy/config.example").write config_example_content
    
    # Create logs directory
    (var/"log/ios-deploy").mkpath
  end

  def ios_deploy_script
    <<~EOS
      #!/usr/bin/env bash
      
      # iOS FastLane Auto Deploy - Homebrew CLI Wrapper
      # Version: 2.3.0
      
      set -e
      
      # Configuration
      INSTALL_DIR="#{libexec}"
      CONFIG_DIR="#{etc}/ios-deploy"
      LOG_DIR="#{var}/log/ios-deploy"
      RUBY_PATH="#{Formula["ruby@3.2"].opt_bin}/ruby"
      BUNDLE_PATH="#{Formula["ruby@3.2"].opt_bin}/bundle"
      
      # Ruby environment setup
      export GEM_HOME="$INSTALL_DIR/vendor"
      export BUNDLE_PATH="$INSTALL_DIR/vendor"
      export PATH="$GEM_HOME/bin:$PATH"
      
      # Ensure we're in a valid iOS project directory
      check_ios_project() {
          if [[ ! -f "*.xcodeproj/project.pbxproj" && ! -f "*.xcworkspace/contents.xcworkspacedata" ]]; then
              if [[ "$1" != "init" && "$1" != "help" && "$1" != "version" ]]; then
                  echo "❌ Error: Not in an iOS project directory"
                  echo "   Please run this command from your iOS project root directory"
                  echo "   (directory containing .xcodeproj or .xcworkspace)"
                  exit 1
              fi
          fi
      }
      
      # Show usage information
      show_usage() {
          cat <<EOF
      📱 iOS FastLane Auto Deploy v2.3.0
      Enterprise-grade iOS TestFlight automation platform
      
      USAGE:
          ios-deploy <command> [options]
      
      COMMANDS:
          deploy                Deploy app to TestFlight (same as build_and_upload)
          build_and_upload      Complete build and TestFlight upload
          setup_certificates    Set up certificates and provisioning profiles
          status               Show current configuration status
          init                 Initialize project with apple_info structure
          validate_machine     Validate machine certificates
          help                 Show this help message
          version              Show version information
      
      REQUIRED PARAMETERS:
          team_id="XXXXXXXXXX"                 Apple Developer Team ID
          app_identifier="com.company.app"     Bundle identifier  
          apple_id="dev@email.com"             Apple Developer email
          api_key_id="YOUR_KEY_ID"             App Store Connect API Key ID
          api_issuer_id="your-issuer-uuid"     API Issuer ID
          app_name="Your App"                  Display name
          scheme="YourScheme"                  Xcode scheme
      
      OPTIONAL PARAMETERS:
          api_key_path="AuthKey_XXX.p8"               API key filename (auto-detected)
          apple_info_dir="/custom/path"               Apple info base directory
          version_bump="patch|minor|major|auto|sync"  Version increment strategy
          testflight_enhanced="true|false"           Enhanced TestFlight confirmation
          p12_password="password"                     P12 certificate password
      
      EXAMPLES:
          # Initialize a new project
          ios-deploy init
          
          # Deploy to TestFlight
          ios-deploy deploy \\
              team_id="NA5574MSN5" \\
              app_identifier="com.myapp" \\
              apple_id="dev@email.com" \\
              api_key_id="ABC123" \\
              api_issuer_id="12345678-1234-1234-1234-123456789012" \\
              app_name="My App" \\
              scheme="MyApp"
              
          # Deploy with enhanced TestFlight confirmation
          ios-deploy deploy \\
              team_id="NA5574MSN5" \\
              testflight_enhanced="true" \\
              [... other parameters]
              
      CONFIGURATION:
          Global config: #{etc}/ios-deploy/config.env
          Project config: ./apple_info/config.env
          
      DOCUMENTATION:
          man ios-deploy        Show manual page
          ios-deploy help       Show this help
          
      For detailed documentation, visit:
      https://github.com/snooky23/ios-deploy-platform
      EOF
      }
      
      # Initialize project structure
      init_project() {
          echo "🚀 Initializing iOS FastLane Auto Deploy structure..."
          
          # Create apple_info directory structure
          mkdir -p apple_info/{certificates,profiles}
          
          # Copy example configuration
          if [[ -f "$CONFIG_DIR/config.example" ]]; then
              cp "$CONFIG_DIR/config.example" apple_info/config.env
              echo "✅ Created apple_info/config.env from template"
          fi
          
          cat <<EOF
      
      ✅ Project initialized successfully!
      
      NEXT STEPS:
      1. Add your Apple Developer credentials to apple_info/:
         - API key file: apple_info/AuthKey_XXXXX.p8
         - Certificates: apple_info/certificates/*.p12
         
      2. Edit apple_info/config.env with your team details
      
      3. Run your first deployment:
         ios-deploy deploy team_id="YOUR_TEAM_ID" app_identifier="com.your.app" [...]
      
      EOF
      }
      
      # Main command dispatch
      main() {
          case "$1" in
              "help"|"--help"|"-h"|"")
                  show_usage
                  ;;
              "version"|"--version"|"-v")
                  echo "iOS FastLane Auto Deploy v2.3.0"
                  echo "Built with ❤️  for iOS developers"
                  ;;
              "init")
                  init_project
                  ;;
              "deploy"|"build_and_upload"|"setup_certificates"|"validate_machine"|"status")
                  check_ios_project "$1"
                  # Change to installation directory and run the original deploy.sh
                  cd "$INSTALL_DIR"
                  export FL_SCRIPTS_DIR="$INSTALL_DIR/scripts"
                  exec "$INSTALL_DIR/scripts/deploy.sh" "$@"
                  ;;
              *)
                  echo "❌ Unknown command: $1"
                  echo "Run 'ios-deploy help' for usage information"
                  exit 1
                  ;;
          esac
      }
      
      main "$@"
    EOS
  end

  def man_page_content
    <<~EOS
      .TH IOS-DEPLOY 1 "January 2025" "ios-deploy 2.3.0" "iOS Development Tools"
      .SH NAME
      ios-deploy \\- Enterprise-grade iOS TestFlight automation platform
      
      .SH SYNOPSIS
      .B ios-deploy
      .I command
      .RI [ options ]
      
      .SH DESCRIPTION
      .B ios-deploy
      is an enterprise-grade iOS TestFlight automation platform that provides complete end-to-end deployment automation from certificate management to TestFlight upload verification.
      
      Key features include:
      .IP \\[bu] 2
      Complete TestFlight publishing pipeline with upload verification
      .IP \\[bu]
      Smart provisioning profile management with reuse capabilities
      .IP \\[bu]
      Multi-team directory structure and collaboration support
      .IP \\[bu]
      Intelligent version management with conflict resolution
      .IP \\[bu]
      Temporary keychain security with automatic cleanup
      .IP \\[bu]
      Enhanced TestFlight confirmation with real-time status polling
      
      .SH COMMANDS
      .TP
      .B deploy, build_and_upload
      Complete build and TestFlight upload process
      
      .TP
      .B setup_certificates
      Set up certificates and provisioning profiles
      
      .TP
      .B status
      Show current configuration and deployment status
      
      .TP
      .B init
      Initialize project with apple_info directory structure
      
      .TP
      .B validate_machine
      Validate machine certificates and configuration
      
      .TP
      .B help
      Show usage information
      
      .TP
      .B version
      Show version information
      
      .SH REQUIRED OPTIONS
      .TP
      .BI team_id= ID
      Apple Developer Team ID (e.g., "NA5574MSN5")
      
      .TP
      .BI app_identifier= BUNDLE_ID
      App bundle identifier (e.g., "com.company.app")
      
      .TP
      .BI apple_id= EMAIL
      Apple Developer account email
      
      .TP
      .BI api_key_id= KEY_ID
      App Store Connect API Key ID
      
      .TP
      .BI api_issuer_id= UUID
      App Store Connect API Issuer ID
      
      .TP
      .BI app_name= NAME
      Application display name
      
      .TP
      .BI scheme= SCHEME
      Xcode build scheme name
      
      .SH OPTIONAL OPTIONS
      .TP
      .BI api_key_path= PATH
      API key filename (auto-detected if not specified)
      
      .TP
      .BI apple_info_dir= PATH
      Custom path to apple_info directory
      
      .TP
      .BI version_bump= STRATEGY
      Version increment strategy: patch, minor, major, auto, or sync
      
      .TP
      .BI testflight_enhanced= BOOL
      Enable enhanced TestFlight confirmation and logging (true/false)
      
      .TP
      .BI p12_password= PASSWORD
      Password for P12 certificate files
      
      .SH FILES
      .TP
      .I apple_info/config.env
      Project-specific configuration file
      
      .TP
      .I apple_info/AuthKey_*.p8
      App Store Connect API key files
      
      .TP
      .I apple_info/certificates/*.p12
      Certificate files for code signing
      
      .TP
      .I apple_info/profiles/*.mobileprovision
      Provisioning profile files
      
      .SH EXAMPLES
      Initialize a new project:
      .RS
      ios-deploy init
      .RE
      
      Deploy to TestFlight:
      .RS
      ios-deploy deploy team_id="NA5574MSN5" app_identifier="com.myapp" apple_id="dev@email.com" api_key_id="ABC123" api_issuer_id="12345678-1234-1234-1234-123456789012" app_name="My App" scheme="MyApp"
      .RE
      
      Deploy with enhanced TestFlight monitoring:
      .RS
      ios-deploy deploy testflight_enhanced="true" [other_parameters...]
      .RE
      
      .SH ENVIRONMENT
      .TP
      .B GEM_HOME
      Ruby gem installation directory
      
      .TP
      .B BUNDLE_PATH
      Bundler gem path
      
      .TP
      .B FL_SCRIPTS_DIR
      FastLane scripts directory
      
      .SH EXIT STATUS
      .TP
      .B 0
      Success
      
      .TP
      .B 1
      General error (missing parameters, invalid project directory, etc.)
      
      .TP
      .B 2
      Deployment failure (build failed, upload failed, etc.)
      
      .SH AUTHOR
      Avi Levin
      
      .SH REPORTING BUGS
      Report bugs to: https://github.com/snooky23/ios-deploy-platform/issues
      
      .SH COPYRIGHT
      Copyright \\[co] 2025 Avi Levin. Licensed under the MIT License.
      
      .SH SEE ALSO
      .BR fastlane (1),
      .BR xcodebuild (1),
      .BR xcrun (1)
    EOS
  end

  def config_example_content
    <<~EOS
      # iOS FastLane Auto Deploy - Configuration Template
      # Copy this file to your project's apple_info/config.env and customize
      
      # Apple Developer Team Configuration
      TEAM_ID="YOUR_TEAM_ID"
      APPLE_ID="your-developer@email.com"
      
      # App Store Connect API Configuration
      API_KEY_ID="YOUR_API_KEY_ID"
      API_ISSUER_ID="12345678-1234-1234-1234-123456789012"
      API_KEY_PATH="AuthKey_XXXXX.p8"
      
      # Application Configuration
      APP_IDENTIFIER="com.yourcompany.yourapp"
      APP_NAME="Your App Name"
      SCHEME="YourAppScheme"
      
      # Deployment Configuration
      VERSION_BUMP="patch"  # patch, minor, major, auto, sync
      TESTFLIGHT_ENHANCED="false"  # true for extended confirmation & logging
      
      # Certificate Configuration (optional)
      P12_PASSWORD="auto-generated-if-not-provided"
      
      # Directory Configuration (optional)
      # APPLE_INFO_DIR="/custom/path/to/apple_info"  # Uncomment to use custom path
      
      # Deployment Status Tracking (automatically updated)
      LAST_DEPLOYMENT=""
      LAST_BUILD_NUMBER=""
      LAST_VERSION=""
      DEPLOYMENT_STATUS=""
      
      # Notes:
      # - Parameters passed to ios-deploy command override these values
      # - Remove or comment out any line to use command-line parameters
      # - API keys and certificates should be placed in apple_info/ directory
    EOS
  end

  def caveats
    <<~EOS
      🍺 iOS FastLane Auto Deploy has been installed!
      
      ⚠️  IMPORTANT SETUP STEPS:
      
      1. Initialize your iOS project:
         cd /path/to/your/ios/project
         ios-deploy init
      
      2. Add your Apple Developer credentials to apple_info/:
         - API key: apple_info/AuthKey_XXXXX.p8
         - Certificates: apple_info/certificates/*.p12
         - Edit: apple_info/config.env
      
      3. Run your first deployment:
         ios-deploy deploy team_id="YOUR_TEAM_ID" app_identifier="com.your.app" [...]
      
      📚 DOCUMENTATION:
      - Quick help: ios-deploy help
      - Manual page: man ios-deploy
      - GitHub: https://github.com/snooky23/ios-deploy-platform
      
      🔧 REQUIREMENTS:
      - macOS with Xcode Command Line Tools
      - Valid Apple Developer account
      - App Store Connect API key
      
      🎯 This tool is designed for enterprise iOS teams and provides
         complete TestFlight automation with intelligent certificate management.
    EOS
  end

  test do
    # Test that the CLI wrapper is properly installed and executable
    assert_match "iOS FastLane Auto Deploy v2.3.0", shell_output("#{bin}/ios-deploy version")
    
    # Test help command
    assert_match "Enterprise-grade iOS TestFlight automation", shell_output("#{bin}/ios-deploy help")
    
    # Test that Ruby and gems are properly installed
    system "#{Formula["ruby@3.2"].opt_bin}/ruby", "-e", "require 'fastlane'"
  end
end