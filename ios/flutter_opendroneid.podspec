#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_opendroneid.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_opendroneid'
  s.version          = '1.0.0'
  s.summary          = 'iOS implementation for reading Wi-Fi and Bluetooth Remote ID advertisements as Flutter plugin'
  s.authors          = 'Dronetag s.r.o.'
  s.license          = {}
  s.homepage         = 'https://github.com/dronetag/flutter-opendroneid'
  s.source           = { :path => '.' }
  # Sources moved under the Swift package so one tree serves both CocoaPods
  # and SwiftPM; see flutter_opendroneid/Package.swift.
  s.source_files     = 'flutter_opendroneid/Sources/flutter_opendroneid/**/*.swift'
  s.platform         = :ios, '12.0'
  
  s.dependency 'Flutter'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
