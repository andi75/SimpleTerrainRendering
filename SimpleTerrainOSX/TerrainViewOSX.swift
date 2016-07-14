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
    let qt = QuadTreeTerrain(maxLevel: 8)
    var qtDisplayLevel : Int = 0
    
    var mousePosition : CGPoint = CGPointMake(0, 0)
    var mouseDown = false
    
    override func drawRect(dirtyRect: NSRect) {
        renderer.render(width: self.frame.width, height: self.frame.height)
        glFlush()
    }
    
    func recreateTerrain()
    {
        TerrainFactory.recreateQuadTerrain(qt)
        qtDisplayLevel = qt.maxLevel
        renderer.xyScale = 1
        renderer.data = TerrainData(qt: qt, level: qtDisplayLevel)
        Swift.print("Height range: \(renderer.data!.minHeight) to \(renderer.data!.maxHeight)")
    }
    
    override func viewDidMoveToWindow() {
        recreateTerrain()
        renderer.cam = TerrainCamera(terrain: renderer.data!)
        
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
//        Swift.print("mouse down")
        // CGDisplayHideCursor(kCGDirectMainDisplay)
        CGDisplayHideCursor(0)
        CGAssociateMouseAndMouseCursorPosition(0)
        
        // throw away first delta
        var dx : Int32 = 0, dy : Int32 = 0
        CGGetLastMouseDelta(&dx, &dy)
    }
    
    override func mouseUp(theEvent: NSEvent) {
//        Swift.print("mouse up")
        // CGDisplayShowCursor(kCGDirectMainDisplay)
        CGAssociateMouseAndMouseCursorPosition(1)
        CGDisplayShowCursor(0)
    }
    
//    override func mouseMoved(theEvent: NSEvent) {
//    }
    
    override func mouseDragged(theEvent: NSEvent) {
        var dx : Int32 = 0, dy : Int32 = 0
        CGGetLastMouseDelta(&dx, &dy)
        // Swift.print("delta: \(dx), \(dy)")
        
        renderer.cam?.phi += Float(-dx) * 0.01
        renderer.cam?.chi += Float(dy) * 0.01
        
        self.needsDisplay = true
    }
    
    override func keyDown(theEvent: NSEvent) {
        // Swift.print("key down")
        self.interpretKeyEvents([theEvent])
    }
    
    override func insertText(insertString: AnyObject) {
        let s = insertString as! String
        let d : Float = 1.0
        switch(s)
        {
        case "w": renderer.cam?.forwardBackwardPlanar(d)
        case "s": renderer.cam?.forwardBackwardPlanar(-d)
        case "a": renderer.cam?.leftRight(-d)
        case "d": renderer.cam?.leftRight(d)
        case " ": renderer.cam?.lowerHigher(d)
        case "c": renderer.cam?.lowerHigher(-d)
            
        case "t": renderer.triangulationType = (renderer.triangulationType + 1) % 3
        case "r": renderer.isWireframe = !renderer.isWireframe
        case "f": renderer.isCameraLight = !renderer.isCameraLight
            
        case "z":
            renderer.data?.smooth()
            renderer.invalidateGeometry()
            
        case "u":
            recreateTerrain()
        case "i":
            qtDisplayLevel = max(qtDisplayLevel - 1, 0)
            renderer.data = TerrainData(qt: qt, level: qtDisplayLevel)
            renderer.xyScale = Float(1 << (qt.maxLevel - qtDisplayLevel))
        case "o":
            qtDisplayLevel = min(qtDisplayLevel + 1, qt.maxLevel)
            renderer.data = TerrainData(qt: qt, level: qtDisplayLevel)
            renderer.xyScale = Float(1 << (qt.maxLevel - qtDisplayLevel))
        case "g":
            renderer.zScale *= 1.1
        case "h":
            renderer.zScale *= 1.0 / 1.1
        case "n":
            renderer.showDebugNormals = !renderer.showDebugNormals
        default:
            Swift.print("unrecognized input: \(s)")
            break
        }
        self.needsDisplay = true
    }
    override func keyUp(theEvent: NSEvent) {
        // Swift.print("key up")
    }
}