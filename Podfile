# Uncomment the next line to define a global platform for your project
 platform :ios, '13.0'

target 'wherewego' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  inhibit_all_warnings!

  # Pods for wherewego
  pod 'GoogleMaps'
#  pod 'GooglePlaces'
  pod 'Material'
  pod 'KakaoOpenSDK'
  pod 'DownPicker'
  pod 'MBProgressHUD'
#  pod 'Firebase/Core'
#  pod 'Firebase/AdMob'
#  pod 'Google-Mobile-Ads-SDK'

  pod 'LSExtensions'#, :path => '~/Projects/leesam/pods/LSExtensions/src/LSExtensions'
  pod 'GADManager'#, :path => '~/Projects/leesam/pods/GADManager/src/GADManager'
  pod 'StringLogger'

  pod 'SDWebImage'#, '~> 4.0'
  
  # Add the pod for Firebase Crashlytics
  pod 'Firebase/Crashlytics'

  # Recommended: Add the Firebase pod for Google Analytics
  pod 'Firebase/Analytics'

  pod 'Firebase/RemoteConfig'
  
  post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '11.0'
        config.build_settings['EXPANDED_CODE_SIGN_IDENTITY'] = ''
        config.build_settings['CODE_SIGNING_REQUIRED'] = 'NO'
        config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
      end
    end
  end
  
  target 'wherewegoTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'wherewegoUITests' do
    inherit! :search_paths
    # Pods for testing
  end

end
