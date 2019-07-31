//
//  ArcView.swift
//
//  Created by Jonathan Gomes on 30/07/19.
//  Copyright © 2019 Jonathan Gomes. All rights reserved.
//

import UIKit

@IBDesignable
class ArcView: UIView {
    @IBInspectable var arcWidth: CGFloat = 5.0
    @IBInspectable var arcWidthForEmptySection: CGFloat = 3.0
    @IBInspectable public dynamic var percentage: CGFloat = 50.0 {
        didSet {
            percentageLayer.percentage = percentage
        }
    }
    @IBInspectable var fillColor: UIColor = .purple
    @IBInspectable var emptyColor: UIColor = UIColor(hexadecimal: 0xe8e8e8)
    @IBInspectable var gradientLayer: Bool = false
    @IBInspectable var gradientColorStart: UIColor = UIColor(hexadecimal: 0xfa6e8c).withAlphaComponent(0.5)
    @IBInspectable var gradientColorEnd: UIColor = UIColor(hexadecimal: 0xebe1c94).withAlphaComponent(0.5)
    @IBInspectable var gradientAlpha: CGFloat = 0.5{
        didSet {
            gradientColorStart = gradientColorStart.withAlphaComponent(gradientAlpha)
            gradientColorEnd = gradientColorEnd.withAlphaComponent(gradientAlpha)
        }
    }
    
    var rect: CGRect!
    fileprivate var fillPath: UIBezierPath!
    fileprivate var emptyPath: UIBezierPath!
    fileprivate var leftRightPadding:CGFloat = 10.0
    fileprivate var bottomPadding:CGFloat = 5.0
    fileprivate var animating: Bool = false
    
    fileprivate var percentageLayer: ArcProgressLayer {
        return layer as! ArcProgressLayer
    }
    override public class var layerClass: AnyClass {
        return ArcProgressLayer.self
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func draw(_ rect: CGRect) {
        self.rect = rect
        if !animating {
            self.createArc(rect)
        }
    }
    func createArc(_ rect: CGRect) {
        createEmptyArc(rect)
        self.fillPath = createAndStrokeFilledArc(rect)
    }
    func createArcPath(_ rect: CGRect, width: CGFloat) -> UIBezierPath {
        let path: UIBezierPath! = UIBezierPath()
        path.lineWidth = width
        path.lineCapStyle = .round
        return path
    }
    
    fileprivate func createEmptyArc(_ rect: CGRect) {
        emptyPath = createArcPath(rect, width: arcWidthForEmptySection)
        emptyPath.addArc(withCenter: CGPoint(x: rect.size.width/2, y: self.frame.size.height-bottomPadding),
                         radius: (rect.size.width-(leftRightPadding*2.5))/2,
                         startAngle: CGFloat(180.0).toRadians(),
            endAngle: CGFloat(0.0).toRadians(),
            clockwise: true)
        emptyColor.setStroke()
        emptyPath.stroke()
        emptyPath.close()
    }
    fileprivate func createAndStrokeFilledArc(_ rect: CGRect ) -> UIBezierPath {
        let path = createFilledArc(rect, self.frame)
        path.stroke()
        if(gradientLayer){
            addGradient(rect, to: path.cgPath)
        }
        path.close()
        return path
    }
    fileprivate func createFilledArc(_ rect: CGRect, _ frame: CGRect) -> UIBezierPath {
        let path = createArcPath(rect, width: arcWidth)
        path.addArc(withCenter: CGPoint(x: rect.size.width/2, y: frame.size.height-bottomPadding),
                        radius: (rect.size.width-(leftRightPadding*2.5))/2,
                        startAngle: CGFloat(180.0).toRadians(),
                        endAngle: CGFloat(180.0 + (180.0/100 * percentage)).toRadians(),
                        clockwise: true)
        fillColor.setStroke()
        return path
    }
    fileprivate func addGradient(_ rect: CGRect, to path: CGPath){
        let c = UIGraphicsGetCurrentContext()!
        c.saveGState()
        c.setLineWidth(arcWidth)
        c.addPath(path)
        c.replacePathWithStrokedPath()
        c.setLineCap(CGLineCap.round)
        c.clip()
        let colors = [self.gradientColorStart.cgColor, self.gradientColorEnd.cgColor]
        let offsets = [ CGFloat(0.0), CGFloat(1.0) ]
        let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: offsets)
        let start = rect.origin
        let end = CGPoint(x: rect.maxX, y: rect.maxY)
        c.drawLinearGradient(grad!, start: start, end: end, options: [])
        c.restoreGState()
        UIGraphicsEndImageContext()
    }
    override public func action(for layer: CALayer, forKey event: String) -> CAAction? {
        if event == #keyPath(ArcProgressLayer.percentage),
            let action = action(for: layer, forKey: #keyPath(backgroundColor)) as? CAAnimation {
            
            let animation = CABasicAnimation()
            animation.keyPath = #keyPath(ArcProgressLayer.percentage)
            animation.fromValue = percentageLayer.percentage
            animation.toValue = percentage
            animation.beginTime = action.beginTime
            animation.duration = action.duration
            animation.speed = action.speed
            animation.timeOffset = action.timeOffset
            animation.repeatCount = action.repeatCount
            animation.repeatDuration = action.repeatDuration
            animation.autoreverses = action.autoreverses
            animation.fillMode = action.fillMode
            animation.timingFunction = action.timingFunction
            animation.delegate = action.delegate
            self.layer.add(animation, forKey: #keyPath(ArcProgressLayer.percentage))
        }
        return super.action(for: layer, forKey: event)
    }
}
fileprivate class ArcProgressLayer: CALayer {
    @NSManaged var percentage: CGFloat
    
    override class func needsDisplay(forKey key: String) -> Bool {
        if key == #keyPath(percentage) {
            return true
        }
        return super.needsDisplay(forKey: key)
    }
    
