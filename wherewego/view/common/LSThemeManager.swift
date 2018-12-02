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
    
    enum Theme{
        case `default`
        case xmas
    }
    
    var theme : Theme = .xmas;
    
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
    }
    
    class NavigationBarTintColors{
        //static var red : UIColor? = "#EF5350".toUIColor();
        static var red : UIColor? = UIColor.white;
    }
    
    class NavigationBarBackgroundColors{
        //static var red : UIColor? = "#EF5350".toUIColor();
        static var red : UIColor? = MaterialColors.red.red400;
    }
    
    class NavigationBarTitleColors{
        //static var red : UIColor? = "#EF5350".toUIColor();
        static var red : UIColor? = MaterialColors.red.red50;
    }
    
    class BackgroundColors{
        //static var red : UIColor? = "#EF5350".toUIColor();
        static var red : UIColor? = MaterialColors.red.red400;
    }
    
    class ImageViewBackgroundColors{
        //static var red : UIColor? = "#EF5350".toUIColor();
        static var red : UIColor? = UIColor.white;
    }
    
    class ImageViewBorderColors{
        //static var red : UIColor? = "#EF5350".toUIColor();
        static var red : UIColor? = MaterialColors.red.red50;
    }
    
    class ImageViewBorderWidths{
        //static var red : UIColor? = "#EF5350".toUIColor();
        static var red : CGFloat = 2.0;
    }
    
    class BarButtonItemTintColors{
        //static var red : UIColor? = "#EF5350".toUIColor();
        static var red : UIColor? = UIColor.white;
    }
    
    class ButtonTintColors{
        //static var red : UIColor? = "#EF5350".toUIColor();
        static var red : UIColor? = UIColor.white;
    }
    
    class RoundButtonBackgroundColors{
        //static var red : UIColor? = "#EF5350".toUIColor();
        static var red : UIColor? = MaterialColors.red.red300;
    }
    
    class RoundButtonTintColors{
        //static var red : UIColor? = "#EF5350".toUIColor();
        static var red : UIColor? = UIColor.white;
    }
    
    class LabelTextColors{
        //static var red : UIColor? = "#EF5350".toUIColor();
        static var red : UIColor? = UIColor.white;
    }
    
    class SliderThumbColors{
        //static var red : UIColor? = "#EF5350".toUIColor();
        static var red : UIColor? = MaterialColors.red.red50;
    }
    
    class SliderMinTrackColors{
        //static var red : UIColor? = "#EF5350".toUIColor();
        static var red : UIColor? = MaterialColors.red.red100;
    }
    
    class SliderMaxTrackColors{
        //static var red : UIColor? = "#EF5350".toUIColor();
        static var red : UIColor? = MaterialColors.red.red300;
    }
    
    class RefreshControlTextColors{
        //static var red : UIColor? = "#EF5350".toUIColor();
        static var red : UIColor? = UIColor.white;
    }
    
    class RefreshControlTintColors{
        //static var red : UIColor? = "#EF5350".toUIColor();
        static var red : UIColor = UIColor.white;
    }
    
    var statusBarStyle: UIStatusBarStyle{
        switch self.theme{
            case .xmas:
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
        default:
            break;
        }
    }
    
    func apply(barButtonItem : UIBarButtonItem?){
        switch self.theme {
        case .xmas:
            //barButtonItem?.tintColor
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
        default:
            break;
        }
    }
    
    func apply(label : UILabel?){
        switch self.theme {
        case .xmas:
            label?.textColor = LabelTextColors.red;
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
        default:
            break;
        }
    }
}
