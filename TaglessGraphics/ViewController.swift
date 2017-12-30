//
//  ViewController.swift
//  TaglessGraphics
//
//  Created by Chris Eidhof on 30.12.17.
//  Copyright © 2017 objc.io. All rights reserved.
//

//extension CGRect {
//    func divide(axis: UILayoutConstraintAxis, count: Int) -> [CGRect] {
//        switch axis {
//        case .horizontal:
//            let itemHeight = size.width / CGFloat(count)
//            let itemSize = CGSize(width: itemHeight, height: size.height)
//            return (0..<count).map {
//                CGRect(origin: CGPoint(x: origin.x + CGFloat($0) * itemHeight, y: origin.y),
//                       size: itemSize)
//            }
//        case .vertical:
//            let itemHeight = size.height / CGFloat(count)
//            let itemSize = CGSize(width: size.width, height: itemHeight)
//            return (0..<count).map {
//                CGRect(origin: CGPoint(x: origin.x, y: origin.y + CGFloat($0) * itemHeight),
//                       size: itemSize)
//            }
//        }
//    }
//}


import UIKit

protocol Drawing {
    static func rectangle(_ rect: CGRect, fill: UIColor) -> Self
    static func ellipse(in rect: CGRect, fill: UIColor) -> Self
    static func combined(_ layers: [Self]) -> Self
}

struct CGraphics {
    let draw: (CGContext) -> ()
}


extension CGraphics: Drawing {
    static func rectangle(_ rect: CGRect, fill: UIColor) -> CGraphics {
        return CGraphics { context in
            context.saveGState()
            context.setFillColor(fill.cgColor)
            context.fill(rect)
            context.restoreGState()
        }
    }
    
    static func ellipse(in rect: CGRect, fill: UIColor) -> CGraphics {
        return CGraphics { context in
            context.saveGState()
            context.setFillColor(fill.cgColor)
            context.fillEllipse(in: rect)
            context.restoreGState()
        }

    }
    
    static func combined(_ layers: [CGraphics]) -> CGraphics {
        return CGraphics { context in
            layers.forEach { $0.draw(context) }
        }
    }
}

struct CoreAnimation {
    let render: () -> CALayer
}

extension CoreAnimation: Drawing {
    static func rectangle(_ rect: CGRect, fill: UIColor) -> CoreAnimation {
        return CoreAnimation {
            let result = CALayer()
            result.frame = rect
            result.backgroundColor = fill.cgColor
            return result
        }
    }
    
    static func ellipse(in rect: CGRect, fill: UIColor) -> CoreAnimation {
        return CoreAnimation {
            let result = CAShapeLayer()
            let path = UIBezierPath(ovalIn: rect)
            result.path = path.cgPath
            result.fillColor = fill.cgColor
            return result
        }
    }
    
    static func combined(_ layers: [CoreAnimation]) -> CoreAnimation {
        return CoreAnimation {
            let result = CALayer()
            for c in layers {
                result.addSublayer(c.render())
            }
            return result
        }
    }
}

func sample<D: Drawing>() -> D {
    return .combined([
        .ellipse(in: CGRect(origin: .zero, size: CGSize(width: 100, height: 100)), fill: .red),
        .rectangle(CGRect(origin: CGPoint(x: 50, y: 50), size: CGSize(width: 100, height: 100)), fill: .blue)
    ])
}

protocol Shadow {
    static func shadow(opacity: CGFloat, offset: CGSize, radius: CGFloat, _ child: Self) -> Self
}

extension Shadow {
    // unfortunately, protocols don't allow default arguments
    static func shadow(_ child: Self) -> Self {
        return shadow(opacity: 0.75, offset: CGSize(width: 0, height: 3), radius: 3, child)
    }
}

extension CoreAnimation: Shadow {
    static func shadow(opacity: CGFloat, offset: CGSize, radius: CGFloat, _ child: CoreAnimation) -> CoreAnimation {
        return CoreAnimation {
            let layer = child.render()
            layer.shadowOpacity = Float(opacity)
            layer.shadowRadius = radius
            layer.shadowOffset = offset
            return layer
        }
    }
}

func sample2<D: Drawing & Shadow>() -> D {
    return .combined([
        .shadow(.ellipse(in: CGRect(origin: .zero, size: CGSize(width: 100, height: 100)), fill: .red)),
        .rectangle(CGRect(origin: CGPoint(x: 50, y: 50), size: CGSize(width: 100, height: 100)), fill: .blue)
        ])
}

class ViewController: UIViewController {
    let iv = UIImageView()
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(iv)
    }
    
    override func viewWillAppear(_ animated: Bool) {        
        iv.frame = view.bounds
        let renderer = UIGraphicsImageRenderer(bounds: view.bounds)
        iv.image = renderer.image { context in
            let drawing: CGraphics = sample()
            drawing.draw(context.cgContext)
        }        
    }
}

class CAViewController: UIViewController {
    override func viewWillAppear(_ animated: Bool) {
        let drawing: CoreAnimation = sample2()
        view.layer.addSublayer(drawing.render())
    }
}
