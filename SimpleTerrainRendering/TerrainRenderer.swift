//
//  TerrainRenderer.swift
//  SimpleTerrainRendering
//
//  Created by Andreas Umbach on 12/07/16.
//  Copyright © 2015 Andreas Umbach. All rights reserved.
//

// import Foundation
// import Cocoa

#if( os(iOS) )
    import GLKit
#else
    import OpenGL
    import GLKit
    import GLUT
#endif

// import GLKit
// import OpenGL

class TerrainRenderer
{
    var vertices : [Float]?
    var normals : [Float]?
    var normalColors : [Float]?
    var colors : [Float]?
    var indices : [UInt32]?
    var normalVertices : [Float]?
    
    var edgeVertices : [Float]?
    
    var vertexCount : Int = 0
    var normalVertexcount : Int = 0
    var primitiveCount : Int = 0
    
    var lightDir = GLKVector3Make(1, 1, -0.6)
    var lightPos : [Float] = [ -1, -1, 0.6, 0 ]
    
    var xyScale : Float = 1.0 {
        didSet {
            isValidGeometry = false
        }
    }
    var zScale : Float = 1.0 {
        didSet {
            isValidGeometry = false
        }
    }
    
    var data : TerrainData? = nil {
        didSet {
            isValidGeometry = false
            isValidIndices = false
        }
    }
    
    var isWireframe = false {
        didSet {
            isValidIndices = false
        }
    }
    var triangulationType = 0 {
        didSet {
            isValidIndices = false
        }
    }
    
    var showDebugNormals = false
    var showDebugShadowGeometry = false
    
    var isValidGeometry = false
    var isValidIndices = false
    
    var isCameraLight = false
    
    var cam : TerrainCamera? = nil
    
    func invalidateGeometry() { isValidGeometry = false }
    func invalidateIndices() { isValidIndices = false }
    func invalidateGeometryAndIndices() {
        isValidGeometry = false
        isValidIndices = false
    }
    
    func checkGLError( _ message : String )
    {
        let error = glGetError()
        if(error != 0)
        {
            print("\(message): \(error)")
        }
    }
    
    func renderTerrain(width : CGFloat, height : CGFloat) {
//        print("render() called")
        checkGLError("before frame")
        
        let global_ambient : [Float] = [ 0, 0, 0, 1 ]
        glLightModelfv(GLenum(GL_LIGHT_MODEL_AMBIENT), global_ambient)
        
        glClearColor(0.3, 0.3, 0.8, 0.0)
//        glClearColor(1.0, 1.0, 1.0, 0.0)
        glClear( GLbitfield(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT)  )
        
        glEnable( GLenum(GL_DEPTH_TEST) )
        glViewport(0, 0, GLsizei(width), GLsizei(height))
        
        if(self.data != nil && self.cam != nil)
        {
            renderTerrain(width, height: height, terrain: data!)
        }
        else
        {
            print("missing camera or terrain")
        }
        checkGLError("after frame")
    }
    
    func glMatrix(_ mat : GLKMatrix4) -> [Float]
    {
        return [
            mat.m00, mat.m01, mat.m02, mat.m03,
            mat.m10, mat.m11, mat.m12, mat.m13,
            mat.m20, mat.m21, mat.m22, mat.m23,
            mat.m30, mat.m31, mat.m32, mat.m33
        ]
    }
    
    func renderTerrain(_ width : CGFloat, height : CGFloat, terrain : TerrainData)
    {
        glMatrixMode(GLenum(GL_PROJECTION))
        // let proj = GLKMatrix4MakeOrtho(0, Float(terrain.width), 0, Float(terrain.height), 0, 100)
        let d = Float(terrain.width) * xyScale
        
        // let proj = GLKMatrix4MakeOrtho(-d, d, -d, d, 0, 4 * d)
        let proj = GLKMatrix4MakePerspective( .pi / 4.0, Float(width / height), 2.0,  2 * d)
        glLoadMatrixf(glMatrix(proj))
        
        glMatrixMode(GLenum(GL_MODELVIEW))
        
        let camMatrix = GLKMatrix4MakeLookAt(
            self.cam!.eye.x, self.cam!.eye.y, self.cam!.eye.z,
            self.cam!.lookAt.x, self.cam!.lookAt.y, self.cam!.lookAt.z,
            self.cam!.up.x, self.cam!.up.y, self.cam!.up.z
        )
        glLoadIdentity()
        
        if(isCameraLight)
        {
            glLightfv( GLenum(GL_LIGHT0), GLenum(GL_POSITION), self.lightPos)
        }
        glLoadMatrixf(glMatrix(camMatrix))
        if(!isCameraLight)
        {
            glLightfv( GLenum(GL_LIGHT0), GLenum(GL_POSITION), self.lightPos)
        }
        
        // TODO: call this function only when the geometry has changed
        createGeometry()

        renderTerrainGeometry()
        
//        let hitResult = terrain.intersectWithRay(self.cam!.eye, direction: self.cam!.viewDir)
//        if(hitResult.isHit)
//        {
//            //            print("hit from \(GLKV3toString(self.cam!.eye)) in direction \(GLKV3toString(self.cam!.viewDir)) at \(GLKV3toString(hitResult.location))")
//            simpleTetrahedron(0.1, location: hitResult.location)
//        }
    }

