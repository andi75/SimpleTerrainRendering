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
    
    var lastZoom : Float = 1
    
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
        let terrain = TerrainData(width: 128, height: 128)
        terrain.randomize(min: 0, max: 15)
        terrain.smooth()
        
        terrainView!.context = EAGLContext(API: .OpenGLES1)

        terrainView!.renderer.data = terrain
        terrainView.renderer.hmax = 8;
        terrainView.renderer.hmin = 2;
        
        terrainView!.renderer.cam = TerrainCamera(terrain: terrain)
        
        singleTap.delaysTouchesBegan = true
        doubleTap.delaysTouchesBegan = true
        singleTap.requireGestureRecognizerToFail(doubleTap)
        
//        singlePan.delaysTouchesBegan = true
//        doublePan.delaysTouchesBegan = true
//        singlePan.requireGestureRecognizerToFail(doublePan)
//        singlePan.delegate = self
//        doublePan.delegate = self
        
        
        self.solidWireFrameSwitch?.on = terrainView.renderer.isWireframe
        self.triangulationTypeSegementedControl?.selectedSegmentIndex = terrainView.renderer.triangulationType
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func viewTapped(sender: UITapGestureRecognizer) {
        // only do this once at the moment, but might actually make this user editable
        let interations = 1
        for _ in 0..<interations
        {
            terrainView.renderer.data?.smooth()
        }
        terrainView.setNeedsDisplay()
        print("smoothed")
    }
    
    @IBAction func viewDoubletapped(sender: UITapGestureRecognizer) {
        terrainView.renderer.data?.randomize(min: 0, max: 15)
        terrainView.renderer.data?.smooth()
        terrainView.setNeedsDisplay()
        print("randomized")
    }
    
    @IBAction func turnViewPoint(sender: UIPanGestureRecognizer) {
        
        if(sender.state == .Changed)
        {
            let delta = sender.translationInView(terrainView)
         
//            print("(turnView by \(delta.x), \(delta.y)")
            
            terrainView.renderer.cam?.phi += Float(delta.x) * 0.01
            terrainView.renderer.cam?.chi += Float(delta.y) * 0.01
//            print("chi: \(terrainView.cam!.chi / Float(M_PI))")
            
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

            terrainView.renderer.cam?.forwardBackwardPlanar(Float(-delta.y))
            terrainView.renderer.cam?.leftRight(Float(delta.x))
            
            sender.setTranslation(CGPointZero, inView: terrainView)
            // print(sender.translationInView(terrainView))
            terrainView.setNeedsDisplay()
        }
    }
    
    @IBAction func moveUpDown(sender: UIPanGestureRecognizer) {
        if(sender.state == .Changed)
        {
            let delta = sender.translationInView(terrainView)
            
//            print("(moveUpDown by \(delta.x), \(delta.y)")

            let hitResult = terrainView.renderer.data!.intersectWithRay(
                terrainView.renderer.cam!.eye,
                direction: terrainView.renderer.cam!.viewDir
            )

            if(hitResult.isHit)
            {
                terrainView.renderer.cam?.lowerHigherWithFocus(Float(delta.y), focus: hitResult.location)
            }
            else
            {
                terrainView.renderer.cam?.lowerHigher(Float(delta.y))
            }

            sender.setTranslation(CGPointZero, inView: terrainView)
            // print(sender.translationInView(terrainView))
            terrainView.setNeedsDisplay()
        }
    }
    @IBAction func zoomInOrOut(sender: UIPinchGestureRecognizer) {
        if(sender.state == .Began)
        {
            self.lastZoom = 1
        }
        if(sender.state == .Changed)
        {
            print("scale: \(sender.scale), velocity: \(sender.velocity)")
            terrainView.renderer.cam?.zoomInOrOut(Float(sender.scale) / self.lastZoom)
            self.lastZoom = Float(sender.scale)
        }
        terrainView.setNeedsDisplay()
    }
    
    @IBAction func solidWireFrameSwitched(sender: UISwitch) {
        self.terrainView.renderer.isWireframe = sender.on
        self.terrainView.setNeedsDisplay()
    }
    @IBAction func triangulationTypeChanged(sender: UISegmentedControl) {
        self.terrainView.renderer.triangulationType = sender.selectedSegmentIndex
        self.terrainView.setNeedsDisplay()
    }
}

