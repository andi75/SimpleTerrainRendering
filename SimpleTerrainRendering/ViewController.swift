	//
//  ViewController.swift
//  SimpleTerrainRendering
//
//  Created by Andreas Umbach on 20/12/15.
//  Copyright © 2015 Andreas Umbach. All rights reserved.
//

// TODO: add support for all the keyboard commands from the OSX version
    
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
    
    let qt = QuadTreeTerrain(maxLevel: 7)
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if(
            (gestureRecognizer == singlePan && otherGestureRecognizer == doublePan) ||
            (gestureRecognizer == doublePan && otherGestureRecognizer == singlePan)
        )
        {
            return true;
        }
        return false;
    }
    
    func recreateTerrain()
    {
        TerrainFactory.recreateQuadTerrain(self.qt)
        terrainView!.renderer.xyScale = 1
        terrainView!.renderer.data = TerrainData(qt: qt, level: qt.maxLevel)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        recreateTerrain()
        
        terrainView!.context = EAGLContext(api: .openGLES1)
        terrainView!.renderer.cam = TerrainCamera(terrain: terrainView!.renderer.data!)
        
        singleTap.delaysTouchesBegan = true
        doubleTap.delaysTouchesBegan = true
        singleTap.require(toFail: doubleTap)
        
//        singlePan.delaysTouchesBegan = true
//        doublePan.delaysTouchesBegan = true
//        singlePan.requireGestureRecognizerToFail(doublePan)
//        singlePan.delegate = self
//        doublePan.delegate = self
        
        
        self.solidWireFrameSwitch?.isOn = terrainView.renderer.isWireframe
        self.triangulationTypeSegementedControl?.selectedSegmentIndex = terrainView.renderer.triangulationType
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func viewTapped(_ sender: UITapGestureRecognizer) {
        // only do this once at the moment, but might actually make this user editable
        let interations = 1
        for _ in 0..<interations
        {
            terrainView.renderer.data?.smooth()
        }
        terrainView.setNeedsDisplay()
        print("smoothed")
    }
    
    @IBAction func viewDoubletapped(_ sender: UITapGestureRecognizer) {
        recreateTerrain()
        terrainView.setNeedsDisplay()
        print("randomized")
    }
    
    @IBAction func turnViewPoint(_ sender: UIPanGestureRecognizer) {
        
        if(sender.state == .changed)
        {
            let delta = sender.translation(in: terrainView)
         
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
            sender.setTranslation(CGPoint.zero, in: terrainView)
            // print(sender.translationInView(terrainView))
            terrainView.setNeedsDisplay()
        }
    }

    @IBAction func moveLeftRightForwardBackwardPlanar(_ sender: UIPanGestureRecognizer) {
        if(sender.state == .changed)
        {
            let delta = sender.translation(in: terrainView)
            
            print("(moveLeftRightForwardBackward by \(delta.x), \(delta.y)")

            terrainView.renderer.cam?.forwardBackwardPlanar(Float(-delta.y))
            terrainView.renderer.cam?.leftRight(Float(delta.x))
            
            sender.setTranslation(CGPoint.zero, in: terrainView)
            // print(sender.translationInView(terrainView))
            terrainView.setNeedsDisplay()
        }
    }
    
    @IBAction func moveUpDown(_ sender: UIPanGestureRecognizer) {
        if(sender.state == .changed)
        {
            let delta = sender.translation(in: terrainView)
            
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

            sender.setTranslation(CGPoint.zero, in: terrainView)
            // print(sender.translationInView(terrainView))
            terrainView.setNeedsDisplay()
        }
    }
    @IBAction func zoomInOrOut(_ sender: UIPinchGestureRecognizer) {
        if(sender.state == .began)
        {
            self.lastZoom = 1
        }
        if(sender.state == .changed)
        {
            print("scale: \(sender.scale), velocity: \(sender.velocity)")
            terrainView.renderer.cam?.zoomInOrOut(Float(sender.scale) / self.lastZoom)
            self.lastZoom = Float(sender.scale)
        }
        terrainView.setNeedsDisplay()
    }
    
    @IBAction func solidWireFrameSwitched(_ sender: UISwitch) {
        self.terrainView.renderer.isWireframe = sender.isOn
        self.terrainView.setNeedsDisplay()
    }
    @IBAction func triangulationTypeChanged(_ sender: UISegmentedControl) {
        self.terrainView.renderer.triangulationType = sender.selectedSegmentIndex
        self.terrainView.setNeedsDisplay()
    }
}

