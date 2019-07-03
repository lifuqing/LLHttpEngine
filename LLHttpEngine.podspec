
Pod::Spec.new do |s|

  s.name         = "LLHttpEngine"
  s.version      = "1.0.4"
  s.summary      = "网络请求中间件"
  s.description  = "网络请求中间件"
  s.license      = {:type => 'MIT', :file => 'LICENSE'}
  s.homepage     = "https://github.com/lifuqing/LLHttpEngine"
  s.author       = { "lifuqing" => "lfqing@vip.qq.com" }
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/lifuqing/LLHttpEngine.git", :tag => s.name.to_s + "-" + s.version.to_s}
  s.source_files = "#{s.name}/Classes/**/*.{h,m,mm}"
  

  s.requires_arc = true
  s.frameworks   = 'Foundation', 'UIKit', 'AVFoundation'

  s.dependency 'AFNetworking'
  s.dependency 'YYModel'
  
end
