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
    
    override func drawRect(rect: CGRect) {
        renderer.render(width: self.frame.width, height: self.frame.height)
    }
}


