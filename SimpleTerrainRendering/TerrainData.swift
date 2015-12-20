//
//  TerrainData.swift
//  SimpleTerrainRendering
//
//  Created by Andreas Umbach on 20/12/15.
//  Copyright © 2015 Andreas Umbach. All rights reserved.
//

import Foundation

class TerrainData
{
    var data : [Float]
    var width : Int, height : Int
    
    init(width: Int, height: Int)
    {
        self.width = width
        self.height = height
        self.data = [Float](count: width * height, repeatedValue: 0.0)
    }
    
    func randomize(min min: Float, max: Float)
    {
        for var i = 0; i < self.data.count; i++ {
            self.data[i] = min + (max - min) * (Float(random()) / Float(RAND_MAX))
            print(data[i])
        }
    }
}