    func createGeometry()
    {
        var updateShadowGeometry = false
        
        if(!self.isValidGeometry)
        {
            self.vertices = TerrainRenderer.createVertexGeometry(self.data!, xyScale: xyScale, zScale: zScale)
            self.vertexCount = self.vertices!.count / 3
            
            self.normals = TerrainRenderer.createNormalGeometry(self.data!, xyScale: xyScale, zScale: zScale)
            self.colors = TerrainRenderer.createVertexColors(self.data!)
            
            createDebugNormalGeometry()
            
            self.isValidGeometry = true
            updateShadowGeometry = true
        }
        if(!self.isValidIndices)
        {
            if(self.isWireframe)
            {
                self.indices = TerrainRenderer.createWireframeIndices(self.data!, triangulationType: self.triangulationType)
                self.primitiveCount = self.indices!.count / 2
            }
            else
            {
                self.indices = TerrainRenderer.createTriangleIndices(self.data!, triangulationType: self.triangulationType)
                self.primitiveCount = self.indices!.count / 3
            }
            self.isValidIndices = true
        }
        
        if(updateShadowGeometry && !self.isWireframe)
        {
            let faceNormals = TerrainRenderer.createFaceNormals(self.vertices!, indices: self.indices!)
            let adjacency = TriangleAdjancency(indices: self.indices!, vertexCount: self.vertexCount).adjacency
            self.edgeVertices = TerrainRenderer.createShadowGeometry(self.vertices!, indices: self.indices!, faceNormals: faceNormals, adjacency: adjacency, lightDirection: self.lightDir)
            
            print("edgeVertexCount: \(self.edgeVertices!.count / 3)")
        }
    }
    
    class func terrainColor(_ t : Float) -> [Float]
    {
        let colorsAndLimits : [(Float, [Float])] = [
            (0.01, [ 0, 0, 1, 1 ]),
            (0.04, [ 0, 0.9, 0, 1]),
            (0.35, [ 0, 0.8, 0, 1]),
            (0.55, [ 0.4, 0.4, 0, 1 ]),
            (0.75, [ 0.3, 0.3, 0.3, 1 ]),
            (0.85, [ 1, 1, 1, 1 ])
            ]
        
        var lastLimit : Float = 0
        var lastColor : [Float]?
        
        for (limit, color) in colorsAndLimits
        {
            if(t < limit)
            {
                if(lastLimit == 0)
                {
                    return color
                }
                else
                {
                    var interPolatedColor : [Float] = [0, 0, 0, 0]
                    let tRange = (t - lastLimit) / (limit - lastLimit)
                    for i in 0..<4
                    {
                        interPolatedColor[i] = lastColor![i] * (1 - tRange) + tRange * color[i]
                    }
                    return interPolatedColor
                }
            }
            lastColor = color
            lastLimit = limit
        }
        return lastColor!
    }

    class func createVertexColors(_ terrain: TerrainData) -> [Float]
    {
        let min = terrain.minHeight
        let max = terrain.maxHeight
        
        var colors : [Float] = [Float](repeating: 1.0, count: terrain.width * terrain.height * 4)
        for y in 0 ..< terrain.height
        {
            for x in 0 ..< terrain.width
            {
                let vertex = (y * terrain.width + x)
                let t = (terrain.data[vertex] - min) / (max - min)

                let color = TerrainRenderer.terrainColor(t)

                for i in 0..<4
                {
                    colors[4 * vertex + i] = color[i]
                }
            }
        }
        return colors
    }

