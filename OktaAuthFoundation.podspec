Pod::Spec.new do |s|
    s.name             = "OktaAuthFoundation"
    s.module_name      = "AuthFoundation"
    s.version          = "2.0.0"
    s.summary          = "Okta Authentication Foundation"
    s.description      = <<-DESC
Provides the foundation and common features used to authenticate users, managing the lifecycle and storage of tokens and credentials, and provide a base for other Okta SDKs to build upon.
                         DESC
    s.swift_version = "5.10"
    s.platforms = {
        :ios      => "13.0",
        :tvos     => "13.0",
        :visionos => "1.0",
        :watchos  => "7.0",
        :macos    => "10.15",
        :osx      => "10.15"
    }
    s.ios.deployment_target      = "13.0"
    s.tvos.deployment_target     = "13.0"
    s.visionos.deployment_target = "1.0"
    s.watchos.deployment_target  = "7.0"
    s.macos.deployment_target    = "10.15"
    s.osx.deployment_target      = "10.15"

    s.homepage      = "https://github.com/okta/okta-mobile-swift"
    s.license       = { :type => "APACHE2", :file => "LICENSE" }
    s.authors       = { "Okta Developers" => "developer@okta.com"}
    s.source        = { :git => "https://github.com/okta/okta-mobile-swift.git", :tag => s.version.to_s }

    s.subspec "OktaConcurrency" do |ss|
      ss.name         = "OktaConcurrency"
      ss.source_files = "Sources/OktaConcurrency/**/*.swift"
      ss.preserve_paths = ["Package.swift", "Sources/OktaClientMacros/**/*.swift"]
      script = <<-SCRIPT.squish
          env -i PATH="$PATH" "$SHELL" -l -c
          "swift build -c release --product OktaClientMacros
          --sdk \\"`xcrun --show-sdk-path`\\"
          --package-path \\"$PODS_TARGET_SRCROOT\\"
          --scratch-path \\"${PODS_BUILD_DIR}/Macros/OktaClientMacros\\""
          SCRIPT
      ss.script_phase = {
        :name => 'Build OktaClientMacros plugin',
        :script => script,
        :input_files => Dir.glob("{Package.swift,Sources/OktaClientMacros/**/*.swift}").map {
          |path| "$(PODS_TARGET_SRCROOT)/#{path}"
        },
        :output_files => ['$(PODS_BUILD_DIR)/Macros/OktaClientMacros/release/OktaClientMacros'],
        :execution_position => :before_compile
      }
      ss.user_target_xcconfig = {
        'OTHER_SWIFT_FLAGS' => <<-FLAGS.squish
        -Xfrontend -load-plugin-executable
        -Xfrontend ${PODS_BUILD_DIR}/Macros/OktaClientMacros/release/OktaClientMacros#OktaClientMacros
        FLAGS
      }
    end

    s.subspec "OktaUtilities" do |ss|
      ss.name         = "OktaUtilities"
      ss.source_files = "Sources/OktaUtilities/**/*.swift"
      ss.dependency "OktaAuthFoundation/OktaConcurrency"
    end

    s.subspec "APIClient" do |ss|
      ss.name         = "APIClient"
      ss.source_files = "Sources/APIClient/**/*.swift"
      ss.resources    = "Sources/APIClient/Resources/**/*"
      ss.dependency "OktaAuthFoundation/OktaUtilities"
    end

    s.subspec "JWT" do |ss|
      ss.name         = "JWT"
      ss.source_files = "Sources/JWT/**/*.swift"
      ss.resources    = "Sources/JWT/Resources/**/*"
      ss.dependency "OktaAuthFoundation/OktaUtilities"
      ss.dependency "OktaAuthFoundation/OktaConcurrency"
      ss.dependency "OktaAuthFoundation/APIClient"
    end

    s.subspec "Keychain" do |ss|
      ss.name         = "Keychain"
      ss.source_files = "Sources/Keychain/**/*.swift"
      ss.resources    = "Sources/Keychain/Resources/**/*"
      ss.dependency "OktaAuthFoundation/OktaConcurrency"
    end

    s.subspec "Core" do |ss|
      ss.source_files     = "Sources/AuthFoundation/**/*.swift"
      ss.resource_bundles = { "AuthFoundation" => "Sources/AuthFoundation/Resources/**/*" }
      ss.dependency "OktaAuthFoundation/OktaUtilities"
      ss.dependency "OktaAuthFoundation/OktaConcurrency"
      ss.dependency "OktaAuthFoundation/Keychain"
      ss.dependency "OktaAuthFoundation/APIClient"
      ss.dependency "OktaAuthFoundation/JWT"
    end

    s.default_subspecs = "Core"
end
