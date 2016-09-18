//
//  CameraMotion.swift
//  SimpleTerrainRendering
//
//  Created by Andreas Umbach on 15.07.2016.
//  Copyright © 2016 Andreas Umbach. All rights reserved.
//

import Foundation

class CameraMotion
{
    var forward = false
    var backward = false
    var left = false
    var right = false
    var up = false
    var down = false
    
    var isMoving : Bool { get { return forward || backward || left || right || up || down } }
    
    func stop()
    {
        forward = false
        backward = false
        left = false
        right = false
        up = false
        down = false
    }
    
    func move(dt : Float, speed: Float, cam: TerrainCamera)
    {
//        print("before: \(GLKV3toString(cam.eye))")
        if(forward) { cam.forwardBackwardPlanar(dt * speed) }
        if(backward) { cam.forwardBackwardPlanar(-dt * speed) }
        if(left) { cam.leftRight(-dt * speed) }
        if(right) { cam.leftRight(dt * speed) }
        if(up) { cam.lowerHigher(dt * speed) }
        if(down) { cam.lowerHigher(-dt * speed) }
//        print("after: \(GLKV3toString(cam.eye))")

    }
}