    class func createFaceNormals(_ vertices: [Float], indices: [UInt32]) -> [Float]
    {
        let nFaces : Int = indices.count / 3
        
        var faceNormals : [Float] = [Float](repeating: 0, count: 3 * nFaces)
        
        for i in 0..<nFaces
        {
            let a = Int( indices[3 * i + 0])
            let b = Int( indices[3 * i + 1])
            let c = Int( indices[3 * i + 2])
            
            let v1 = GLKVector3Make(
                vertices[3 * b + 0] - vertices[3 * a + 0],
                vertices[3 * b + 1] - vertices[3 * a + 1],
                vertices[3 * b + 2] - vertices[3 * a + 2]
            )
            
            let v2 = GLKVector3Make(
                vertices[3 * c + 0] - vertices[3 * a + 0],
                vertices[3 * c + 1] - vertices[3 * a + 1],
                vertices[3 * c + 2] - vertices[3 * a + 2]
            )
            let vCross = GLKVector3CrossProduct(v1, v2)
            let vNormal = GLKVector3Normalize(vCross)
            faceNormals[3 * i + 0] = vNormal.x
            faceNormals[3 * i + 1] = vNormal.y
            faceNormals[3 * i + 2] = vNormal.z
        }
        return faceNormals
    }
    
    class func createShadowGeometry(_ vertices: [Float], indices: [UInt32], faceNormals: [Float], adjacency: [Int], lightDirection: GLKVector3) -> [Float]
    {
        let shadowVolume = ShadowVolume(vertices: vertices, indices: indices, adjacency: adjacency, faceNormals: faceNormals)
        shadowVolume.computeSilouette(lightDirection)
        
        let edgeVertexCount = 2 * shadowVolume.silouette!.count
        let edgeQuads = shadowVolume.silouette!.count / 2
        var edgeVertices = [Float](repeating: 0, count: edgeVertexCount * 3)
        

        let lightDirNormalized = GLKVector3Normalize(lightDirection)
//        let v = GLKVector3Normalize(lightDirection)
//        let lightDirHack = GLKVector3Make(v.x, v.y, v.z * 1.4)
//        let lightDirNormalized = GLKVector3Normalize(lightDirHack)
        for i in 0..<edgeQuads
        {
            let v1Index = shadowVolume.silouette![2 * i + 0]
            let v2Index = shadowVolume.silouette![2 * i + 1]
            
            let v1 = GLKVector3Make(
                vertices[3 * v1Index + 0],
                vertices[3 * v1Index + 1],
                vertices[3 * v1Index + 2]
                )
            let v2 = GLKVector3Make(
                vertices[3 * v2Index + 0],
                vertices[3 * v2Index + 1],
                vertices[3 * v2Index + 2]
            )
            // TODO: check if light is parallel to the ground
            let t1 = -v1.z / lightDirNormalized.z
            let t2 = -v2.z / lightDirNormalized.z
            let v1Extrusion = GLKVector3MultiplyScalar(lightDirNormalized, t1)
            let v2Extrusion = GLKVector3MultiplyScalar(lightDirNormalized, t2)
            let v1Extracted = GLKVector3Add(v1, v1Extrusion)
            let v2Extracted = GLKVector3Add(v2, v2Extrusion)
            
            // print("\(GLKV3toString(v1)) -> \(GLKV3toString(v1Extracted))")
            // print("\(GLKV3toString(v2)) -> \(GLKV3toString(v2Extracted))")
            
            edgeVertices[4 * 3 * i + 0] = v1.x
            edgeVertices[4 * 3 * i + 1] = v1.y
            edgeVertices[4 * 3 * i + 2] = v1.z

            edgeVertices[4 * 3 * i + 3] = v1Extracted.x
            edgeVertices[4 * 3 * i + 4] = v1Extracted.y
            edgeVertices[4 * 3 * i + 5] = v1Extracted.z
            
            edgeVertices[4 * 3 * i + 6] = v2Extracted.x
            edgeVertices[4 * 3 * i + 7] = v2Extracted.y
            edgeVertices[4 * 3 * i + 8] = v2Extracted.z
            
            edgeVertices[4 * 3 * i + 9] = v2.x
            edgeVertices[4 * 3 * i + 10] = v2.y
            edgeVertices[4 * 3 * i + 11] = v2.z
        }
        return edgeVertices
    }
    
