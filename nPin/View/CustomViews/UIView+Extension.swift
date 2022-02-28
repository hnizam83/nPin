//
//  UIView+Extension.swift
//  nPin
//
//  Created by Hamza Nizameddin on 02/08/2021.
//

import UIKit

// UIView extension to shake little circle images above number pad when the user enters a wrong passcode
extension UIView
{
	// Using CAMediaTimingFunction
	func shake(duration: TimeInterval = 0.5, values: [CGFloat]) {
		let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")

		animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)

		animation.duration = duration // You can set fix duration
		animation.values = values  // You can set fix values here also
		self.layer.add(animation, forKey: "shake")
	}


	// Using SpringWithDamping
	func shake(duration: TimeInterval = 0.5, xValue: CGFloat = 12, yValue: CGFloat = 0) {
		self.transform = CGAffineTransform(translationX: xValue, y: yValue)
		UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.4, initialSpringVelocity: 1.0, options: .curveEaseInOut, animations: {
			self.transform = CGAffineTransform.identity
		}, completion: nil)

	}


	// Using CABasicAnimation
	func shake(duration: TimeInterval = 0.05, shakeCount: Float = 6, xValue: CGFloat = 12, yValue: CGFloat = 0){
		let animation = CABasicAnimation(keyPath: "position")
		animation.duration = duration
		animation.repeatCount = shakeCount
		animation.autoreverses = true
		animation.fromValue = NSValue(cgPoint: CGPoint(x: self.center.x - xValue, y: self.center.y - yValue))
		animation.toValue = NSValue(cgPoint: CGPoint(x: self.center.x + xValue, y: self.center.y - yValue))
		self.layer.add(animation, forKey: "shake")
	}

}
