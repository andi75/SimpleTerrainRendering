//
//  SimpleTerrainView.swift
//  SimpleTerrainRendering
//
//  Created by Andreas Umbach on 20/12/15.
//  Copyright © 2015 Andreas Umbach. All rights reserved.
//

import UIKit
import GLKit

class SimpleTerrainView : GLKView
{
    var data : TerrainData? = nil
    
    var min : Float = 0
    var max : Float = 1
    
    var distance : Float = 1.0
    
    override func drawRect(rect: CGRect) {
        print("drawRect called")
        
        glClearColor(0.0, 0.0, 0.5, 0.0)
        glClear( GLbitfield(GL_COLOR_BUFFER_BIT) )
        // glViewport(0, 0, GLsizei(self.frame.width), GLsizei(self.frame.height))
        
        if(data != nil)
        {
            renderTerrain(data!)
        }
    }
    
    func glMatrix(mat : GLKMatrix4) -> [Float]
    {
        return [
            mat.m00, mat.m01, mat.m02, mat.m03,
            mat.m10, mat.m11, mat.m12, mat.m13,
            mat.m20, mat.m21, mat.m22, mat.m23,
            mat.m30, mat.m31, mat.m32, mat.m33
        ]
    }
    
    func renderTerrain(terrain : TerrainData)
    {
        glMatrixMode(GLenum(GL_PROJECTION))
        // let proj = GLKMatrix4MakeOrtho(0, Float(terrain.width), 0, Float(terrain.height), 0, 100)
        let d = distance * Float(terrain.width)
        
        let proj = GLKMatrix4MakeOrtho(-d, d, -d, d, 0, 4 * d)
        glLoadMatrixf(glMatrix(proj))
        
        glMatrixMode(GLenum(GL_MODELVIEW))
        let cam = GLKMatrix4MakeLookAt(d/2, d/2, d, 0, 0, 0, 0, 0, 1)
        glLoadIdentity()
        glLoadMatrixf(glMatrix(cam))
        // simpleTriangle()
        terrainGeometry(terrain)
    }
    