    class func createVertexGeometry(_ terrain: TerrainData, xyScale : Float, zScale : Float) -> [Float]
    {
        let vertexCount = terrain.width * terrain.height
        
        var vertices : [Float] = [Float](repeating: 0.0, count: vertexCount * 3)
        
        for y in 0 ..< terrain.height
        {
            for x in 0 ..< terrain.width
            {
                let vertex = (y * terrain.width + x)
                vertices[3 * vertex + 0] = Float(x) * xyScale
                vertices[3 * vertex + 1] = Float(y) * xyScale
                vertices[3 * vertex + 2] = terrain.data[vertex] * zScale
            }
        }
        return vertices
    }
    
    class func createNormalGeometry(_ terrain: TerrainData, xyScale: Float, zScale: Float) -> [Float]
    {
        let vertexCount = terrain.width * terrain.height
        
        var normals : [Float] = [Float](repeating: 0.0, count: vertexCount * 3)
        
        for y in 0 ..< terrain.height
        {
            for x in 0 ..< terrain.width
            {
                let vertex = (y * terrain.width + x)
                
                let prefx = max(0, x - 1)
                let postx = min(x + 1, terrain.width - 1)
                let prefy = max(0, y - 1)
                let posty = min(y + 1, terrain.height - 1)
                
                let vprex = (y * terrain.width + prefx)
                let vpostx = (y * terrain.width + postx)
                let vprey = (prefy * terrain.width + x)
                let vposty = (posty * terrain.width + x)
                let vdx = GLKVector3(v: (2 * xyScale, 0, (terrain.data[vpostx] - terrain.data[vprex]) * zScale) )
                let vdy = GLKVector3(v: (0, 2 * xyScale, (terrain.data[vposty] - terrain.data[vprey]) * zScale) )
                let vTemp = GLKVector3CrossProduct(vdx, vdy)
                let vNormal = GLKVector3Normalize(vTemp)
                
                normals[3 * vertex + 0] = vNormal.x
                normals[3 * vertex + 1] = vNormal.y
                normals[3 * vertex + 2] = vNormal.z
            }
        }
        return normals
    }
    
    class func createWireframeIndices(_ terrain: TerrainData, triangulationType: Int) -> [UInt32]
    {
        let primitiveCount = (terrain.width - 1) * (terrain.height - 1) * 5
        var indices : [UInt32] = [UInt32](repeating: 0, count: primitiveCount * 2)
        
        var primitive = 0;
        
        for y in 0 ..< (terrain.height - 1)
        {
            for x in 0 ..< (terrain.width - 1)
            {
                let v1 = (y + 0) * terrain.width + (x + 0)
                let v2 = (y + 0) * terrain.width + (x + 1)
                let v3 = (y + 1) * terrain.width + (x + 0)
                let v4 = (y + 1) * terrain.width + (x + 1)
                
                let d14 = abs(terrain.data[v1] - terrain.data[v4])
                let d23 = abs(terrain.data[v2] - terrain.data[v3])
                
                let wireframe2 =
                    (d14 < d23) ?
                        // ((x + y) % 2 == 0) ?
                        [ v1, v2, v1, v3, v2, v4, v3, v4, v1, v4 ]  :
                        [ v1, v2, v1, v3, v2, v4, v3, v4, v2, v3 ];
                
                let wireframe1 = ((x + y) % 2 == 0) ?
                    [ v1, v2, v1, v3, v2, v4, v3, v4, v1, v4 ]  :
                    [ v1, v2, v1, v3, v2, v4, v3, v4, v2, v3 ];
                
                let wireframe0 = [ v1, v2, v1, v3, v2, v4, v3, v4, v1, v4 ];
                
                var wireframe : [Int]
                
                switch(triangulationType)
                {
                case 0: wireframe = wireframe0
                case 1: wireframe = wireframe1
                case 2: wireframe = wireframe2
                default: wireframe = wireframe0
                    print("not supposed to happen")
                }
                
                for i in 0 ..< 5
                {
                    for j in 0 ..< 2
                    {
                        indices[2 * primitive + j] = UInt32(wireframe[2 * i + j])
                    }
                    primitive += 1
                }
            }
        }
        return indices
        
    }
    
