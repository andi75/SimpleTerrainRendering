//
//  TerrainViewOSX.swift
//  SimpleTerrainRendering
//
//  Created by Andreas Umbach on 12.07.2016.
//  Copyright © 2016 Andreas Umbach. All rights reserved.
//

import Cocoa
import CoreGraphics

// TODO: add support for all the missing camera controls from the IOS version

class TerrainViewOSX : NSOpenGLView
{
    var displayLink : CVDisplayLink?
    var lasttime : Double = 0
    
    override var acceptsFirstResponder: Bool { return true }
    
    let renderer = TerrainRenderer()
    let qt = QuadTreeTerrain(maxLevel: 8)
    var qtDisplayLevel : Int = 0
    
    var mousePosition : CGPoint = CGPoint(x: 0, y: 0)
    var mouseDown = false
    
    let camMotion = CameraMotion()
    
    override func prepareOpenGL() {
        var swapInt : GLint = 1
        self.openGLContext?.setValues(&swapInt, for: NSOpenGLContextParameter.swapInterval)
        
        // copied some code from https://forums.developer.apple.com/thread/23142
        
        //  The callback function is called everytime CVDisplayLink says its time to get a new frame.
        func displayLinkOutputCallback(_ displayLink: CVDisplayLink, _ inNow: UnsafePointer<CVTimeStamp>, _ inOutputTime: UnsafePointer<CVTimeStamp>, _ flagsIn: CVOptionFlags, _ flagsOut: UnsafeMutablePointer<CVOptionFlags>, _ displayLinkContext: UnsafeMutableRawPointer) -> CVReturn {
            
            /*  The displayLinkContext is CVDisplayLink's parameter definition of the view in which we are working.
             In order to access the methods of a given view we need to specify what kind of view it is as right
             now the UnsafeMutablePointer<Void> just means we have a pointer to "something".  To cast the pointer
             such that the compiler at runtime can access the methods associated with our SwiftOpenGLView, we use
             an unsafeBitCast.  The definition of which states, "Returns the the bits of x, interpreted as having
             type U."  We may then call any of that view's methods.  Here we call drawView() which we draw a
             frame for rendering.  */
            unsafeBitCast(displayLinkContext, to: TerrainViewOSX.self).updateFrame()
            
            //  We are going to assume that everything went well for this mock up, and pass success as the CVReturn
            return kCVReturnSuccess
        }
        
        //  Grab the a link to the active displays, set the callback defined above, and start the link.
        /*  An alternative to a nested function is a global function or a closure passed as the argument--a local function
         (i.e. a function defined within the class) is NOT allowed. */
        //  The UnsafeMutablePointer<Void>(unsafeAddressOf(self)) passes a pointer to the instance of our class.
        CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)
        CVDisplayLinkSetOutputCallback(displayLink!, displayLinkOutputCallback, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))
        CVDisplayLinkStart(displayLink!)
        CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)
        
    }
    override func draw(_ dirtyRect: NSRect) {
        renderer.render(width: self.frame.width, height: self.frame.height)
        glFlush()
    }
    
    func updateFrame()
    {
//        Swift.print("update frame")
        // now, let's get a reliable time stamp, according to http://blog.airsource.co.uk/2010/03/15/quelle-heure-est-il/ this can be a little messy, see also https://forums.developer.apple.com/thread/12135
        
        // since we don't care about the user changing the system time mid-game, let's trust CFAbsoluteTimeGetCurrent()
        
        let now = CFAbsoluteTimeGetCurrent()
        if(lasttime == 0)
        {
            lasttime = now
            return
        }
        else
        {
            let dt = Float(now - lasttime)
            lasttime = now
            if(camMotion.isMoving)
            {
                camMotion.move(dt: dt, speed: 50, cam: renderer.cam!)
                self.needsDisplay = true
            }
        }
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
        renderer.zScale = 12
        
// apparently all the following is unneeded
//        self.window?.makeKeyWindow()
//        if(self.window!.makeFirstResponder(self))
//        {
//            Swift.print("I should be first responder now")
//            Swift.print("AcceptsFirstResponder: \(self.acceptsFirstResponder)")
//        }
        // self.window?.acceptsMouseMovedEvents = true
    }
    
    override func acceptsFirstMouse(for theEvent: NSEvent?) -> Bool {
        return true
    }
    
    override func mouseDown(with theEvent: NSEvent) {
//        Swift.print("mouse down")
        // CGDisplayHideCursor(kCGDirectMainDisplay)
        CGDisplayHideCursor(0)
        CGAssociateMouseAndMouseCursorPosition(0)
        
        // throw away first delta
        var dx : Int32 = 0, dy : Int32 = 0
        CGGetLastMouseDelta(&dx, &dy)
    }
    
    override func mouseUp(with theEvent: NSEvent) {
//        Swift.print("mouse up")
        // CGDisplayShowCursor(kCGDirectMainDisplay)
        CGAssociateMouseAndMouseCursorPosition(1)
        CGDisplayShowCursor(0)
    }
    
//    override func mouseMoved(theEvent: NSEvent) {
//    }
    
    override func mouseDragged(with theEvent: NSEvent) {
        var dx : Int32 = 0, dy : Int32 = 0
        CGGetLastMouseDelta(&dx, &dy)
        // Swift.print("delta: \(dx), \(dy)")
        
        renderer.cam?.phi += Float(-dx) * 0.01
        renderer.cam?.chi += Float(dy) * 0.01
        
        self.needsDisplay = true
    }
    
    override func keyDown(with theEvent: NSEvent) {
        // Swift.print("key down")
        let s = theEvent.charactersIgnoringModifiers
        switch(s!)
        {
        case "w": camMotion.forward = true // renderer.cam?.forwardBackwardPlanar(d)
        case "s": camMotion.backward = true // renderer.cam?.forwardBackwardPlanar(-d)
        case "a": camMotion.left = true // renderer.cam?.leftRight(-d)
        case "d": camMotion.right = true // renderer.cam?.leftRight(d)
        case " ": camMotion.up = true // renderer.cam?.lowerHigher(d)
        case "c": camMotion.down = true // renderer.cam?.lowerHigher(-d)
        default:
            self.interpretKeyEvents([theEvent])
        }
    }
    
    override func keyUp(with theEvent: NSEvent)
    {
        let s = theEvent.charactersIgnoringModifiers
        switch(s!)
        {
        case "w": camMotion.forward = false
        case "s": camMotion.backward = false
        case "a": camMotion.left = false
        case "d": camMotion.right = false
        case " ": camMotion.up = false
        case "c": camMotion.down = false
        default:
            break // do nothing
            // self.interpretKeyEvents([theEvent])
        }

    }
    
    override func insertText(_ insertString: Any) {
        let s = insertString as! String

        switch(s)
        {
        case ".": camMotion.stop()
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
            Swift.print("zScale: \(renderer.zScale)")
        case "h":
            renderer.zScale *= 1.0 / 1.1
            Swift.print("zScale: \(renderer.zScale)")
        case "n":
            renderer.showDebugNormals = !renderer.showDebugNormals
        case "m":
            renderer.showDebugShadowGeometry = !renderer.showDebugShadowGeometry

        default:
            Swift.print("unrecognized input: \(s)")
            break
        }
        self.needsDisplay = true
    }
}
