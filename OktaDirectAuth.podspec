Pod::Spec.new do |s|
    s.name             = "OktaDirectAuth"
    s.version          = "1.8.2"
    s.summary          = "Okta Direct Authentication"
    s.description      = <<-DESC
Enables application developers to build native sign in experiences using the Okta Direct Authentication API.
                         DESC
    s.platforms = {
        :ios     => "10.0",
        :tvos    => "10.0",
        :watchos => "7.0",
        :osx     => "10.12"
    }
    s.ios.deployment_target     = "10.0"
    s.tvos.deployment_target    = "10.0"
    s.watchos.deployment_target = "7.0"
    s.osx.deployment_target     = "10.12"

    s.homepage      = "https://github.com/okta/okta-mobile-swift"
    s.license       = { :type => "APACHE2", :file => "LICENSE" }
    s.authors       = { "Okta Developers" => "developer@okta.com"}
    s.source        = { :git => "https://github.com/okta/okta-mobile-swift.git", :tag => s.version.to_s }
    s.source_files  = "Sources/OktaDirectAuth/**/*.swift"
    s.resource_bundles = { "OktaDirectAuth" => "Sources/OktaDirectAuth/Resources/**/*" }
    s.swift_version = "5.6"

    s.dependency "OktaAuthFoundation", "#{s.version.to_s}"
end
