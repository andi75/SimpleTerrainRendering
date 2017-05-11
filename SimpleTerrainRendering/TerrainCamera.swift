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
    var chi : Float = 0.0
    {
        didSet(oldValue)// clamp to -5 Pi/12, 5 Pi/12
        {
            chi = max( -5 * .pi / 12, min( chi, 5 * .pi / 12) )
        }
    }
    // up-down angle, chi = pi/2 is in z direction
    
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
                cos(phi - .pi / 2) * cos(chi),
                sin(phi - .pi / 2) * cos(chi),
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
        self.phi = -3 * .pi / 2
        self.chi = 0 // -.pi / 4
    }
    
    func forwardBackward(_ d : Float)
    {
        let viewDirScaled = GLKVector3MultiplyScalar(self.viewDir, d)
        self.eye = GLKVector3Add(self.eye, viewDirScaled)
    }
    
    func forwardBackwardPlanar(_ d : Float)
    {
        let viewHorizontal = GLKVector3Make(self.viewDir.x, self.viewDir.y, 0)
        let viewHorizontalNormalized = GLKVector3Normalize(viewHorizontal)
        let viewHorizontalScaled = GLKVector3MultiplyScalar(viewHorizontalNormalized, d)
        self.eye = GLKVector3Add(self.eye, viewHorizontalScaled)
    }
    
    
    func leftRight(_ d : Float)
    {
        let rightScaled = GLKVector3MultiplyScalar(self.right, d)
        self.eye = GLKVector3Add(self.eye, rightScaled)
    }
    
    func lowerHigher(_ d : Float)
    {
        let zScaled = GLKVector3Make(0, 0, d)
        self.eye = GLKVector3Add(self.eye, zScaled)
    }
    
    func lowerHigherWithFocus(_ d : Float, focus : GLKVector3)
    {
        let zScaled = GLKVector3Make(0, 0, d)
        self.eye = GLKVector3Add(self.eye, zScaled)
        
        let distHorizontal = sqrt( (focus.x - eye.x) * (focus.x - eye.x) + (focus.y - eye.y) * (focus.y - eye.y) )
        
//        print("chi before: \(self.chi)")
        self.chi = atan( -(self.eye.z - focus.z ) / distHorizontal )
//        print("chi after: \(self.chi)")

    }
    
    func zoomInOrOut(_ scale : Float)
    {
        var vScale : Float
        if(scale < 1)
        {
            vScale = -1 / scale
        }
        else
        {
            vScale = scale
        }
        // vScale *= 10
        
        print("scale: \(vScale)")
        
        self.eye = GLKVector3Add(self.eye, GLKVector3MultiplyScalar(self.viewDir, vScale))
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
