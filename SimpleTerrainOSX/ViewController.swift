//
//  ViewController.swift
//  SimpleTerrainOSX
//
//  Created by Andreas Umbach on 10.07.2016.
//  Copyright © 2016 Andreas Umbach. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet weak var terrainViewOSX: TerrainViewOSX!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let terrain = TerrainData(width: 128, height: 128)
        terrain.randomize(min: 0, max: 15)
        terrain.smooth()
        
        // don't think we need that on OS X
        // terrainViewOSX!.context = EAGLContext(API: .OpenGLES1)
        
        terrainViewOSX!.renderer.data = terrain
        terrainViewOSX.renderer.hmax = 8;
        terrainViewOSX.renderer.hmin = 2;
        
        terrainViewOSX!.renderer.cam = TerrainCamera(terrain: terrain)
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

