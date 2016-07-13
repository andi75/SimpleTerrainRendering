//
//  Geometry.swift
//  SimpleTerrainRendering
//
//  Created by Andreas Umbach on 28.03.2016.
//  Copyright © 2016 Andreas Umbach. All rights reserved.
//

// Möller–Trumbore ray-triangle intersection algorithm

import GLKit

let epsilon : Float = 0.000001

func GLKV3toString(v : GLKVector3) -> String
{
    return "(\(v.x), \(v.y), \(v.z))"
}

func intersectTriangleWithRay(v1 : GLKVector3, v2 : GLKVector3, v3 : GLKVector3, origin: GLKVector3, direction: GLKVector3) -> (isHit: Bool, t: Float)
{
//    print("Triangle: \(GLKV3toString(v1)), \(GLKV3toString(v2)), \(GLKV3toString(v3))")
    
    let e1 = GLKVector3Subtract(v2, v1)
    let e2 = GLKVector3Subtract(v3, v1)
    let p = GLKVector3CrossProduct(direction, e2)
    let det = GLKVector3DotProduct(e1, p)
    let inv_det = 1.0 / det
    
    if(det > -epsilon && det < epsilon)
    {
        return (false, 0)
    }
    
    let r = GLKVector3Subtract(origin, v1)
    let u = GLKVector3DotProduct(r, p) * inv_det
    
    if(u < 0 || u > 1.0)
    {
        return (false, 0)
    }
    let q = GLKVector3CrossProduct(r, e1)
    
    let v = GLKVector3DotProduct(direction, q) * inv_det
    
    if(v < 0 || u + v > 1)
    {
        return (false, 0)
    }
    
    let t = GLKVector3DotProduct(e2, q) * inv_det

    return (true, t)
//    if(t > epsilon)
//    {
//        return (true, t)
//    }
//    
//    return (false, 0)
}
