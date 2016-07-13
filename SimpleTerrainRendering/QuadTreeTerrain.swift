//
//  QuadTreeTerrain.swift
//  SimpleTerrainRendering
//
//  Created by Andreas Umbach on 13.07.2016.
//  Copyright © 2016 Andreas Umbach. All rights reserved.
//

import Foundation

class QuadTreeTerrain
{
    var data: [Float]
    var maxLevel : Int
    
    class func getOffset(level : Int) -> Int
    {
        var offset = 0
        for i in 0..<level
        {
            let width = QuadTreeTerrain.getWidth(i)
            offset += width * width
        }
        return offset
    }
    
    class func getWidth(level : Int) -> Int
    {
        return (1 << level) + 1
    }
    
    func getDataAt(level: Int, x: Int, y: Int) -> Float
    {
        return data[QuadTreeTerrain.getOffset(level) + y * QuadTreeTerrain.getWidth(level) + x]
    }
    
    func setDataAt(level: Int, x: Int, y: Int, value: Float)
    {
        data[QuadTreeTerrain.getOffset(level) + y * QuadTreeTerrain.getWidth(level) + x] = value
    }
    
    init(maxLevel : Int)
    {
        self.maxLevel = maxLevel
        let size = QuadTreeTerrain.getOffset(maxLevel + 1)
        self.data = [Float](count: size, repeatedValue: 0.0)
    }
    
    func copyFromUpperLevel(upperLevel : Int)
    {
        if(upperLevel >= maxLevel)
        {
            print("upperLevel (\(upperLevel)) is equal or larger than maxLevel (\(maxLevel)) ")
            return
        }
        let curLevel = upperLevel + 1
        let curWidth = QuadTreeTerrain.getWidth(curLevel)
        
        for y in 0..<curWidth
        {
            for x in 0..<curWidth
            {
                if(x % 2 == 0 && y % 2 == 0)
                {
                    // nothing to interpolate
                    self.setDataAt(curLevel, x: x, y: y,
                                   value: self.getDataAt(upperLevel, x: x/2, y: y/2))
                }
                else if(x % 2 == 1 && y % 2 == 1)
                {
                    let value = 0.25 * (
                        self.getDataAt(upperLevel, x: x/2 + 0, y: y/2 + 0) +
                        self.getDataAt(upperLevel, x: x/2 + 1, y: y/2 + 0) +
                        self.getDataAt(upperLevel, x: x/2 + 0, y: y/2 + 1) +
                        self.getDataAt(upperLevel, x: x/2 + 1, y: y/2 + 1)
                    )
                    self.setDataAt(curLevel, x: x, y: y, value: value)
                }
                else
                {
                    // interpolate between two values
                    let value = 0.5 * (
                        self.getDataAt(upperLevel, x: x/2, y: y/2) +
                        self.getDataAt(upperLevel, x: x/2 + (x % 2), y: y/2 + (y % 2))
                    )
                    self.setDataAt(curLevel, x: x, y: y, value: value)
                }
            }
        }
    }
    
    func addRandomNoiseToLevel(level: Int, maxNoise: Float)
    {
        let curWidth = QuadTreeTerrain.getWidth(level)
        
        for y in 0..<curWidth
        {
            for x in 0..<curWidth
            {
                let noise = maxNoise * (0.5 - (Float(random()) / Float(RAND_MAX)))
                self.setDataAt(level, x: x, y: y,
                               value: noise + self.getDataAt(level, x: x, y: y))
            }
        }
    }
    func crop(level: Int, minHeight: Float, maxHeight: Float)
    {
        let curWidth = QuadTreeTerrain.getWidth(level)
        
        for y in 0..<curWidth
        {
            for x in 0..<curWidth
            {
                self.setDataAt(level, x: x, y: y,
                               value: max(minHeight, min(maxHeight, self.getDataAt(level, x: x, y: y))))
            }
        }
    }

}