    class func createTriangleIndices(_ terrain: TerrainData, triangulationType: Int) -> [UInt32]
    {
        let primitiveCount = (terrain.width - 1) * (terrain.height - 1) * 2
        var indices : [UInt32] = [UInt32](repeating: 0, count: primitiveCount * 3)
        
        var triangle = 0;
        
        for y in 0 ..< (terrain.height - 1)
        {
            for x in 0 ..< (terrain.width - 1)
            {
                let v1 = (y + 0) * terrain.width + (x + 0)
                let v2 = (y + 0) * terrain.width + (x + 1)
                let v3 = (y + 1) * terrain.width + (x + 0)
                let v4 = (y + 1) * terrain.width + (x + 1)
                
                let d14 = abs(terrain.data[v1] - terrain.data[v4])
                let d23 = abs(terrain.data[v2] - terrain.data[v3])
                
                let solid2 = (d14 < d23) ?
                    [ v1, v2, v3, v2, v4, v3 ] :
                    [ v1, v2, v4, v1, v4, v3 ];
                
                let solid1 = ((x + y) % 2 == 0) ?
                    [ v1, v2, v3, v2, v4, v3 ] :
                    [ v1, v2, v4, v1, v4, v3 ];
                
                let solid0 = [ v1, v2, v3, v2, v4, v3 ]
                
                var solid : [Int]
                
                switch(triangulationType)
                {
                case 0: solid = solid0
                case 1: solid = solid1
                case 2: solid = solid2
                default: solid = solid0
                print("not supposed to happen")
                }
                
                for i in 0 ..< 6
                {
                    indices[3 * triangle + i] = UInt32(solid[i])
                }
                triangle += 2
                
                // TODO: Create adjacency directly (faster then then the
                // general adjacency computiation)
            }
        }
        return indices
    }
    
    func createDebugNormalGeometry()
    {
        self.normalVertexcount = 2 * self.vertexCount
        self.normalVertices = [Float](repeating: 0.0, count: self.normalVertexcount * 3)
        self.normalColors = [Float](repeating: 0.0, count: self.normalVertexcount * 4)
        
        for i in 0 ..< self.vertexCount
        {
            normalVertices![6 * i + 0] = self.vertices![3 * i + 0];
            normalVertices![6 * i + 1] = self.vertices![3 * i + 1];
            normalVertices![6 * i + 2] = self.vertices![3 * i + 2];
            normalVertices![6 * i + 3] = self.vertices![3 * i + 0] + self.normals![3 * i + 0];
            normalVertices![6 * i + 4] = self.vertices![3 * i + 1] + self.normals![3 * i + 1];
            normalVertices![6 * i + 5] = self.vertices![3 * i + 2] + self.normals![3 * i + 2];
            
            normalColors![8 * i + 0] = 1.0;
            normalColors![8 * i + 1] = 0.0;
            normalColors![8 * i + 2] = 0.0;
            normalColors![8 * i + 3] = 1.0;
            
            normalColors![8 * i + 4] = 1.0;
            normalColors![8 * i + 5] = 1.0;
            normalColors![8 * i + 6] = 0.0;
            normalColors![8 * i + 7] = 1.0;
        }
    }
    
    func pushTerrainVertices()
    {
        glVertexPointer(3, GLenum(GL_FLOAT), 0, self.vertices!)
        glColorPointer(4, GLenum(GL_FLOAT), 0, self.colors!)
        glNormalPointer(GLenum(GL_FLOAT), 0, self.normals!)
        glEnableClientState(GLenum(GL_VERTEX_ARRAY))
        glEnableClientState(GLenum(GL_COLOR_ARRAY))
        glEnableClientState(GLenum(GL_NORMAL_ARRAY))
        
        if(self.isWireframe)
        {
            glDrawElements(GLenum(GL_LINES), GLsizei(2 * self.primitiveCount), GLenum(GL_UNSIGNED_INT), self.indices!)
        }
        else
        {
            glDrawElements(GLenum(GL_TRIANGLES), GLsizei(3 * self.primitiveCount), GLenum(GL_UNSIGNED_INT), self.indices!)
        }
        glDisableClientState(GLenum(GL_NORMAL_ARRAY))
        glDisableClientState(GLenum(GL_COLOR_ARRAY))
        glDisableClientState(GLenum(GL_VERTEX_ARRAY))

    }
    
