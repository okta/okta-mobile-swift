Pod::Spec.new do |s|
    s.name             = "OktaOAuth2"
    s.version          = "1.0.0-RC1"
    s.summary          = "Okta OAuth2 Authentication"
    s.description      = <<-DESC
Enables application developers to authenticate users utilizing a variety of OAuth2 authentication flows.
                         DESC
    s.platforms = {
        :ios => "9.0",
        :tvos => "10.0",
        :watchos => "7.0",
        :osx => "10.11"
    }
    s.homepage         = "https://github.com/okta/okta-mobile-swift"
    s.license          = { :type => "APACHE2", :file => "LICENSE" }
    s.authors          = { "Okta Developers" => "developer@okta.com"}
    s.source           = { :git => "https://github.com/okta/okta-mobile-swift.git", :tag => s.version.to_s }
    s.swift_version = "5.5"
    s.ios.deployment_target = "9.0"
    s.tvos.deployment_target = "10.0"
    s.watchos.deployment_target = "7.0"
    s.osx.deployment_target = "10.11"
    s.source_files = "Sources/OktaOAuth2/**/*.swift"
    s.resources = "Sources/OktaOAuth2/Resources/*.lproj"
    s.dependency "AuthFoundation", "#{s.version.to_s}"
end
