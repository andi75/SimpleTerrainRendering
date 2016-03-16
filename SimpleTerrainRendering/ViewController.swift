//
//  ViewController.swift
//  SimpleTerrainRendering
//
//  Created by Andreas Umbach on 20/12/15.
//  Copyright © 2015 Andreas Umbach. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var terrainView: SimpleTerrainView!
    
    @IBOutlet var singleTap: UITapGestureRecognizer!
    @IBOutlet var doubleTap: UITapGestureRecognizer!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var terrain = TerrainData(width: 128, height: 128)
        terrain.randomize(min: 0, max: 5)
        
        terrainView!.context = EAGLContext(API: .OpenGLES1)
        terrainView!.data = terrain
        terrainView.max = 5;
        terrainView.min = 0;
        
        singleTap.delaysTouchesBegan = true
        doubleTap.delaysTouchesBegan = true
        singleTap.requireGestureRecognizerToFail(doubleTap)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func viewTapped(sender: UITapGestureRecognizer) {
        terrainView.data?.smooth()
        terrainView.setNeedsDisplay()
        print("smoothed")
    }
    
    @IBAction func viewDoubletapped(sender: UITapGestureRecognizer) {
        terrainView.data?.randomize(min: 0, max: 5)
        terrainView.setNeedsDisplay()
        print("randomized")
    }
    
    @IBAction func viewPanned(sender: UIPanGestureRecognizer) {
        if(sender.state == .Changed)
        {
            if(sender.translationInView(terrainView).y < 0)
            {
                terrainView.distance *= 0.95
            }
            else
            {
                terrainView.distance /= 0.95
            }
            sender.setTranslation(CGPointZero, inView: terrainView)
            // print(sender.translationInView(terrainView))
            terrainView.setNeedsDisplay()
        }
    }

}

