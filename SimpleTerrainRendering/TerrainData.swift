//
//  TerrainData.swift
//  SimpleTerrainRendering
//
//  Created by Andreas Umbach on 20/12/15.
//  Copyright © 2015 Andreas Umbach. All rights reserved.
//

import Foundation
import CoreGraphics

class TerrainData
{
    var data : [Float]
    
    var width : Int
        {
            return Int(rect.width)
    }
    
    var height : Int
        {
            return Int(rect.height)
    }
    
    var rect : CGRect
    
    var minHeight : Float {
        var minHeight = data[0]
        for i in 1 ..< (width * height)
        {
            if(data[i] < minHeight)
            {
                minHeight = data[i]
            }
        }
        return minHeight
    }
    
    var maxHeight : Float {
        var maxHeight = data[0]
        for i in 1 ..< (width * height)
        {
            if(data[i] > maxHeight)
            {
                maxHeight = data[i]
            }
        }
        return maxHeight
    }
    
    init(width: Int, height: Int)
    {
        self.rect = CGRectMake(0, 0, CGFloat(width), CGFloat(height))
        self.data = [Float](count: width * height, repeatedValue: 0.0)
    }
    
    func randomize(min min: Float, max: Float)
    {
        for i in 0 ..< self.data.count
        {
            self.data[i] = min + (max - min) * (Float(random()) / Float(RAND_MAX))
            // print(data[i])
        }
    }
    
    func apply3x3Kernel(kernel: [Float], normalize: Bool)
    {
        var scale : Float = 1
        let size = 3
        let offset : [Int] = [ -1, 0, 1 ]

        if(normalize)
        {
            scale = 0
            for i in 0 ..< (size * size)
            {
                scale += kernel[i]
            }
        }
        
        var tmp : [Float] = [Float](count: self.width * self.height, repeatedValue: 0.0)
        
        for y in 0 ..< self.height
        {
            for x in 0 ..< self.width
            {
                var sum : Float = 0
                for i in 0 ..< (size * size)
                {
                    let px = min(self.width - 1, max(0, x + offset[i % 3]))
                    let py = min(self.height - 1, max(0, y + offset[i / 3]))
                    sum += kernel[i] * self.data[py * self.width + px]
                }
                tmp[y * self.width + x] = sum / scale
            }
        }
        for i in 0 ..< (self.width * self.height)
        {
            self.data[i] = tmp[i]
        }
    }
    
    func smooth()
    {
        let kernel : [Float] = [ 0.25, 0.5, 0.25, 0.5, 2, 0.5, 0.25, 0.5, 0.25 ]
        self.apply3x3Kernel(kernel, normalize: true)
    }
}

