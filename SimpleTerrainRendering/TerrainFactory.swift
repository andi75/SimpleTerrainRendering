//
//  TerrainFactory.swift
//  SimpleTerrainRendering
//
//  Created by Andreas Umbach on 14.07.2016.
//  Copyright © 2016 Andreas Umbach. All rights reserved.
//

import Foundation

class TerrainFactory
{
    class func recreateQuadTerrain(qt: QuadTreeTerrain)
    {
        var maxNoise : Float = 15.0
        
        qt.setDataAt(0, x: 0, y: 0, value: 0.0)
        
        for level in 0..<qt.maxLevel
        {
            qt.copyFromUpperLevel(level)
            qt.addRandomNoiseToLevel(level + 1, maxNoise: maxNoise)
            maxNoise *= 0.4
        }
        for level in 0...qt.maxLevel
        {
            qt.crop(level, minHeight: 0.5, maxHeight: 100)
        }        
    }
}