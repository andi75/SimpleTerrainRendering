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
    var data: [Float] // height information
    var maxLevel : Int
    
    /**
     Compute the index where the current level's QuadTree data is stored
     
     - returns: index of the first element for the current level's data
     - paramter level: the current quadtree level
     */
    class func getOffset(_ level : Int) -> Int
    {
        var offset = 0
        for i in 0..<level
        {
            let width = QuadTreeTerrain.getWidth(i)
            offset += width * width
        }
        return offset
    }
    
    /**
     Compute the width (amount of data points per row/column) of the current
     QuadTree level
     
     - returns: amount of data points per row/column
     - parameter level: the current quadtree level
     */
    class func getWidth(_ level : Int) -> Int
    {
        return (1 << level) + 1
    }
    
    class func getNextLevelXYOrigin(_ currentLevel: Int, currentX: Int, currentY: Int) -> (nextX: Int, nextY: Int)
    {
        let width = QuadTreeTerrain.getWidth(currentLevel)
        return (nextX: currentX * width, nextY: currentY * width)
        // TODO: untested
    }
    
    /**
     Gets the data at the x/y coordinates of the specified level
     - returns: data at the x/y coordinates of the specified level
     */
    func getDataAt(_ level: Int, x: Int, y: Int) -> Float
    {
        return data[QuadTreeTerrain.getOffset(level) + y * QuadTreeTerrain.getWidth(level) + x]
    }
    
    /**
     Sets the data at the x/y coordinates of the specified level
     */
    func setDataAt(_ level: Int, x: Int, y: Int, value: Float)
    {
        data[QuadTreeTerrain.getOffset(level) + y * QuadTreeTerrain.getWidth(level) + x] = value
    }
    
    init(maxLevel : Int)
    {
        self.maxLevel = maxLevel
        let size = QuadTreeTerrain.getOffset(maxLevel + 1)
        self.data = [Float](repeating: 0.0, count: size)
    }
    
    /**
    Copies data from a higher (coarser) level to a lower level. Data points that are
    at the same location are unchanged, new data points between old points are
    linearly interpolated
     
    - paramter upperLevel: The level that contains the data to be copied and interpolated
    */
    func copyFromUpperLevel(_ upperLevel : Int)
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
    
    /**
     Adds random noise ranging from -maxNoise/2 to maxNoise/2
     the specified level
     */
    func addRandomNoiseToLevel(_ level: Int, maxNoise: Float)
    {
        let curWidth = QuadTreeTerrain.getWidth(level)
        
        for y in 0..<curWidth
        {
            for x in 0..<curWidth
            {
                // TODO: it might make sense to change this to maxNoise * rand(-1 from 1)
                let noise = maxNoise * (0.5 - Float(arc4random_uniform(10000)) / 10000.0)
                self.setDataAt(level, x: x, y: y,
                               value: noise + self.getDataAt(level, x: x, y: y))
            }
        }
    }
    /**
     Crops the data in the specified level to the
     range [minHeight, maxHeight]
     */
    func crop(_ level: Int, minHeight: Float, maxHeight: Float)
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
    
    /**
     */
    
    func setEdge(_ level: Int, value : Float)
    {
        let curWidth = QuadTreeTerrain.getWidth(level)
        for i in 0..<curWidth
        {
            self.setDataAt(level, x: 0, y: i, value: value)
            self.setDataAt(level, x: i, y: 0, value: value)
            self.setDataAt(level, x: curWidth - 1, y: i, value: value)
            self.setDataAt(level, x: i, y: curWidth - 1, value: value)
        }
        
    }

}
