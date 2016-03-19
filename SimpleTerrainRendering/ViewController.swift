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
    
    @IBOutlet weak var solidWireFrameSwitch: UISwitch!
    @IBOutlet weak var triangulationTypeSegementedControl: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var terrain = TerrainData(width: 128, height: 128)
        terrain.randomize(min: 0, max: 15)
        terrain.smooth()
        
        terrainView!.context = EAGLContext(API: .OpenGLES1)
        terrainView!.data = terrain
        terrainView.hmax = 8;
        terrainView.hmin = 2;
        
        singleTap.delaysTouchesBegan = true
        doubleTap.delaysTouchesBegan = true
        singleTap.requireGestureRecognizerToFail(doubleTap)
        
        self.solidWireFrameSwitch?.on = terrainView.isWireframe
        self.triangulationTypeSegementedControl?.selectedSegmentIndex = terrainView.triangulationType
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
        terrainView.data?.randomize(min: 0, max: 15)
        terrainView.data?.smooth()
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

    @IBAction func solidWireFrameSwitched(sender: UISwitch) {
        self.terrainView.isWireframe = sender.on
        self.terrainView.setNeedsDisplay()
    }
    @IBAction func triangulationTypeChanged(sender: UISegmentedControl) {
        self.terrainView.triangulationType = sender.selectedSegmentIndex
        self.terrainView.setNeedsDisplay()
    }
}

