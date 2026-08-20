# Uncomment the next line to define a global platform for your project
platform :ios, '13.0'

target 'ABank' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # SnapKit - Auto Layout DSL
  pod 'SnapKit', '~> 5.6.0'
  
  # 可以后续添加其他常用库
  # pod 'Kingfisher', '~> 7.0'  # 图片加载
  # pod 'MJRefresh', '~> 3.7'   # 下拉刷新

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
    end
  end
end

