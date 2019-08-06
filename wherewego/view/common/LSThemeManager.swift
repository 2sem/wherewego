//
//  LSThemeManager.swift
//  wherewego
//
//  Created by 영준 이 on 2018. 11. 29..
//  Copyright © 2018년 leesam. All rights reserved.
//

import UIKit
import LSExtensions

class LSThemeManager{
    static let shared = LSThemeManager();
    
    enum Theme : String{
        case `default`
        case summer = "summer"
        case xmas = "xmas"
    }
    
    var theme : Theme = LSRemoteConfig.shared.theme;
    
    class MaterialColors{
        class red{
            static var `red50` : UIColor? = "#FFEBEE".toUIColor();
            static var `red100` : UIColor? = "#FFCDD2".toUIColor();
            static var `red200` : UIColor? = "#EF9A9A".toUIColor();
            static var `red300` : UIColor? = "#E57373".toUIColor();
            static var `red400` : UIColor? = "#EF5350".toUIColor();
            static var `red500` : UIColor? = "#F44336".toUIColor();
            static var `red600` : UIColor? = "#E53935".toUIColor();
            static var `red700` : UIColor? = "#D32F2F".toUIColor();

        }
        class lightBlue{
            static var _50 : UIColor? = "#E1F5FE".toUIColor();
            static var _100 : UIColor? = "#B3E5FC".toUIColor();
            static var _200 : UIColor? = "#81D4FA".toUIColor();
            static var _300 : UIColor? = "#4FC3F7".toUIColor();
            static var _400 : UIColor? = "#29B6F6".toUIColor();
            static var _500 : UIColor? = "#03A9F4".toUIColor();
            static var _600 : UIColor? = "#039BE5".toUIColor();
            static var _700 : UIColor? = "#0288D1".toUIColor();
            
        }
    }
    
    class NavigationBarTintColors{
        //static var red : UIColor? = "#EF5350".toUIColor();
        static var red : UIColor? = UIColor.white;
        static var lightBlue : UIColor? = UIColor.white;
    }
    
    class NavigationBarBackgroundColors{
        //static var red : UIColor? = "#EF5350".toUIColor();
        static var red : UIColor? = MaterialColors.red.red400;
        static var lightBlue : UIColor? = MaterialColors.lightBlue._400;
    }
    
    class NavigationBarTitleColors{
        //static var red : UIColor? = "#EF5350".toUIColor();
        static var red : UIColor? = MaterialColors.red.red50;
        static var lightBlue : UIColor? = MaterialColors.lightBlue._50;
    }
    
    class BackgroundColors{
        //static var red : UIColor? = "#EF5350".toUIColor();
        static var red : UIColor? = MaterialColors.red.red400;
        static var lightBlue : UIColor? = MaterialColors.lightBlue._400;
    }
    
    class ImageViewBackgroundColors{
        //static var red : UIColor? = "#EF5350".toUIColor();
        static var red : UIColor? = UIColor.white;
        static var lightBlue : UIColor? = UIColor.white;
    }
    
    class ImageViewBorderColors{
        //static var red : UIColor? = "#EF5350".toUIColor();
        static var red : UIColor? = MaterialColors.red.red50;
        static var lightBlue : UIColor? = MaterialColors.lightBlue._50;
    }
    
    class ImageViewBorderWidths{
        //static var red : UIColor? = "#EF5350".toUIColor();
        static var red : CGFloat = 2.0;
        static var lightBlue : CGFloat = 2.0;
    }
    
    class BarButtonItemTintColors{
        //static var red : UIColor? = "#EF5350".toUIColor();
        static var red : UIColor? = UIColor.white;
        static var lightBlue : UIColor? = UIColor.white;
    }
    
    class ButtonTintColors{
        //static var red : UIColor? = "#EF5350".toUIColor();
        static var red : UIColor? = UIColor.white;
        static var lightBlue : UIColor? = UIColor.white;
    }
    
    class RoundButtonBackgroundColors{
        //static var red : UIColor? = "#EF5350".toUIColor();
        static var red : UIColor? = MaterialColors.red.red300;
        static var lightBlue : UIColor? = MaterialColors.lightBlue._300;
    }
    
