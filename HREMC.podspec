Pod::Spec.new do |s|

  s.name         = "HREMC"
  s.version      = "1.0.0"
  s.summary      = "haier HREMC"

  s.homepage     = "https://github.com/hanyuantao/HREMC.git"
  s.license      = { :type => "MIT", :file => "FILE_LICENSE" }

  s.author             = { "once" => "545574484@qq.com" }
  # s.platform     = :ios
  s.platform     = :ios, "7"

  #  When using multiple platforms
  # s.ios.deployment_target = "5.0"
  # s.osx.deployment_target = "10.7"
  # s.watchos.deployment_target = "2.0"
  # s.tvos.deployment_target = "9.0"


  # s.source       = { :git => "https://github.com/hanyuantao/HREMC.git", :tag => "1.0.0" }
  s.source       = { :git => "https://github.com/hanyuantao/HREMC.git", :commit => "0d6761feefccff1f7d8b7c7788ceb8e9cd1314ea" }


  # s.source_files  = "HREMC/", "HREMC/.{h,m}"
  s.source_files  = "HREMC/*.{h,m}"
  # s.source_files  = "HREMC/", "HREMC.{h,m}"
  # s.source_files  = "HREMC/**/*.{h,m}"

  # s.exclude_files = "Classes/Exclude"
  # s.public_header_files = "Classes/**/*.h"
  # s.resource  = "icon.png"
  # s.resources = "Resources/*.png"

  # s.preserve_paths = "FilesToSave", "MoreFilesToSave"
  # s.framework  = "SomeFramework"
  # s.frameworks = "SomeFramework", "AnotherFramework"
  s.frameworks = "UIKit", "Foundation" ,"CoreTelephony", "CoreGraphics", "QuartzCore", "SystemConfiguration", "AudioToolbox", "AddressBook", "AVFoundation", "CoreLocation", "AssetsLibrary"
  # s.vendored_frameworks  = "HREMC/iflyMSC.framework"

  # s.library   = "iconv"
  # s.libraries = "iconv", "xml2"
  s.libraries = "c++", "z"



  s.requires_arc = true

  # s.xcconfig = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include/libxml2" }
  # s.dependency "JSONKit", "~> 1.4"
  s.dependency "AFNetworking", "~> 3.1.0"
  s.dependency "QRScan", "~> 1.0.1"

end
