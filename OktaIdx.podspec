Pod::Spec.new do |spec|
  spec.name             = 'OktaIdx'
  spec.version          = '3.0.4'
  spec.summary          = 'SDK to easily integrate the Okta Identity Engine'
  spec.description      = <<-DESC
Integrate your native app with Okta using the Okta Identity Engine library.
                       DESC
  spec.platforms = {
    :ios     => "10.0",
    :tvos    => "10.0",
    :watchos => "7.0",
    :osx     => "10.11"
  }
  spec.ios.deployment_target     = "10.0"
  spec.tvos.deployment_target    = "10.0"
  spec.watchos.deployment_target = "7.0"
  spec.osx.deployment_target     = "10.11"

  spec.homepage         = 'https://github.com/okta/okta-idx-swift'
  spec.license          = { :type => 'APACHE2', :file => 'LICENSE' }
  spec.authors          = { "Okta Developers" => "developer@okta.com"}
  spec.source           = { :git => 'https://github.com/okta/okta-idx-swift.git', :tag => spec.version.to_s }

  spec.source_files = 'Sources/OktaIdx/**/*.swift'
  spec.swift_version = "5.5"

  spec.dependency "OktaAuthFoundation", "1.1.4"
end
