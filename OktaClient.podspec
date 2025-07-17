Pod::Spec.new do |s|
    s.name         = "OktaClient"
    s.version      = "2.0.2"
    s.summary      = "Secure client authentication, request authorization, and user management capabilities for Swift."
    s.description  = <<-DESC
Provides a modularized set of libraries that provide the building blocks and convenience features used to authenticate users, manage the lifecycle and storage of tokens and user credentials, and provide a base for other libraries and applications to build upon.

NOTE: This Swift-based pod requires `use_frameworks!` in your Podfile.
                   DESC
    s.homepage     = "https://github.com/okta/okta-mobile-swift"
    s.license      = { :type => "Apache-2.0", :file => "LICENSE" }
    s.author       = { "Okta Developers" => "developer@okta.com" }
    s.source       = { :git => "https://github.com/okta/okta-mobile-swift.git", :tag => "#{s.version}" }
 
    s.ios.deployment_target      = '13.0'
    s.tvos.deployment_target     = '16.0'
    s.watchos.deployment_target  = '7.0'
    s.osx.deployment_target      = '10.15'
    s.visionos.deployment_target = '1.0'
 
    s.swift_versions = ['5.10', '6.0']
 
    s.source_files = []
    s.module_map = "Sources/CocoaPods/OktaClient.modulemap"
 
    common_swift_flags = [
        '-Xfrontend', '-enable-upcoming-feature',
        '-Xfrontend', 'ExistentialAny',
        '-strict-concurrency=complete'
    ]
 
    s.subspec 'AuthFoundation' do |ss|
        ss.ios.deployment_target      = '13.0'
        ss.tvos.deployment_target     = '16.0'
        ss.watchos.deployment_target  = '7.0'
        ss.osx.deployment_target      = '10.15'
        ss.visionos.deployment_target = '1.0'
       
        ss.dependency 'OktaAuthFoundation', "~> #{s.version.to_s}"
    end
 
    s.subspec 'OAuth2' do |ss|
        ss.ios.deployment_target      = '13.0'
        ss.tvos.deployment_target     = '16.0'
        ss.watchos.deployment_target  = '7.0'
        ss.visionos.deployment_target = '1.0'
        ss.osx.deployment_target      = '10.15'
       
        ss.dependency 'OktaClient/AuthFoundation'
        ss.dependency 'OktaOAuth2', "~> #{s.version.to_s}"
    end
  
    s.subspec 'DirectAuth' do |ss|
        ss.ios.deployment_target      = '13.0'
        ss.tvos.deployment_target     = '16.0'
        ss.watchos.deployment_target  = '7.0'
        ss.visionos.deployment_target = '1.0'
        ss.osx.deployment_target      = '10.15'

        ss.dependency 'OktaClient/AuthFoundation'
        ss.dependency 'OktaDirectAuth', "~> #{s.version.to_s}"
    end

    s.subspec 'IdxAuth' do |ss|
        ss.ios.deployment_target      = '13.0'
        ss.tvos.deployment_target     = '16.0'
        ss.watchos.deployment_target  = '7.0'
        ss.visionos.deployment_target = '1.0'
        ss.osx.deployment_target      = '10.15'
       
        ss.dependency 'OktaClient/AuthFoundation'
        ss.dependency 'OktaIdxAuth', "~> #{s.version.to_s}"
    end
  
    s.subspec 'BrowserSignin' do |ss|
        ss.ios.deployment_target      = '13.0'
        ss.tvos.deployment_target     = '16.0'
        ss.watchos.deployment_target  = '7.0'
        ss.visionos.deployment_target = '1.0'
        ss.osx.deployment_target      = '10.15'
       
        ss.dependency 'OktaClient/OAuth2'
        ss.dependency 'OktaBrowserSignin', "~> #{s.version.to_s}"
    end
end