    func terrainGeometry(terrain: TerrainData)
    {
        let wireframe = true

        let vertexCount = terrain.width * terrain.height
        let primitiveCount = wireframe ?
            (terrain.width - 1) * (terrain.height - 1) * 5 :
            (terrain.width - 1) * (terrain.height - 1) * 2
        
        let indicesPerPrimitive = wireframe ? 2 : 3
        
        var vertices : [Float] = [Float](count: vertexCount * 3, repeatedValue: 0.0)
        var colors : [Float] = [Float](count: vertexCount * 4, repeatedValue: 0.0)
        
        var indices : [UInt32] = [UInt32](count: primitiveCount * indicesPerPrimitive, repeatedValue: 0)
        

        
        for var y = 0; y < terrain.height; y++
        {
            for var x = 0; x < terrain.width; x++
            {
                let vertex = (y * terrain.width + x)
                vertices[3 * vertex + 0] = Float(x)
                vertices[3 * vertex + 1] = Float(y)
                vertices[3 * vertex + 2] = terrain.data[vertex]
    
                colors[4 * vertex + 0] = (terrain.data[vertex] - min) / (max - min)
                colors[4 * vertex + 1] = (terrain.data[vertex] - min) / (max - min)
                colors[4 * vertex + 2] = (terrain.data[vertex] - min) / (max - min)
                colors[4 * vertex + 3] = 1
            }
        }
        
        colors[4 * 0 + 0] = 1;
        colors[4 * 0 + 1] = 1;
        colors[4 * 0 + 2] = 0;
        colors[4 * 0 + 3] = 1;

        colors[4 * (terrain.width - 1) + 0] = 1;
        colors[4 * (terrain.width - 1) + 1] = 0;
        colors[4 * (terrain.width - 1) + 2] = 0;
        colors[4 * (terrain.width - 1) + 3] = 1;

        colors[4 * (terrain.width * (terrain.height - 1)) + 0] = 0;
        colors[4 * (terrain.width * (terrain.height - 1)) + 1] = 1;
        colors[4 * (terrain.width * (terrain.height - 1)) + 2] = 0;
        colors[4 * (terrain.width * (terrain.height - 1)) + 3] = 1;
        
        var triangle = 0;
        
        for(var y = 0; y < terrain.height - 1; y++)
        {
            for(var x = 0; x < terrain.width - 1; x++)
            {
                let v1 = UInt32( (y + 0) * terrain.width + (x + 0) )
                let v2 = UInt32( (y + 0) * terrain.width + (x + 1) )
                let v3 = UInt32( (y + 1) * terrain.width + (x + 0) )
                let v4 = UInt32( (y + 1) * terrain.width + (x + 1) )
                
                let d14 = abs(vertices[3 * Int(v1) + 2] - vertices[3 * Int(v4) + 2])
                let d23 = abs(vertices[3 * Int(v2) + 2] - vertices[3 * Int(v3) + 2])
                
                let wireframe1 =
                    (d14 < d23) ?

                    // ((x + y) % 2 == 0) ?
                    [ v1, v2, v1, v3, v2, v4, v3, v4, v1, v4 ]  :
                    [ v1, v2, v1, v3, v2, v4, v3, v4, v2, v3 ];
                
                if(wireframe)
                {
                    
                    for(var i = 0; i < 5; i++)
                    {
                        for(var j = 0; j < 2; j++)
                        {
                            indices[2 * triangle + j] = wireframe1[2 * i + j];
                        }
                        triangle++;
                    }
                }
                else
                {
                    if (d14 < d23)
                        // ( (x + y) % 2 == 0)
                    {
                        indices[3 * triangle + 0] = v1;
                        indices[3 * triangle + 1] = v2;
                        indices[3 * triangle + 2] = v3;
                        triangle++;
                        
                        indices[3 * triangle + 0] = v2;
                        indices[3 * triangle + 1] = v4;
                        indices[3 * triangle + 2] = v3;
                        triangle++;
                    }
                    else
                    {
                        indices[3 * triangle + 0] = v1;
                        indices[3 * triangle + 1] = v4;
                        indices[3 * triangle + 2] = v2;
                        triangle++;
                        
                        indices[3 * triangle + 0] = v1;
                        indices[3 * triangle + 1] = v3;
                        indices[3 * triangle + 2] = v4;
                        triangle++;
                    }
                }
            }
        }
//        print("indices: \(indices)")
//        print("vertices: \(vertices)")
//        print("colors: \(colors)")
        
        glVertexPointer(3, GLenum(GL_FLOAT), 0, vertices)
        glColorPointer(4, GLenum(GL_FLOAT), 0, colors)
        glEnableClientState(GLenum(GL_VERTEX_ARRAY))
        glEnableClientState(GLenum(GL_COLOR_ARRAY))
        
        if(wireframe)
        {
            glDrawElements(GLenum(GL_LINES), GLsizei(2 * triangle), GLenum(GL_UNSIGNED_INT), indices)
        }
        else
        {
            glDrawElements(GLenum(GL_TRIANGLES), GLsizei(3 * triangle), GLenum(GL_UNSIGNED_INT), indices)
        }
        glDisableClientState(GLenum(GL_COLOR_ARRAY))
        glDisableClientState(GLenum(GL_VERTEX_ARRAY))
        
    }
    func simpleTriangle()
    {
        let z : Float = -0.5
        let vertices : [Float] = [ 0, 0, z, 1, 0, z, 0, 1, z]
        let colors : [Float] = [ 1, 0, 0, 1, 0, 1, 0, 1, 0, 0, 1, 1 ]
        let indices : [UInt32] = [ 0, 1, 2 ]
        
        glVertexPointer(3, GLenum(GL_FLOAT), 0, vertices)
        glColorPointer(4, GLenum(GL_FLOAT), 0, colors)
        glEnableClientState(GLenum(GL_VERTEX_ARRAY))
        glEnableClientState(GLenum(GL_COLOR_ARRAY))
        // glDrawArrays(GLenum(GL_TRIANGLES), 0, GLsizei(3))
        glDrawElements(GLenum(GL_TRIANGLES), 3, GLenum(GL_UNSIGNED_INT), indices)
        glDisableClientState(GLenum(GL_COLOR_ARRAY))
        glDisableClientState(GLenum(GL_VERTEX_ARRAY))
    }
}