    func setupAmbientLightParameters()
    {
        let light0diffuse : [Float] = [ 0, 0, 0, 1 ]
        let light0ambient : [Float] = [ 0.2, 0.2, 0.2, 1 ]
        let light0specular : [Float] = [ 0, 0, 0, 1 ]
        
        glEnable( GLenum(GL_LIGHT0) )
        glEnable( GLenum(GL_LIGHTING) )
        glLightfv( GLenum(GL_LIGHT0), GLenum(GL_DIFFUSE), light0diffuse)
        glLightfv( GLenum(GL_LIGHT0), GLenum(GL_AMBIENT), light0ambient)
        glLightfv( GLenum(GL_LIGHT0), GLenum(GL_SPECULAR), light0specular)
        
        // default behaviour in OpenGL ES
        // glColorMaterial( GLenum(GL_FRONT), GLenum(GL_AMBIENT_AND_DIFFUSE) )
        glEnable( GLenum(GL_COLOR_MATERIAL) )
        // glEnable( GLenum(GL_RESCALE_NORMAL ) )
    }
    
    func setupDiffuseLightParameters()
    {
        let light0diffuse : [Float] = [ 1, 1, 1, 1 ]
        let light0ambient : [Float] = [ 0, 0, 0, 1 ]
        let light0specular : [Float] = [ 0, 0, 0, 1 ]
        
        glEnable( GLenum(GL_LIGHT0) )
        glEnable( GLenum(GL_LIGHTING) )
        glLightfv( GLenum(GL_LIGHT0), GLenum(GL_DIFFUSE), light0diffuse)
        glLightfv( GLenum(GL_LIGHT0), GLenum(GL_AMBIENT), light0ambient)
        glLightfv( GLenum(GL_LIGHT0), GLenum(GL_SPECULAR), light0specular)
        
        // default behaviour in OpenGL ES
        // glColorMaterial( GLenum(GL_FRONT), GLenum(GL_AMBIENT_AND_DIFFUSE) )
        glEnable( GLenum(GL_COLOR_MATERIAL) )
        // glEnable( GLenum(GL_RESCALE_NORMAL ) )
    }

    func pushShadowVolumeGeometry()
    {
        glVertexPointer(3, GLenum(GL_FLOAT), 0, self.edgeVertices!)
        glEnableClientState(GLenum(GL_VERTEX_ARRAY))
        glDrawArrays(GLenum(GL_QUADS), 0, GLsizei(self.edgeVertices!.count / 3))
        glDisableClientState(GLenum(GL_VERTEX_ARRAY))
    }
    
    func pushShadowEdges()
    {
        var edgeIndices : [UInt32] = [UInt32](repeating: 0,
                                              count: self.edgeVertices!.count / 6)
        for i in 0..<(edgeIndices.count / 2)
        {
            edgeIndices[2 * i + 0] = UInt32(4 * i)
            edgeIndices[2 * i + 1] = UInt32(4 * i + 3)
        }
        glVertexPointer(3, GLenum(GL_FLOAT), 0, self.edgeVertices!)
        glEnableClientState(GLenum(GL_VERTEX_ARRAY))
            glDrawElements(GLenum(GL_LINES), GLsizei(edgeIndices.count), GLenum(GL_UNSIGNED_INT), edgeIndices)
        glDisableClientState(GLenum(GL_VERTEX_ARRAY))
    }
    
