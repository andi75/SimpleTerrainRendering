//
//  SimpleTerrainView.swift
//  SimpleTerrainRendering
//
//  Created by Andreas Umbach on 20/12/15.
//  Copyright © 2015 Andreas Umbach. All rights reserved.
//

import Swift
import UIKit
import GLKit

class SimpleTerrainView : GLKView
{
    var data : TerrainData? = nil
    
    var hmin : Float = 0
    var hmax : Float = 1
    
    var distance : Float = 0.25
    
    var isWireframe = false
    var triangulationType = 0
    
    var cam : TerrainCamera? = nil
    
    override func drawRect(rect: CGRect) {
        print("drawRect called")
        
        glClearColor(0.0, 0.0, 0.5, 0.0)
        glClear( GLbitfield(GL_COLOR_BUFFER_BIT) )
        // glViewport(0, 0, GLsizei(self.frame.width), GLsizei(self.frame.height))
        
        if(self.data != nil && self.cam != nil)
        {
            renderTerrain(data!)
        }
        else
        {
            print("missing camera or terrain")
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
        
        // let proj = GLKMatrix4MakeOrtho(-d, d, -d, d, 0, 4 * d)
        let proj = GLKMatrix4MakePerspective(Float(M_PI) / 3, 1.0, 1.0, 2 * d)
        glLoadMatrixf(glMatrix(proj))
        
        glMatrixMode(GLenum(GL_MODELVIEW))
        
        print("eye position: (\(d/2), \(d/2), \(d))");
        
        // TODO: use terrain camera once it's debugged
        let camMatrix = GLKMatrix4MakeLookAt(
            self.cam!.eye.x, self.cam!.eye.y, self.cam!.eye.z,
            self.cam!.lookAt.x, self.cam!.lookAt.y, self.cam!.lookAt.z,
            self.cam!.up.x, self.cam!.up.y, self.cam!.up.z
            )
        glLoadIdentity()
        
        let lightpos : [Float] = [ 0, 0, 1, 0 ]
        glLightfv( GLenum(GL_LIGHT0), GLenum(GL_POSITION), lightpos)

        glLoadMatrixf(glMatrix(camMatrix))
 
        // simpleTriangle()
        terrainGeometry(terrain)
        // drawCamera(self.cam!)
    }
    
    func terrainGeometry(terrain: TerrainData)
    {
        
        let vertexCount = terrain.width * terrain.height
        let primitiveCount = self.isWireframe ?
            (terrain.width - 1) * (terrain.height - 1) * 5 :
            (terrain.width - 1) * (terrain.height - 1) * 2
        
        let indicesPerPrimitive = self.isWireframe ? 2 : 3
        
        var vertices : [Float] = [Float](count: vertexCount * 3, repeatedValue: 0.0)
        var normals : [Float] = [Float](count: vertexCount * 3, repeatedValue: 0.0)
        var normalColors : [Float] = [Float](count: vertexCount * 8, repeatedValue: 0.0)
        var colors : [Float] = [Float](count: vertexCount * 4, repeatedValue: 0.0)
        
        var indices : [UInt32] = [UInt32](count: primitiveCount * indicesPerPrimitive, repeatedValue: 0)
        

        
        for y in 0 ..< terrain.height
        {
            for x in 0 ..< terrain.width
            {
                let vertex = (y * terrain.width + x)
                vertices[3 * vertex + 0] = Float(x)
                vertices[3 * vertex + 1] = Float(y)
                vertices[3 * vertex + 2] = terrain.data[vertex]
                
                // normals
                let prefx = max(0, x - 1)
                let postx = min(x + 1, terrain.width - 1)
                let prefy = max(0, y - 1)
                let posty = min(y + 1, terrain.height - 1)
                
                let vprex = (y * terrain.width + prefx)
                let vpostx = (y * terrain.width + postx)
                let vprey = (prefy * terrain.width + x)
                let vposty = (posty * terrain.width + x)
                let vdx = GLKVector3(v: (2, 0, terrain.data[vpostx] - terrain.data[vprex]) )
                let vdy = GLKVector3(v: (0, 2, terrain.data[vposty] - terrain.data[vprey]) )
                let vTemp = GLKVector3CrossProduct(vdx, vdy)
                let vNormal = GLKVector3Normalize(vTemp)
                
                normals[3 * vertex + 0] = vNormal.x
                normals[3 * vertex + 1] = vNormal.y
                normals[3 * vertex + 2] = vNormal.z
                
                // let base : Float = 0.2
                // let terrainValue : Float = (terrain.data[vertex] - hmin) / (hmax - hmin)
                colors[4 * vertex + 0] = Float(x) / Float(terrain.width) // base + (1 - base) * terrainValue
                colors[4 * vertex + 1] = Float(y) / Float(terrain.height) // base + (1 - base) * terrainValue
                colors[4 * vertex + 2] = 1 // base + (1 - base) * terrainValue
                
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
        
        for y in 0 ..< (terrain.height - 1)
        {
            for x in 0 ..< (terrain.width - 1)
            {
                let v1 = UInt32( (y + 0) * terrain.width + (x + 0) )
                let v2 = UInt32( (y + 0) * terrain.width + (x + 1) )
                let v3 = UInt32( (y + 1) * terrain.width + (x + 0) )
                let v4 = UInt32( (y + 1) * terrain.width + (x + 1) )
                
                let d14 = abs(vertices[3 * Int(v1) + 2] - vertices[3 * Int(v4) + 2])
                let d23 = abs(vertices[3 * Int(v2) + 2] - vertices[3 * Int(v3) + 2])
                
                let wireframe2 =
                    (d14 < d23) ?

                    // ((x + y) % 2 == 0) ?
                    [ v1, v2, v1, v3, v2, v4, v3, v4, v1, v4 ]  :
                    [ v1, v2, v1, v3, v2, v4, v3, v4, v2, v3 ];
                
                let wireframe1 = ((x + y) % 2 == 0) ?
                    [ v1, v2, v1, v3, v2, v4, v3, v4, v1, v4 ]  :
                    [ v1, v2, v1, v3, v2, v4, v3, v4, v2, v3 ];
                
                let wireframe0 = [ v1, v2, v1, v3, v2, v4, v3, v4, v1, v4 ];
                
                let solid2 = (d14 < d23) ?
                    [ v1, v2, v3, v2, v4, v3 ] :
                    [ v1, v2, v4, v1, v4, v3 ];
                
                let solid1 = ((x + y) % 2 == 0) ?
                    [ v1, v2, v3, v2, v4, v3 ] :
                    [ v1, v2, v4, v1, v4, v3 ];
                
                let solid0 = [ v1, v2, v3, v2, v4, v3 ]
                
                var wireframe : [UInt32]
                var solid : [UInt32]
                
                switch(self.triangulationType)
                {
                case 0:
                    wireframe = wireframe0
                    solid = solid0
                case 1:
                    wireframe = wireframe1
                    solid = solid1
                case 2:
                    wireframe = wireframe2
                    solid = solid2
                default:
                    wireframe = wireframe0
                    solid = solid0
                    print("not supposed to happen")
                }
                
                if(self.isWireframe)
                {
                    
                    for i in 0 ..< 5
                    {
                        for j in 0 ..< 2
                        {
                            indices[2 * triangle + j] = wireframe[2 * i + j]
                        }
                        triangle += 1
                    }
                }
                else
                {
                    for i in 0 ..< 6
                    {
                        indices[3 * triangle + i] = solid[i]
                    }
                    triangle += 2
                }
            }
        }
//        print("indices: \(indices)")
//        print("vertices: \(vertices)")
//        print("colors: \(colors)")
        
        let normalVertexcount = 2 * vertexCount
        var normalVertices : [Float] = [Float](count: normalVertexcount * 3, repeatedValue: 0.0)
        for i in 0 ..< vertexCount
        {
            normalVertices[6 * i + 0] = vertices[3 * i + 0];
            normalVertices[6 * i + 1] = vertices[3 * i + 1];
            normalVertices[6 * i + 2] = vertices[3 * i + 2];
            normalVertices[6 * i + 3] = vertices[3 * i + 0] + normals[3 * i + 0];
            normalVertices[6 * i + 4] = vertices[3 * i + 1] + normals[3 * i + 1];
            normalVertices[6 * i + 5] = vertices[3 * i + 2] + normals[3 * i + 2];
            
            normalColors[8 * i + 0] = 1.0;
            normalColors[8 * i + 1] = 0.0;
            normalColors[8 * i + 2] = 0.0;
            normalColors[8 * i + 3] = 1.0;
            
            normalColors[8 * i + 4] = 1.0;
            normalColors[8 * i + 5] = 1.0;
            normalColors[8 * i + 6] = 0.0;
            normalColors[8 * i + 7] = 1.0;
        }
        
        
        glVertexPointer(3, GLenum(GL_FLOAT), 0, vertices)
        glColorPointer(4, GLenum(GL_FLOAT), 0, colors)
        glNormalPointer(GLenum(GL_FLOAT), 0, normals)
        glEnableClientState(GLenum(GL_VERTEX_ARRAY))
        glEnableClientState(GLenum(GL_COLOR_ARRAY))
        glEnableClientState(GLenum(GL_NORMAL_ARRAY))
        
        let light0diffuse : [Float] = [ 1, 1, 1, 1 ]
        let light0ambient : [Float] = [ 0, 0, 0, 1 ]
        let light0specular : [Float] = [ 0, 0, 0, 1 ]
        
        glEnable( GLenum(GL_LIGHT0) )
        glEnable( GLenum(GL_LIGHTING) )
        glLightfv( GLenum(GL_LIGHT0), GLenum(GL_DIFFUSE), light0diffuse)
        glLightfv( GLenum(GL_LIGHT0), GLenum(GL_AMBIENT), light0ambient)
        glLightfv( GLenum(GL_LIGHT0), GLenum(GL_SPECULAR), light0specular)
        
        glEnable( GLenum(GL_RESCALE_NORMAL ) )

        glCullFace( GLenum(GL_BACK) )
        glEnable( GLenum(GL_CULL_FACE) )
        
        // default behaviour in OpenGL ES
        // glColorMaterial( GLenum(GL_FRONT), GLenum(GL_AMBIENT_AND_DIFFUSE) )
        glEnable( GLenum(GL_COLOR_MATERIAL) )
        
        
        if(self.isWireframe)
        {
            glDrawElements(GLenum(GL_LINES), GLsizei(2 * triangle), GLenum(GL_UNSIGNED_INT), indices)
        }
        else
        {
            glDrawElements(GLenum(GL_TRIANGLES), GLsizei(3 * triangle), GLenum(GL_UNSIGNED_INT), indices)
        }
        glDisableClientState(GLenum(GL_NORMAL_ARRAY))
        glDisableClientState(GLenum(GL_COLOR_ARRAY))
        glDisableClientState(GLenum(GL_VERTEX_ARRAY))
        
        glDisable( GLenum(GL_LIGHT0) )
        glDisable( GLenum(GL_LIGHTING) )
        
        // draw normals
        // glColor4f(1.0, 0.0, 0.0, 1.0)
        
        glVertexPointer(3, GLenum(GL_FLOAT), 0, normalVertices)
        glColorPointer(4, GLenum(GL_FLOAT), 0, normalColors)
        glEnableClientState(GLenum(GL_VERTEX_ARRAY))
        glEnableClientState(GLenum(GL_COLOR_ARRAY))
        // glDrawArrays(GLenum(GL_LINES), 0, GLsizei(normalVertexcount))
        glDisableClientState(GLenum(GL_COLOR_ARRAY))
        glDisableClientState(GLenum(GL_VERTEX_ARRAY))

    }
    
    func drawCamera(cam : TerrainCamera)
    {
        let upDir = GLKVector3MultiplyScalar(cam.up, 10)
        let upEndPoint = GLKVector3Add(cam.eye, upDir)
        
        let viewDir = GLKVector3MultiplyScalar(cam.viewDir, 10)
        let viewEndPoint = GLKVector3Add(cam.eye, viewDir)
        
        let rightDir = GLKVector3MultiplyScalar(cam.right, 10)
        let rightEndPoint = GLKVector3Add(cam.eye, rightDir)
        
        let vertices : [Float] = [
            cam.eye.x, cam.eye.y, cam.eye.z,
            viewEndPoint.x, viewEndPoint.y, viewEndPoint.z,
            cam.eye.x, cam.eye.y, cam.eye.z,
            upEndPoint.x, upEndPoint.y, upEndPoint.z,
            cam.eye.x, cam.eye.y, cam.eye.z,
            rightEndPoint.x, rightEndPoint.y, rightEndPoint.z
        ]
        
        let colors : [Float] = [
            1, 1, 1, 1,
            1, 0, 0, 1,
            1, 1, 1, 1,
            0, 0, 1, 1,
            1, 1, 1, 1,
            0, 1.0, 0, 1
        ]
        drawAsLines(vertices, colors: colors)
    }
    
    func drawAsLines(vertices : [Float], colors : [Float])
    {
        glVertexPointer(3, GLenum(GL_FLOAT), 0, vertices)
        glColorPointer(4, GLenum(GL_FLOAT), 0, colors)
        glEnableClientState(GLenum(GL_VERTEX_ARRAY))
        glEnableClientState(GLenum(GL_COLOR_ARRAY))
        glDrawArrays(GLenum(GL_LINES), 0, GLsizei(vertices.count / 3))
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


