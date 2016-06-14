Pod::Spec.new do |s|
s.name         = "QTPaySDK"
s.version      = "0.0.4"
s.summary      = "A Pay SDK of QFPay Inc. Include WeChat Pay, AliPay etc."
s.description  = <<-DESC
A Pay SDK of QFPay Inc. Include WeChat Pay, AliPay etc.
* Enables every transaction.
DESC
s.homepage     = "http://www.qfpay.com/"
s.author       = { "bjxiaowanzi" => "zhoucheng@qfpay.com" }
s.license      = "MIT"
s.ios.platform = :ios, '6.0'
s.source       = { :git => "https://github.com/bjxiaowanzi/QTPaySDK-iOS.git", :tag => "#{s.version}" }
s.requires_arc = true
s.ios.public_header_files  = "**/*.framework/**/*.h"
s.vendored_libraries  = "**/*.a"
s.vendored_frameworks = "**/*.framework"
s.preserve_paths = "**/*.framework"
s.resources    = "**/*.bundle"
s.frameworks = 'Foundation', 'UIKit', 'CoreLocation', 'SystemConfiguration', 'MobileCoreServices'
s.libraries = ["z", "c++", "sqlite3"]
s.xcconfig  = { "OTHER_LDFLAGS" => "-lObjC",'LD_RUNPATH_SEARCH_PATHS' => '"$(SRCROOT)/**/*.framework"' }
end