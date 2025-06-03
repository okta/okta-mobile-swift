Pod::Spec.new do |s|
    s.name             = "OktaWebAuthenticationUI"
    s.module_name      = "WebAuthenticationUI"
    s.version          = "2.0.0"
    s.summary          = "Okta Web Authentication UI"
    s.description      = <<-DESC
Authenticate users using web-based OIDC.
                         DESC
    s.platforms = {
        :ios      => "13.0",
        :tvos     => "16.0",
        :watchos  => "7.0",
        :visionos => "1.0",
        :osx      => "10.15"
    }
    s.ios.deployment_target      = "13.0"
    s.tvos.deployment_target     = "16.0"
    s.watchos.deployment_target  = "7.0"
    s.visionos.deployment_target = "1.0"
    s.osx.deployment_target      = "10.15"

    s.homepage      = "https://github.com/okta/okta-mobile-swift"
    s.license       = { :type => "APACHE2", :file => "LICENSE" }
    s.authors       = { "Okta Developers" => "developer@okta.com"}
    s.source        = { :git => "https://github.com/okta/okta-mobile-swift.git", :tag => s.version.to_s }

    s.source_files  = "Sources/WebAuthenticationUI/**/*.swift"
    s.resource_bundles = { "WebAuthenticationUI" => "Sources/WebAuthenticationUI/Resources/**/*" }
    s.swift_versions = ['5.10', '6.0']
    s.prefix_header_file = false

    s.dependency "OktaOAuth2", "~> #{s.version.to_s}"
end
