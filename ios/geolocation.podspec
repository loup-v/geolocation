Pod::Spec.new do |s|
  s.name             = 'geolocation'
  s.version          = '0.0.1'
  s.summary          = 'Geolocation plugin for iOS and Android.'
  s.description      = <<-DESC
Geolocation plugin for iOS and Android.
                       DESC
  s.homepage         = 'https://github.com/loup-v/geolocation'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Loup Inc.' => 'hello@intheloup.io' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'

  s.dependency 'Flutter'
  s.dependency 'streams_channel'
  s.frameworks = 'CoreLocation'
  s.ios.deployment_target = '9.0'
end