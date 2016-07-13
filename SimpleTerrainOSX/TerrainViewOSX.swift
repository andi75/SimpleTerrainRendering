//
//  TerrainViewOSX.swift
//  SimpleTerrainRendering
//
//  Created by Andreas Umbach on 12.07.2016.
//  Copyright © 2016 Andreas Umbach. All rights reserved.
//

import Cocoa
import CoreGraphics

class TerrainViewOSX : NSOpenGLView
{
    override var acceptsFirstResponder: Bool { return true }
    
    let renderer = TerrainRenderer()
    
    var mousePosition : CGPoint = CGPointMake(0, 0)
    var mouseDown = false
    
    override func drawRect(dirtyRect: NSRect) {
        renderer.render(width: self.frame.width, height: self.frame.height)
        glFlush()
    }
    
    override func viewDidMoveToWindow() {
        // apparently all the following is unneeded
//        self.window?.makeKeyWindow()
//        if(self.window!.makeFirstResponder(self))
//        {
//            Swift.print("I should be first responder now")
//            Swift.print("AcceptsFirstResponder: \(self.acceptsFirstResponder)")
//        }
        // self.window?.acceptsMouseMovedEvents = true
    }
    
    override func acceptsFirstMouse(theEvent: NSEvent?) -> Bool {
        return true
    }
    
    override func mouseDown(theEvent: NSEvent) {
        Swift.print("mouse down")
        // CGDisplayHideCursor(kCGDirectMainDisplay)
        CGDisplayHideCursor(0)
        CGAssociateMouseAndMouseCursorPosition(0)
    }
    
    override func mouseUp(theEvent: NSEvent) {
        Swift.print("mouse up")
        // CGDisplayShowCursor(kCGDirectMainDisplay)
        CGAssociateMouseAndMouseCursorPosition(1)
        CGDisplayShowCursor(0)
    }
    
//    override func mouseMoved(theEvent: NSEvent) {
//    }
    
    override func mouseDragged(theEvent: NSEvent) {
        var dx : Int32 = 0, dy : Int32 = 0
        CGGetLastMouseDelta(&dx, &dy)
        Swift.print("delta: \(dx), \(dy)")
    }
    
    override func keyDown(theEvent: NSEvent) {
        Swift.print("key down")
    }
    
    override func keyUp(theEvent: NSEvent) {
        Swift.print("key up")
    }
}