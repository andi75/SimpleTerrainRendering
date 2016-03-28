//
//  TerrainData.swift
//  SimpleTerrainRendering
//
//  Created by Andreas Umbach on 20/12/15.
//  Copyright © 2015 Andreas Umbach. All rights reserved.
//

import Foundation
import CoreGraphics
import GLKit

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
    
    func intersectWithRay(origin : GLKVector3, direction: GLKVector3) -> (isHit: Bool, location: GLKVector3)
    {
        // find tile
//        let xmin : Int = min( max(0, Int( floor(origin.x) )), self.width - 2)
//        let ymin : Int = min( max(0, Int( floor(origin.x) )), self.height - 2)

        for ymin in 0 ..< self.height - 1
        {
            for xmin in 0 ..< self.width - 1
            {
                
                let v1 = ymin * self.width + xmin
                let v2 = ymin * self.width + xmin + 1
                let v3 = (ymin + 1) * self.width + xmin
                let v4 = (ymin + 1) * self.width + xmin + 1
                
                let p1 = GLKVector3Make( Float(xmin), Float(ymin), data[v1] )
                let p2 = GLKVector3Make( Float(xmin + 1), Float(ymin), data[v2] )
                let p3 = GLKVector3Make( Float(xmin), Float(ymin + 1), data[v3] )
                let p4 = GLKVector3Make( Float(xmin + 1), Float(ymin + 1), data[v4] )
                
                var hitInfo = intersectTriangleWithRay(p1, v2: p2, v3: p3, origin: origin, direction: direction)
                if(!hitInfo.isHit)
                {
                    hitInfo = intersectTriangleWithRay(p4, v2: p2, v3: p3, origin: origin, direction: direction)
                    
                }
                if(hitInfo.isHit)
                {
                    let dirScaled = GLKVector3MultiplyScalar(direction, hitInfo.t)
                    let location = GLKVector3Add(origin, dirScaled)
                    return (true, location)
                }
                
            }
        }
        
        
        return (false, GLKVector3Make(0, 0, 0))
    }
}

