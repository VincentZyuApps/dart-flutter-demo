Pod::Spec.new do |s|
  s.name             = 'system_info_vincentzyu'
  s.version          = '0.1.0'
  s.summary          = 'Typed system information for Flutter.'
  s.description      = <<-DESC
Cross-platform system information with field-level source diagnostics.
                       DESC
  s.homepage         = 'https://github.com/VincentZyuApps/dart-flutter-demo'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'VincentZyuApps' => '1830540513zyu@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.resource_bundles = { 'system_info_vincentzyu_privacy' => ['Resources/PrivacyInfo.xcprivacy'] }
  s.dependency 'FlutterMacOS'
  s.platform = :osx, '10.15'
  s.swift_version = '5.0'
end
