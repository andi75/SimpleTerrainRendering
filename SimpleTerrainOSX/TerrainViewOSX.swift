//
//  TerrainViewOSX.swift
//  SimpleTerrainRendering
//
//  Created by Andreas Umbach on 12.07.2016.
//  Copyright © 2016 Andreas Umbach. All rights reserved.
//

import Cocoa

class TerrainViewOSX : NSOpenGLView
{
    let renderer = TerrainRenderer()
    
    override func drawRect(dirtyRect: NSRect) {
        renderer.render(width: self.frame.width, height: self.frame.height)
        glFlush()
    }
    
    override func acceptsFirstMouse(theEvent: NSEvent?) -> Bool {
        return true
    }
    
    override func mouseDown(theEvent: NSEvent) {
        Swift.print("mouse down")
    }
    override func keyDown(theEvent: NSEvent) {
        Swift.print("key down")
    }
}