    /**
     Renders terrain geometry either as triangles or as wireframe.
     Relies on createVertexGeometry(), createVertexColors(),
     createNormalGeometry(), and either createTriangleIndices() or
     createWireframeIndices() being called before
     
     Optionally draws normals for debugging (relies on createDebugNormalGeometry()
     being called before)
     */
    func renderTerrainGeometry()
    {
        setupAmbientLightParameters()
        
        glDisable(GLenum(GL_BLEND))
        
        glCullFace( GLenum(GL_BACK) )
        glEnable( GLenum(GL_CULL_FACE) )
        pushTerrainVertices()
        
        glDepthMask( GLboolean(GL_FALSE) )
        glColorMask( GLboolean(GL_FALSE), GLboolean(GL_FALSE), GLboolean(GL_FALSE), GLboolean(GL_FALSE) )

        // setting depth func is not really necessary
        glDepthFunc(GLenum(GL_LEQUAL))

        // increase the stencil buffer for everything (guess this should only be for
        // front faces of volumes, but currently we don't have any true back faces yet)
        glEnable(GLenum(GL_STENCIL_TEST))
        glStencilFunc( GLenum(GL_ALWAYS), 0, 127)
        
        glEnable(GLenum(GL_CULL_FACE))
        glCullFace( GLenum(GL_BACK) )
        glStencilOp( GLenum(GL_KEEP), GLenum(GL_KEEP), GLenum(GL_INCR) )
        pushShadowVolumeGeometry()
        glCullFace( GLenum(GL_FRONT) )
        glStencilOp( GLenum(GL_KEEP), GLenum(GL_KEEP), GLenum(GL_DECR) )
        pushShadowVolumeGeometry()
        
        glCullFace( GLenum(GL_BACK) )
        glDepthMask( GLboolean(GL_TRUE) )
        glColorMask( GLboolean(GL_TRUE), GLboolean(GL_TRUE), GLboolean(GL_TRUE), GLboolean(GL_TRUE) )
        
        glStencilOp( GLenum(GL_KEEP), GLenum(GL_KEEP), GLenum(GL_KEEP) )
        glStencilFunc( GLenum(GL_EQUAL), 0, 127 )
        
        setupDiffuseLightParameters()
        
        glDepthFunc(GLenum(GL_LEQUAL))
        glEnable(GLenum(GL_BLEND))
        glBlendFunc(GLenum(GL_ONE), GLenum(GL_ONE))
        
        glCullFace( GLenum(GL_BACK) )
        glEnable( GLenum(GL_CULL_FACE) )
        
        glEnable( GLenum(GL_STENCIL_TEST) )
        pushTerrainVertices()
        glDisable( GLenum(GL_STENCIL_TEST) )
        
        glDisable( GLenum(GL_LIGHT0) )
        glDisable( GLenum(GL_LIGHTING) )
        
        if(self.showDebugNormals)
        {
            glVertexPointer(3, GLenum(GL_FLOAT), 0, self.normalVertices!)
            glColorPointer(4, GLenum(GL_FLOAT), 0, self.normalColors!)
            glEnableClientState(GLenum(GL_VERTEX_ARRAY))
            glEnableClientState(GLenum(GL_COLOR_ARRAY))
            glDrawArrays(GLenum(GL_LINES), 0, GLsizei(self.normalVertexcount))
            glDisableClientState(GLenum(GL_COLOR_ARRAY))
            glDisableClientState(GLenum(GL_VERTEX_ARRAY))
        }
        
        if(self.showDebugShadowGeometry)
        {
            // glPolygonOffset(1.0, 1.0)
            glPolygonMode(GLenum(GL_FRONT_AND_BACK), GLenum(GL_LINE))
            glEnable(GLenum(GL_CULL_FACE))
            
            // glDepthFunc(GLenum(GL_LEQUAL))
            
            glCullFace(GLenum(GL_FRONT))
            // glDisable(GLenum(GL_DEPTH_TEST))
            glColor4f(1, 0, 0, 1)
            pushShadowVolumeGeometry()
            
            glCullFace(GLenum(GL_BACK))
            // glDisable(GLenum(GL_DEPTH_TEST))
            glColor4f(1, 1, 0, 1)
            pushShadowVolumeGeometry()
            
            // glEnable(GLenum(GL_DEPTH_TEST))
            glEnable(GLenum(GL_CULL_FACE))
            glPolygonMode(GLenum(GL_FRONT_AND_BACK), GLenum(GL_FILL))

            // glDisable(GLenum(GL_DEPTH_TEST))
            glColor4f(1, 0, 1, 1)
            pushShadowEdges()
            glEnable(GLenum(GL_DEPTH_TEST))
        }
        
        // full screen quad

//        glDisable(GLenum(GL_DEPTH_TEST))
//        glDisable(GLenum(GL_BLEND))
//        
//        glColor4f(1, 0, 0, 1)
//        
//        glEnable(GLenum(GL_STENCIL_TEST))
//        glStencilFunc( GLenum(GL_ALWAYS), 0, 127)
//        glStencilOp( GLenum(GL_KEEP), GLenum(GL_KEEP), GLenum(GL_INCR) )
//        drawFullScreenQuad(0.7)
//        
//        glColor4f(0, 1, 0, 1)
//        glStencilFunc( GLenum(GL_EQUAL), 0, 127 )
//        glEnable(GLenum(GL_STENCIL_TEST))
//        drawFullScreenQuad(0.9)
//        glDisable(GLenum(GL_STENCIL_TEST))
//
//        glEnable(GLenum(GL_DEPTH_TEST))
    }
    
