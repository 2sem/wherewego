//
//  KGDImageViewController.swift
//  wherewego
//
//  Created by 영준 이 on 2017. 5. 19..
//  Copyright © 2017년 leesam. All rights reserved.
//

import UIKit

class KGDImageViewController: UIViewController {

    var image : UIImage?;
    
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.imageView.image = self.image;
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onShare(_ sender: Any) {
        self.share([self.image?.description ?? ""])
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
