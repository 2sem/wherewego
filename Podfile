# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

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

  pod 'LSExtensions', :path => '~/Projects/leesam/pods/LSExtensions/src/LSExtensions'
  pod 'GADManager', '1.2.22'#, :path => '~/Projects/leesam/pods/GADManager/src/GADManager'
  pod 'StringLogger'

  pod 'SDWebImage'#, '~> 4.0'
  
  # Add the pod for Firebase Crashlytics
  pod 'Firebase/Crashlytics'

  # Recommended: Add the Firebase pod for Google Analytics
  pod 'Firebase/Analytics'

  pod 'Firebase/RemoteConfig'
  

  target 'wherewegoTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'wherewegoUITests' do
    inherit! :search_paths
    # Pods for testing
  end

end