    class RoundButtonTintColors{
        //static var red : UIColor? = "#EF5350".toUIColor();
        static var red : UIColor? = UIColor.white;
        static var lightBlue : UIColor? = UIColor.white;
    }
    
    class LabelTextColors{
        //static var red : UIColor? = "#EF5350".toUIColor();
        static var red : UIColor? = UIColor.white;
        static var lightBlue : UIColor? = UIColor.white;
    }
    
    class SliderThumbColors{
        //static var red : UIColor? = "#EF5350".toUIColor();
        static var red : UIColor? = MaterialColors.red.red50;
        static var lightBlue : UIColor? = MaterialColors.lightBlue._50;
    }
    
    class SliderMinTrackColors{
        //static var red : UIColor? = "#EF5350".toUIColor();
        static var red : UIColor? = MaterialColors.red.red100;
        static var lightBlue : UIColor? = MaterialColors.lightBlue._100;
    }
    
    class SliderMaxTrackColors{
        //static var red : UIColor? = "#EF5350".toUIColor();
        static var red : UIColor? = MaterialColors.red.red300;
        static var lightBlue : UIColor? = MaterialColors.lightBlue._300;
    }
    
    class RefreshControlTextColors{
        //static var red : UIColor? = "#EF5350".toUIColor();
        static var red : UIColor? = UIColor.white;
        static var lightBlue : UIColor? = UIColor.white;
    }
    
    class RefreshControlTintColors{
        //static var red : UIColor? = "#EF5350".toUIColor();
        static var red : UIColor = UIColor.white;
        static var lightBlue : UIColor = UIColor.white;
    }
    
    var statusBarStyle: UIStatusBarStyle{
        switch self.theme{
            case .xmas:
                return .lightContent;
            case .summer:
                return .lightContent;
            default:
                return .default;
        }
    }
    
    func apply(navigationController : UINavigationController?){
        //UINavigationBar().tintColor
        switch self.theme {
        case .xmas:
            self.apply(navigationBar: navigationController?.navigationBar);
            break;
        case .summer:
            self.apply(navigationBar: navigationController?.navigationBar);
            break;
        default:
            break;
        }
    }
    
    func apply(navigationBar : UINavigationBar?){
        //UINavigationBar().tintColor
        switch self.theme {
        case .xmas:
            navigationBar?.barTintColor = NavigationBarBackgroundColors.red;
            navigationBar?.tintColor = NavigationBarTintColors.red;
            if let _ = navigationBar?.titleTextAttributes{
                navigationBar?.titleTextAttributes?[.foregroundColor] = NavigationBarTitleColors.red;
            }else{
                navigationBar?.titleTextAttributes = [.foregroundColor : NavigationBarTitleColors.red];
            }
            break;
        case .summer:
            navigationBar?.barTintColor = NavigationBarBackgroundColors.lightBlue;
            navigationBar?.tintColor = NavigationBarTintColors.lightBlue;
            if let _ = navigationBar?.titleTextAttributes{
                navigationBar?.titleTextAttributes?[.foregroundColor] = NavigationBarTitleColors.lightBlue;
            }else{
                navigationBar?.titleTextAttributes = [.foregroundColor : NavigationBarTitleColors.lightBlue];
            }
            
            break;
        default:
            break;
        }
    }
    
    func apply(barButtonItem : UIBarButtonItem?){
        switch self.theme {
        case .xmas:
            //barButtonItem?.tintColor
            break;
        case .summer:
                break;
        default:
            break;
        }
    }
    
    func apply(barButton : UIButton?){
        switch self.theme {
        case .xmas:
            barButton?.tintColor = BarButtonItemTintColors.red;
            //barButton?.titleLabel?.textColor = BarButtonItemTintColors.red;
            barButton?.setTitleColor(BarButtonItemTintColors.red, for: .normal);
            break;
        case .summer:
            barButton?.tintColor = BarButtonItemTintColors.lightBlue;
            //barButton?.titleLabel?.textColor = BarButtonItemTintColors.red;
            barButton?.setTitleColor(BarButtonItemTintColors.lightBlue, for: .normal);
            break;
        default:
            break;
        }
    }
    
