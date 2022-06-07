Pod::Spec.new do |s|
    s.name             = "OktaWebAuthenticationUI"
    s.module_name      = "WebAuthenticationUI"
    s.version          = "0.5.0"
    s.summary          = "Okta Web Authentication UI"
    s.description      = <<-DESC
Authenticate users using web-based OIDC.
                         DESC
    s.platforms = {
        :ios => "9.0",
        :osx => "10.11"
    }
    s.ios.deployment_target = "9.0"
    s.osx.deployment_target = "10.11"

    s.homepage      = "https://github.com/okta/okta-mobile-swift"
    s.license       = { :type => "APACHE2", :file => "LICENSE" }
    s.authors       = { "Okta Developers" => "developer@okta.com"}
    s.source        = { :git => "https://github.com/okta/okta-mobile-swift.git", :tag => s.version.to_s }
    s.source_files  = "Sources/WebAuthenticationUI/**/*.swift"
    s.resources     = "Sources/WebAuthenticationUI/Resources/*.lproj"
    s.swift_version = "5.5"

    s.dependency "OktaAuthFoundation", "#{s.version.to_s}"
    s.dependency "OktaOAuth2", "#{s.version.to_s}"
end