    override func draw(in ctx: CGContext) {
        let view:ArcView = self.delegate as! ArcView
        view.animating = true
        super.draw(in: ctx)
        
        UIGraphicsPushContext(ctx)
        view.emptyPath = nil
        view.fillPath = nil
        
        view.createEmptyArc(view.rect)
        
        let fillPath: UIBezierPath! = UIBezierPath()
        fillPath.lineWidth = view.arcWidth
        fillPath.lineCapStyle = .round
        fillPath.addArc(withCenter: CGPoint(x: bounds.size.width/2, y: bounds.size.height-view.bottomPadding),
                        radius: (bounds.size.width-(view.leftRightPadding*2.5))/2,
                        startAngle: CGFloat(180.0).toRadians(),
                        endAngle: CGFloat(180.0 + (180.0/100 * percentage)).toRadians(),
                        clockwise: true)
        view.fillColor.setStroke()
        fillPath.stroke()
        addGradient(view: view, rect: bounds, to: fillPath.cgPath)
        fillPath.close()
        
        UIGraphicsPopContext()
    }
    fileprivate func addGradient(view: ArcView, rect: CGRect, to path: CGPath){
        let c = UIGraphicsGetCurrentContext()!
        c.saveGState()
        c.setLineWidth(view.arcWidth)
        c.addPath(path)
        c.replacePathWithStrokedPath()
        c.setLineCap(CGLineCap.round)
        c.clip()
        let colors = [view.gradientColorStart.cgColor, view.gradientColorEnd.cgColor]
        let offsets = [ CGFloat(0.0), CGFloat(1.0) ]
        let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: offsets)
        let start = rect.origin
        let end = CGPoint(x: rect.maxX, y: rect.maxY)
        c.drawLinearGradient(grad!, start: start, end: end, options: [])
        c.restoreGState()
        UIGraphicsEndImageContext()
    }
}
extension CGFloat {
    func toRadians() -> CGFloat {
        return self * CGFloat(CGFloat.pi) / 180.0
    }
}
protocol Coloring { }

extension Coloring where Self: UIColor {
    
    init(red: Int, green: Int, blue: Int) {
        
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    init(hexadecimal: Int) {
        self.init(red:(hexadecimal >> 16) & 0xff, green:(hexadecimal >> 8) & 0xff, blue:hexadecimal & 0xff)
    }
}

extension UIColor : Coloring { }
