//
//  SimpleTerrainView.swift
//  SimpleTerrainRendering
//
//  Created by Andreas Umbach on 20/12/15.
//  Copyright © 2015 Andreas Umbach. All rights reserved.
//

import GLKit

class SimpleTerrainView : GLKView
{
    let renderer = TerrainRenderer()
    
    override func draw(_ rect: CGRect) {
        renderer.renderTerrain(width: self.frame.width, height: self.frame.height)
    }
}


