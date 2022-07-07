#
# Be sure to run `pod lib lint ExcelReader.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'ExcelReader'
  s.version          = '0.1.0'
  s.summary          = 'A short description of ExcelReader.'
  s.homepage         = 'www.example.com' 
  s.author           = { 'tw' => '' }
  s.source           = { :git => '.', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '12.0'

  s.vendored_framework = 'build/xcframework/ExcelReader.xcframework'

  s.libraries = 'iconv'
end
