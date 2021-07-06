Pod::Spec.new do |spec|
  spec.name             = 'OktaIdx'
  spec.version          = '0.1.0'
  spec.summary          = 'SDK to easily integrate the Okta Identity Engine'
  spec.description      = <<-DESC
Integrate your native app with Okta using the Okta Identity Engine library.
                       DESC
  spec.platforms    = { :ios => "10.0", :tvos => "10.0", :osx => "10.10"}
  spec.homepage         = 'https://github.com/okta/okta-idx-swift'
  spec.license          = { :type => 'APACHE2', :file => 'LICENSE' }
  spec.authors          = { "Okta Developers" => "developer@okta.com"}
  spec.source           = { :git => 'https://github.com/okta/okta-idx-swift.git', :tag => spec.version.to_s }
  spec.swift_version = '5.0'

  spec.source_files = 'Sources/OktaIdx/**/*.{h,swift}'
  spec.ios.deployment_target = '10.0'
  spec.osx.deployment_target = '10.10'

  spec.xcconfig = {
    'USER_HEADER_SEARCH_PATHS' => '${SRCROOT}/Sources/**'
  }
end