    func drawFullScreenQuad(_ size: Float)
    {
        glMatrixMode(GLenum(GL_PROJECTION))
        glLoadIdentity()
        glMatrixMode(GLenum(GL_MODELVIEW))
        glLoadIdentity()
        glScalef(size, size, size)
        let quad : [Float] = [ -1, -1, 1, -1, 1, 1, -1, 1 ]
        glVertexPointer(2, GLenum(GL_FLOAT), 0, quad)
        glEnableClientState(GLenum(GL_VERTEX_ARRAY))
        glDrawArrays(GLenum(GL_QUADS), 0, 4)
        glDisableClientState(GLenum(GL_VERTEX_ARRAY))
    }
    
    
    func drawCamera(_ cam : TerrainCamera)
    {
        // TODO: untestet, unused
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
        TerrainRenderer.drawAsLines(vertices, colors: colors)
    }
    
    class func drawAsLines(_ vertices : [Float], colors : [Float])
    {
        glVertexPointer(3, GLenum(GL_FLOAT), 0, vertices)
        glColorPointer(4, GLenum(GL_FLOAT), 0, colors)
        glEnableClientState(GLenum(GL_VERTEX_ARRAY))
        glEnableClientState(GLenum(GL_COLOR_ARRAY))
        glDrawArrays(GLenum(GL_LINES), 0, GLsizei(vertices.count / 3))
        glDisableClientState(GLenum(GL_COLOR_ARRAY))
        glDisableClientState(GLenum(GL_VERTEX_ARRAY))
    }
    
    class func simpleTriangle()
    {
        // TODO: untestet, unused
        let z : Float = -0.5
        let vertices : [Float] = [ 0, 0, z, 1, 0, z, 0, 1, z]
        let colors : [Float] = [ 1, 0, 0, 1, 0, 1, 0, 1, 0, 0, 1, 1 ]
        let indices : [UInt32] = [ 0, 1, 2 ]
        
        glVertexPointer(3, GLenum(GL_FLOAT), 0, vertices)
        glColorPointer(4, GLenum(GL_FLOAT), 0, colors)
        glEnableClientState(GLenum(GL_VERTEX_ARRAY))
        glEnableClientState(GLenum(GL_COLOR_ARRAY))
        glDrawArrays(GLenum(GL_TRIANGLES), 0, GLsizei(3))
        glDrawElements(GLenum(GL_TRIANGLES), 3, GLenum(GL_UNSIGNED_INT), indices)
        glDisableClientState(GLenum(GL_COLOR_ARRAY))
        glDisableClientState(GLenum(GL_VERTEX_ARRAY))
    }
    
    class func simpleTetrahedron(_ size : Float, location : GLKVector3)
    {
        // TODO: render edges as well (in a contrast color)
        let cos30 : Float = cos( .pi / 6.0 )
        let sin30 : Float = sin( .pi / 6.0 )
        var vertices : [Float] = [
            0, 0, 1,
            cos30, 0, -sin30,
            -cos30 * cos30, sin30 * cos30, -sin30,
            -cos30 * cos30, -sin30 * cos30, -sin30
        ]
        for i in 0 ..< 12
        {
            vertices[i] *= size
        }
        
        for i in 0...3
        {
            vertices[3 * i + 0] += location.x
            vertices[3 * i + 1] += location.y
            vertices[3 * i + 2] += location.z
        }
        let indices : [UInt32] = [ 0, 1, 2, 0, 2, 3, 0, 3, 1, 1, 3, 2 ]
        glVertexPointer(3, GLenum(GL_FLOAT), 0, vertices)
        glColor4f(1.0, 1.0, 0.0, 1.0)
        glEnableClientState(GLenum(GL_VERTEX_ARRAY))
        glDrawElements(GLenum(GL_TRIANGLES), 12, GLenum(GL_UNSIGNED_INT), indices)
        glDisableClientState(GLenum(GL_VERTEX_ARRAY))
    }
    
    class func intersect(_ origin : GLKVector3, direction : GLKVector3) -> GLKVector3
    {
        // find the square origion contains
        // check intersection for both triangles in that square
        // advance to next square
        
        // TODO: totally incomplete, unused
        return GLKVector3Make(0, 0, 0)
    }
}


