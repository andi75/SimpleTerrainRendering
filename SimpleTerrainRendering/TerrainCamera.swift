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
    
    var phi : Float = 0.0 // left-right angle, phi = 0 is in x direction, phi = pi/2 is in y direction
    var chi : Float = 0.0 // up-down angle, chi = pi/2 is in z direction
    
    var distance : Float = 1.0
    
    var lookAt : GLKVector3
    {
        get {
            return GLKVector3Add(self.eye, self.viewDir)
        }
    }
    
    var viewDir : GLKVector3
    {
        get {
            return GLKVector3Make(
                cos(phi) * cos(chi),
                sin(phi) * cos(chi),
                sin(chi)
            )
        }
    }
    
    var right : GLKVector3 {
        get {
            return GLKVector3Make(
                cos(phi - Float(M_PI_2)) * cos(chi),
                sin(phi - Float(M_PI_2)) * cos(chi),
                0
            )
        }
    }
    
    var up : GLKVector3
    {
        get {
            let v = GLKVector3CrossProduct(self.right, self.viewDir
            )
//            print("up: \(v.x), \(v.y), \(v.z)")
            return v
        }
    }
    
    var terrain : TerrainData
    
    init(terrain : TerrainData)
    {
        self.terrain = terrain
        self.eye = GLKVector3Make(Float(terrain.rect.width / 2), Float(terrain.rect.height / 2), terrain.maxHeight)
        self.phi = -3 * Float(M_PI) / 2
        self.chi = 0 // -Float(M_PI) / 4
    }
    
    func forwardBackward(d : Float)
    {
        let viewDirScaled = GLKVector3MultiplyScalar(self.viewDir, d)
        eye = GLKVector3Add(eye, viewDirScaled)
    }
    
    func forwardBackwardPlanar(d : Float)
    {
        let viewHorizontal = GLKVector3Make(self.viewDir.x, self.viewDir.y, 0)
        let viewHorizontalNormalized = GLKVector3Normalize(viewHorizontal)
        let viewHorizontalScaled = GLKVector3MultiplyScalar(viewHorizontalNormalized, d)
        eye = GLKVector3Add(eye, viewHorizontalScaled)
    }
    
    
    func leftRight(d : Float)
    {
        let rightScaled = GLKVector3MultiplyScalar(self.right, d)
        eye = GLKVector3Add(eye, rightScaled)
    }
    
    func lowerHigher(d : Float)
    {
        let zScaled = GLKVector3Make(0, 0, d)
        eye = GLKVector3Add(eye, zScaled)
    }
    
    func lookAtMatrix() -> GLKMatrix4
    {
        let mat = GLKMatrix4MakeLookAt(
            eye.x, eye.y, eye.z,
            lookAt.x, lookAt.y, lookAt.y,
            up.x, up.y, up.y
            )
            // 0, 0, 0,
            // Float(terrain.width) / 2, Float(terrain.height) / 2, 0,
            // 0, 0, 1)
        
        return mat
    }
    
}