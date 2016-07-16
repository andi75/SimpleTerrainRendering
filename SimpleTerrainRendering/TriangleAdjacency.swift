//
//  TriangleAdjacency.swift
//  SimpleTerrainRendering
//
//  Created by Andreas Umbach on 16.07.2016.
//  Copyright © 2016 Andreas Umbach. All rights reserved.
//

import Foundation

// TODO: unused and untested

class TriangleAdjancency
{
    var adjacency : [Int]
    
    /**
     Computes for each triangle in the indices array the index of the three adjancent triangles,
     or -1 if there's no adjacent triang le
     */
    init(indices : [Int], vertexCount : Int)
    {
        let triangleCount = indices.count / 3
        adjacency = [Int](count: triangleCount * 3, repeatedValue: -1)
        
        // foreach vertex, count in how many triangle it is
        var vertexOrder = [Int](count: vertexCount, repeatedValue: 0)
        for i in 0..<triangleCount
        {
            for j in 0..<3
            {
                vertexOrder[ indices[3 * i + j] ] += 1
            }
        }
        // foreach vertex, store the list of triangles it is part of
        // first: compute the offsets where we store those lists in one big array
        var vertexTriangleListOffset = [Int](count: vertexCount, repeatedValue: 0)
        var currentOffset = 0
        for i in 0..<vertexCount
        {
            vertexTriangleListOffset[i] = currentOffset
            currentOffset += vertexOrder[i]
        }
        
        // second: store all the triangles in those lists
        // in order to keep track where to store the vertices, we need to keep
        // a list of the amount of triangles we already found for each vertex
        // so we can compute the total offset into our buffer
        var tmpTriangleOffset = [Int](count: vertexCount, repeatedValue: 0)
        var vertexTriangleList = [Int](count: triangleCount * 3, repeatedValue: -1)
        for i in 0..<triangleCount
        {
            for j in 0..<3
            {
                let vertex = indices[3 * i + j]
                let offset = vertexTriangleListOffset[vertex] + tmpTriangleOffset[vertex]
                vertexTriangleList[offset] = i
                tmpTriangleOffset[vertex] += 1
            }
        }
        
        // Now, we for each triangle, we check both vertices of each edge, and find the
        // other triangle they share, if there is one. If they share more than one
        // other triangle, the triangulation is not manifold and it we should throw
        // an error
        
        for i in 0..<triangleCount
        {
            for j in 0..<3
            {
                // v1-v2 form an edge of the triangle
                let v1 = indices[3 * i + j]
                let v2 = indices[3 * i + ( (j + 1) % 3)]

                let baseOffsetV1 = vertexTriangleListOffset[v1]
                
                // TODO: I think it's possible to skip the next loop if v2 < v1, and only
                // do this for v1 < v2, and still discover all inconsistencies.
                // However, this would require setting both adjacencies at the same time
                // in the inner l-loop
                
                // foreach triangle that contains v1, check all edges and see if one contains v2
                for k in 0..<vertexOrder[v1]
                {
                    let triangle = vertexTriangleList[ baseOffsetV1 + k]
                    for l in 0..<3
                    {
                        if( indices[3 * triangle + ((l + 1) % 3)] == v1 &&
                            indices[3 * triangle + l] == v2 )
                        {
                            // adjacency found
                            assert(
                                adjacency[3 * i + j] == -1 ||
                                adjacency[3 * i + j] == triangle
                            )
                            adjacency[3 * i + j] = triangle
                            // we could break out of the k-loop here, but then we wouldn't detect
                            // inconsistencies
                        }
                    }
                }
            }
        }
    }
}