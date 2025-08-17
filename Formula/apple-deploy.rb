class AppleDeploy < Formula
  desc "Enterprise-grade iOS TestFlight automation platform with Clean Architecture and intelligent certificate management"
  homepage "https://github.com/snooky23/apple-deploy"
  url "https://github.com/snooky23/apple-deploy/archive/refs/tags/v2.12.6.tar.gz"
  sha256 "d1a88f785faf1ef9947eed6be64621b8d6a95a8512e23a8789ae8ffbcad40022"
  license "MIT"
  version "2.12.6"

  # Dependencies
  depends_on "ruby@3.2"
  depends_on "fastlane"
  
  # macOS-specific dependencies (iOS development is macOS-only)
  depends_on :macos
  
  # Optional but recommended dependencies  
  depends_on "cocoapods" => :optional


  def install
    # Install the main application to libexec to avoid conflicts
    libexec.install Dir["*"]
    
    # Create the main CLI wrapper script
    (bin/"apple-deploy").write ios_deploy_script
    
    # Make the wrapper executable
    chmod 0755, bin/"apple-deploy"
    
    # Create man page directory and install documentation
    man1.mkpath
    (man1/"apple-deploy.1").write man_page_content
    
    # Skip bundler installation as it may already be present
    
    # Set up Ruby environment
    ENV["GEM_HOME"] = libexec/"vendor"
    ENV["BUNDLE_PATH"] = libexec/"vendor"
    
    # Skip gem installation - let runtime handle it
    
    # Create configuration directory
    (etc/"apple-deploy").mkpath
    
    # Install example configuration
    (etc/"apple-deploy/config.example").write config_example_content
    
    # Create logs directory
    (var/"log/apple-deploy").mkpath
  end

  def ios_deploy_script
    <<~EOS
      #!/usr/bin/env bash
      
      # iOS FastLane Auto Deploy - Homebrew CLI Wrapper
      # Version: 2.12.6
      
      set -e
      
      # Configuration
      INSTALL_DIR="#{libexec}"
      CONFIG_DIR="#{etc}/apple-deploy"
      LOG_DIR="#{var}/log/apple-deploy"
      RUBY_PATH="#{Formula["ruby@3.2"].opt_bin}/ruby"
      BUNDLE_PATH="#{Formula["ruby@3.2"].opt_bin}/bundle"
      
      # Ruby environment setup
      export GEM_HOME="$INSTALL_DIR/vendor"
      export BUNDLE_PATH="$INSTALL_DIR/vendor"
      export PATH="$GEM_HOME/bin:$PATH"
      
      # Ensure we're in a valid iOS project directory
      check_ios_project() {
          # Check if we're in an iOS project directory
          if [[ "$1" != "init" && "$1" != "help" && "$1" != "version" ]]; then
              if ! ls *.xcodeproj/project.pbxproj >/dev/null 2>&1 && ! ls *.xcworkspace/contents.xcworkspacedata >/dev/null 2>&1; then
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
      📱 Apple Deploy v2.12.6
      Enterprise-grade iOS TestFlight automation platform with Clean Architecture
      
      USAGE:
          apple-deploy <command> [options]
      
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
          api_key_path="AuthKey_XXX.p8"        API key filename
          api_key_id="YOUR_KEY_ID"             App Store Connect API Key ID
          api_issuer_id="your-issuer-uuid"     API Issuer ID
          app_name="Your App"                  Display name
          scheme="YourScheme"                  Xcode scheme
      
      OPTIONAL PARAMETERS:
          version_bump="patch|minor|major"  Version increment strategy
          testflight_enhanced="true|false"           Enhanced TestFlight confirmation
          p12_password="password"                     P12 certificate password
          apple_info_dir="/custom/path"               Custom apple_info location
      
      EXAMPLES:
          # Initialize a new project
          apple-deploy init
          
          # Deploy to TestFlight
          apple-deploy deploy \\
              team_id="YOUR_TEAM_ID" \\
              app_identifier="com.myapp" \\
              apple_id="dev@email.com" \\
              api_key_path="AuthKey_ABC123.p8" \\
              api_key_id="ABC123" \\
              api_issuer_id="12345678-1234-1234-1234-123456789012" \\
              app_name="My App" \\
              scheme="MyApp"
              
          # Deploy with enhanced TestFlight confirmation
          apple-deploy deploy \\
              team_id="YOUR_TEAM_ID" \\
              testflight_enhanced="true" \\
              [... other parameters]
              
      CONFIGURATION:
          Global config: #{etc}/apple-deploy/config.env
          Project config: ./apple_info/config.env
          
      DOCUMENTATION:
          man apple-deploy        Show manual page
          apple-deploy help       Show this help
          
      For detailed documentation, visit:
      https://github.com/snooky23/apple-deploy
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
         apple-deploy deploy team_id="YOUR_TEAM_ID" app_identifier="com.your.app" ...
      
      EOF
      }
      
      # Main command dispatch
      main() {
          case "$1" in
              "help"|"--help"|"-h"|"")
                  show_usage
                  ;;
              "version"|"--version"|"-v")
                  echo "Apple Deploy v2.12.6"
                  echo "Built with ❤️  for iOS developers - Enhanced Clean Architecture"
                  ;;
              "init")
                  init_project
                  ;;
              "deploy"|"build_and_upload"|"setup_certificates"|"validate_machine"|"status")
                  check_ios_project "$1"
                  # Set up environment and run deploy.sh from current directory
                  export FL_SCRIPTS_DIR="$INSTALL_DIR/scripts"
                  exec "$INSTALL_DIR/scripts/deploy.sh" "$@"
                  ;;
              *)
                  echo "❌ Unknown command: $1"
                  echo "Run 'apple-deploy help' for usage information"
                  exit 1
                  ;;
          esac
      }
      
      main "$@"
    EOS
  end

  def man_page_content
    <<~EOS
      .TH APPLE-DEPLOY 1 "January 2025" "apple-deploy 2.12.6" "iOS Development Tools"
      .SH NAME
      apple-deploy \\- Enterprise-grade iOS TestFlight automation platform
      
      .SH SYNOPSIS
      .B apple-deploy
      .I command
      .RI [ options ]
      
      .SH DESCRIPTION
      .B apple-deploy
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
      Apple Developer Team ID (e.g., "YOUR_TEAM_ID")
      
      .TP
      .BI app_identifier= BUNDLE_ID
      App bundle identifier (e.g., "com.company.app")
      
      .TP
      .BI apple_id= EMAIL
      Apple Developer account email
      
      .TP
      .BI api_key_path= PATH
      App Store Connect API key filename (e.g., "AuthKey_ABC123.p8")
      
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
      .BI version_bump= STRATEGY
      Version increment strategy: patch, minor, or major
      
      .TP
      .BI testflight_enhanced= BOOL
      Enable enhanced TestFlight confirmation and logging (true/false)
      
      .TP
      .BI p12_password= PASSWORD
      Password for P12 certificate files
      
      .TP
      .BI apple_info_dir= PATH
      Custom path to apple_info directory
      
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
      apple-deploy init
      .RE
      
      Deploy to TestFlight:
      .RS
      apple-deploy deploy team_id="YOUR_TEAM_ID" app_identifier="com.myapp" apple_id="dev@email.com" api_key_path="AuthKey_ABC123.p8" api_key_id="ABC123" api_issuer_id="12345678-1234-1234-1234-123456789012" app_name="My App" scheme="MyApp"
      .RE
      
      Deploy with enhanced TestFlight monitoring:
      .RS
      apple-deploy deploy testflight_enhanced="true" [other_parameters...]
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
      Report bugs to: https://github.com/snooky23/apple-deploy/issues
      
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
      VERSION_BUMP="patch"  # patch, minor, major
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
      # - Parameters passed to apple-deploy command override these values
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
         apple-deploy init
      
      2. Add your Apple Developer credentials to apple_info/:
         - API key: apple_info/AuthKey_XXXXX.p8
         - Certificates: apple_info/certificates/*.p12
         - Edit: apple_info/config.env
      
      3. Run your first deployment:
         apple-deploy deploy team_id="YOUR_TEAM_ID" app_identifier="com.your.app" [...]
      
      📚 DOCUMENTATION:
      - Quick help: apple-deploy help
      - Manual page: man apple-deploy
      - GitHub: https://github.com/snooky23/apple-deploy
      
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
    assert_match "Apple Deploy v2.12.6", shell_output("#{bin}/apple-deploy version")
    
    # Test help command
    assert_match "Enterprise-grade iOS TestFlight automation", shell_output("#{bin}/apple-deploy help")
    
    # Test that Ruby and gems are properly installed
    system "#{Formula["ruby@3.2"].opt_bin}/ruby", "-e", "require 'fastlane'"
  end
end