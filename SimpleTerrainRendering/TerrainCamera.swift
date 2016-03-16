//
//  TerrainCamera.swift
//  SimpleTerrainRendering
//
//  Created by Andreas Umbach on 22.12.2015.
//  Copyright © 2015 Andreas Umbach. All rights reserved.
//

import GLKit

class TerrainCamera {
    var eye : GLKVector3
    var lookAt : GLKVector3
    var up : GLKVector3 = GLKVector3( v: (0, 0, 1) )
    var terrain : TerrainData
    
    var distance : Float = 1.5
    
    init(terrain : TerrainData)
    {
        self.terrain = terrain
        self.lookAt = GLKVector3( v: ( Float(terrain.rect.midX), Float(terrain.rect.midY), 0 ) )
        let viewDir = GLKVector3( v: (-distance * Float(terrain.rect.width), -distance * Float(terrain.rect.width), -distance * Float(terrain.rect.width) ) )
        self.eye = GLKVector3Subtract(lookAt, viewDir)
    }
    
    func lookAtMatrix() -> [Float]
    {
        return [Float]()
    }
    
}