#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint geolocation.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'geolocation'
  s.version          = '0.0.1'
  s.summary          = 'A new flutter plugin project.'
  s.description      = <<-DESC
Flutter Geolocation plugin for iOS and Android.
                       DESC
  s.homepage         = 'https://github.com/loup-v/geolocation'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Loup Inc.' => 'hello@loup.app' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'streams_channel'
  s.frameworks = 'CoreLocation'
  s.platform = :ios, '9.0'

  # Flutter.framework does not contain a i386 slice. Only x86_64 simulators are supported.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64' }
  s.swift_version = '5.0'
end
