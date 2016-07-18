//
//  ShadowVolume.swift
//  SimpleTerrainRendering
//
//  Created by Andreas Umbach on 17.07.2016.
//  Copyright © 2016 Andreas Umbach. All rights reserved.
//

import Foundation
import GLKit

class ShadowVolume
{
    var vertices : [Float]
    var indices : [UInt32]
    var adjacency : [Int]
    var faceNormals : [Float]
    
    var silouette : [Int]?
    var frontFaces : [UInt32]?
    var backFaces : [UInt32]?
    
    init(vertices : [Float], indices : [UInt32], adjacency : [Int], faceNormals : [Float])
    {
        self.vertices = vertices
        self.indices = indices
        self.adjacency = adjacency
        self.faceNormals = faceNormals
        
        assert(faceNormals.count == indices.count)
        assert(adjacency.count == indices.count)
    }
    
    func computeSilouette(lightDirection : GLKVector3)
    {
        // TODO: untested and unused
        assert(
            lightDirection.x != 0 ||
            lightDirection.y != 0 ||
            lightDirection.z != 0
        )
        
        let triangles = indices.count / 3
        var dotSigns = [Float](count: indices.count / 3, repeatedValue: 0)
        
        // for each triangle, compute the signs of the dotproduct
        // between the face normal and the light direction
        var frontFaceCount : Int = 0
        var backFaceCount : Int = 0
        
        for i in 0..<triangles
        {
            let v = GLKVector3Make(
                faceNormals[3 * i + 0],
                faceNormals[3 * i + 1],
                faceNormals[3 * i + 2]
            )
            dotSigns[i] = sign(GLKVector3DotProduct(v, lightDirection))
            if(dotSigns[i] < 0) { frontFaceCount += 1 }
            if(dotSigns[i] >= 0) { backFaceCount += 1 }
        }
        
        // for each triangle edge, compare the signs between the triangle and its neighbors
        // if the signs differ, the edge is a silouette edge
        
        // count silouette edges first, so the appropriate
        // index buffers can be built
        
        var edgeCount : Int = 0
        for i in 0..<triangles
        {
            for j in 0..<3
            {
                let neighbor = adjacency[3 * i + j]
                // check for i < neighbor so we count each edge only once, not twice
                if( neighbor != -1 && i < neighbor && dotSigns[i] != dotSigns[ neighbor ])
                {
                    // silouette edge found
                    edgeCount += 1
                }
            }
        }
        
        self.silouette = [Int](count : edgeCount * 2, repeatedValue: 0)
        var currentEdge = 0
        for i in 0..<triangles
        {
            for j in 0..<3
            {
                let neighbor = adjacency[3 * i + j]
                // check for i < neighbor so we count each edge only once, not twice
                if( neighbor != -1 && i < neighbor && dotSigns[i] != dotSigns[ neighbor ])
                {
                    // silouette edge found
                    
                    // if triangle i is backfacing, we need to switch the edge direction
                    // in the silouette order to get the correct front facing and back
                    // facing shadow volumes
                    if( dotSigns[i] == -1)
                    {
                        silouette![ currentEdge * 2 + 0] = Int(indices[ 3 * i + j ])
                        silouette![ currentEdge * 2 + 1] = Int(indices[ 3 * i + ( (j + 1) % 3 ) ])
                    }
                    else
                    {
                        silouette![ currentEdge * 2 + 0] = Int(indices[ 3 * i + ( (j + 1) % 3 ) ])
                        silouette![ currentEdge * 2 + 1] = Int(indices[ 3 * i + j ])
                    }
                    currentEdge += 1
                }
            }
        }
        
        var currentFrontFace = 0
        var currentBackFace = 0
        self.frontFaces = [UInt32](count: frontFaceCount * 3, repeatedValue: 0)
        self.backFaces = [UInt32](count: backFaceCount * 3, repeatedValue : 0)

        for i in 0..<triangles
        {
            if(dotSigns[i] < 0)
            {
                // front face
                for j in 0..<3
                {
                    self.frontFaces![3 * currentFrontFace + j] = self.indices[3 * i + j]
                }
                currentFrontFace += 1
            }
            else
            {
                for j in 0..<3
                {
                    self.backFaces![3 * currentBackFace + j] = self.indices[3 * i + j]
                }
                currentBackFace += 1
            }
        }
    }
}