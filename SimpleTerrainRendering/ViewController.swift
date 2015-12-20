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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var terrain = TerrainData(width: 4, height: 4)
        // terrain.randomize(min: 5, max: 10)
        terrainView!.context = EAGLContext(API: .OpenGLES1)
        
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

