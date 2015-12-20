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
    override func drawRect(rect: CGRect) {
        glClearColor(0.0, 0.0, 0.5, 0.0)
        glClear( GLbitfield(GL_COLOR_BUFFER_BIT) )
        // glViewport(0, 0, GLsizei(self.frame.width), GLsizei(self.frame.height))
        glMatrixMode(GLenum(GL_PROJECTION))
        glLoadIdentity()
        glMatrixMode(GLenum(GL_MODELVIEW))
        glLoadIdentity()
    
        
        let colors : [Float] = [
            1, 0, 0, 1,
            0, 1, 0, 1,
            0, 0, 1, 1,
            1, 0.5, 0.5, 1,
            0.5, 1, 0.5, 1,
            0.5, 0.5, 1, 1
        ]
        let vertices : [Float] = [
            -1, -1, 0, 1, -1, 0, 0, 1, 0,
            0, 0, 0, 1, 0, 0, 0, 1, 0
        ]
        glVertexPointer(3, GLenum(GL_FLOAT), 0, vertices)
        glColorPointer(4, GLenum(GL_FLOAT), 0, colors)
        glEnableClientState(GLenum(GL_VERTEX_ARRAY))
        glEnableClientState(GLenum(GL_COLOR_ARRAY))
        glDrawArrays(GLenum(GL_TRIANGLES), 0, 6) 
    }
}