    func apply(button : UIButton?){
        switch self.theme {
        case .xmas:
            button?.tintColor = ButtonTintColors.red;
            //barButton?.titleLabel?.textColor = BarButtonItemTintColors.red;
            button?.setTitleColor(ButtonTintColors.red, for: .normal);
            break;
        case .summer:
            button?.tintColor = ButtonTintColors.lightBlue;
            //barButton?.titleLabel?.textColor = BarButtonItemTintColors.red;
            button?.setTitleColor(ButtonTintColors.lightBlue, for: .normal);
            break;
        default:
            break;
        }
    }
    
    func apply(roundButton : UIButton?){
        switch self.theme {
        case .xmas:
            roundButton?.tintColor = RoundButtonTintColors.red;
            //barButton?.titleLabel?.textColor = BarButtonItemTintColors.red;
            //roundButton?.setTitleColor(RoundButtonBackgroundColors.red, for: .normal);
            roundButton?.backgroundColor = RoundButtonBackgroundColors.red;
            break;
        case .summer:
            roundButton?.tintColor = RoundButtonTintColors.lightBlue;
            //barButton?.titleLabel?.textColor = BarButtonItemTintColors.red;
            //roundButton?.setTitleColor(RoundButtonBackgroundColors.red, for: .normal);
            roundButton?.backgroundColor = RoundButtonBackgroundColors.lightBlue;
            break;
        default:
            break;
        }
    }
    
    func apply(label : UILabel?){
        switch self.theme {
        case .xmas:
            label?.textColor = LabelTextColors.red;
            break;
        case .summer:
            label?.textColor = LabelTextColors.lightBlue;
            break;
        default:
            break;
        }
    }
    
    func apply(slider : UISlider?){
        switch self.theme {
        case .xmas:
            slider?.thumbTintColor = SliderThumbColors.red;
            slider?.minimumTrackTintColor = SliderMinTrackColors.red;
            slider?.maximumTrackTintColor = SliderMaxTrackColors.red;
            break;
        case .summer:
            slider?.thumbTintColor = SliderThumbColors.lightBlue;
            slider?.minimumTrackTintColor = SliderMinTrackColors.lightBlue;
            slider?.maximumTrackTintColor = SliderMaxTrackColors.lightBlue;
            break;
        default:
            break;
        }
    }
    
    func apply(imageView : UIImageView?){
        switch self.theme {
        case .xmas:
            imageView?.backgroundColor = ImageViewBackgroundColors.red;
            imageView?.borderUIColor = ImageViewBorderColors.red;
            //imageView?.borderWidth = ImageViewBorderWidths.red;
            break;
        case .summer:
            imageView?.backgroundColor = ImageViewBackgroundColors.lightBlue;
            imageView?.borderUIColor = ImageViewBorderColors.lightBlue;
            //imageView?.borderWidth = ImageViewBorderWidths.red;
            break;
        default:
            break;
        }
    }
    
    func apply(refreshControl : UIRefreshControl?){
        switch self.theme {
        case .xmas:
            if let refreshTitle = refreshControl?.attributedTitle{
                let title = NSMutableAttributedString.init(attributedString: refreshTitle);
                title.addAttribute(.foregroundColor, value: RefreshControlTextColors.red, range: refreshTitle.string.fullRange);
                refreshControl?.attributedTitle = title;
            }
            refreshControl?.tintColor = RefreshControlTintColors.red;
            break;
        case .summer:
            if let refreshTitle = refreshControl?.attributedTitle{
                let title = NSMutableAttributedString.init(attributedString: refreshTitle);
                title.addAttribute(.foregroundColor, value: RefreshControlTextColors.lightBlue, range: refreshTitle.string.fullRange);
                refreshControl?.attributedTitle = title;
            }
            refreshControl?.tintColor = RefreshControlTintColors.lightBlue;
            break;
        default:
            break;
        }
    }
    
    func apply(view : UIView?){
        
    }
    
    func apply(viewController : UIViewController?){
        switch self.theme {
        case .xmas:
            viewController?.view?.backgroundColor = BackgroundColors.red;
            break;
        case .summer:
            viewController?.view?.backgroundColor = BackgroundColors.lightBlue;
            break;
        default:
            break;
        }
    }
}
