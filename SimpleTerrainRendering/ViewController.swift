	//
//  ViewController.swift
//  SimpleTerrainRendering
//
//  Created by Andreas Umbach on 20/12/15.
//  Copyright © 2015 Andreas Umbach. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIGestureRecognizerDelegate {

    @IBOutlet weak var terrainView: SimpleTerrainView!
    
    @IBOutlet weak var singleTap: UITapGestureRecognizer!
    @IBOutlet weak var doubleTap: UITapGestureRecognizer!
    
    @IBOutlet weak var singlePan: UIPanGestureRecognizer!
    @IBOutlet weak var doublePan: UIPanGestureRecognizer!
    
    @IBOutlet weak var solidWireFrameSwitch: UISwitch!
    @IBOutlet weak var triangulationTypeSegementedControl: UISegmentedControl!
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if(
            (gestureRecognizer == singlePan && otherGestureRecognizer == doublePan) ||
            (gestureRecognizer == doublePan && otherGestureRecognizer == singlePan)
        )
        {
            return true;
        }
        return false;
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        var terrain = TerrainData(width: 128, height: 128)
        terrain.randomize(min: 0, max: 15)
        terrain.smooth()
        
        terrainView!.context = EAGLContext(API: .OpenGLES1)

        terrainView!.data = terrain
        terrainView.hmax = 8;
        terrainView.hmin = 2;
        
        terrainView!.cam = TerrainCamera(terrain: terrain)
        
        singleTap.delaysTouchesBegan = true
        doubleTap.delaysTouchesBegan = true
        singleTap.requireGestureRecognizerToFail(doubleTap)
        
//        singlePan.delaysTouchesBegan = true
//        doublePan.delaysTouchesBegan = true
//        singlePan.requireGestureRecognizerToFail(doublePan)
//        singlePan.delegate = self
//        doublePan.delegate = self
        
        
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
    
    @IBAction func turnViewPoint(sender: UIPanGestureRecognizer) {
        
        if(sender.state == .Changed)
        {
            let delta = sender.translationInView(terrainView)
         
            print("(turnView by \(delta.x), \(delta.y)")
            
            terrainView.cam?.phi += Float(delta.x) * 0.01
            terrainView.cam?.chi += Float(delta.y) * 0.01
            print("chi: \(terrainView.cam!.chi / Float(M_PI))")
            
//            if(delta.y < 0)
//            {
//                terrainView.distance *= 0.95
//            }
//            else
//            {
//                terrainView.distance /= 0.95
//            }
            sender.setTranslation(CGPointZero, inView: terrainView)
            // print(sender.translationInView(terrainView))
            terrainView.setNeedsDisplay()
        }
    }

    @IBAction func moveLeftRightForwardBackwardPlanar(sender: UIPanGestureRecognizer) {
        if(sender.state == .Changed)
        {
            let delta = sender.translationInView(terrainView)
            
            print("(moveLeftRightForwardBackward by \(delta.x), \(delta.y)")

            terrainView.cam?.forwardBackwardPlanar(Float(-delta.y))
            terrainView.cam?.leftRight(Float(delta.x))
            
            sender.setTranslation(CGPointZero, inView: terrainView)
            // print(sender.translationInView(terrainView))
            terrainView.setNeedsDisplay()
        }
    }
    
    @IBAction func moveUpDown(sender: UIPanGestureRecognizer) {
        if(sender.state == .Changed)
        {
            let delta = sender.translationInView(terrainView)
            
            print("(moveUpDown by \(delta.x), \(delta.y)")
            
            terrainView.cam?.lowerHigher(Float(delta.y))
            
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

