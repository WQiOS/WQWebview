
Pod::Spec.new do |s|

s.name         = "WQWebview"
s.version      = "0.0.1"
s.summary      = "WKWebView的封装"
s.homepage     = "https://github.com/WQiOS/WQWebview"
s.license      = "MIT"
s.author       = { "王强" => "1570375769@qq.com" }
s.platform     = :ios, "8.0" #平台及支持的最低版本
s.requires_arc = true # 是否启用ARC
s.source       = { :git => "https://github.com/WQiOS/WQWebview.git", :tag => "#{s.version}" }
s.source_files = "WQWebview/*.{h,m}"
s.ios.framework  = 'UIKit'

end
