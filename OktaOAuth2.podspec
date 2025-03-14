Pod::Spec.new do |s|
    s.name             = "OktaOAuth2"
    s.version          = "1.8.2"
    s.summary          = "Okta OAuth2 Authentication"
    s.description      = <<-DESC
Enables application developers to authenticate users utilizing a variety of OAuth2 authentication flows.
                         DESC
    s.platforms = {
        :ios      => "13.0",
        :tvos     => "13.0",
        :visionos => "1.0",
        :watchos  => "7.0",
        :osx      => "10.15"
    }
    s.ios.deployment_target      = "13.0"
    s.tvos.deployment_target     = "13.0"
    s.visionos.deployment_target = "1.0"
    s.watchos.deployment_target  = "7.0"
    s.osx.deployment_target      = "10.15"

    s.homepage      = "https://github.com/okta/okta-mobile-swift"
    s.license       = { :type => "APACHE2", :file => "LICENSE" }
    s.authors       = { "Okta Developers" => "developer@okta.com"}
    s.source        = { :git => "https://github.com/okta/okta-mobile-swift.git", :tag => s.version.to_s }
    s.source_files  = "Sources/OktaOAuth2/**/*.swift"
    s.resource_bundles = { "OktaOAuth2" => "Sources/OktaOAuth2/Resources/**/*" }
    s.swift_version = "5.10"

    s.dependency "OktaAuthFoundation", "#{s.version.to_s}"
end
