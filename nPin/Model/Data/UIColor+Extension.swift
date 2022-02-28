//
//  UIColor+Extension.swift
//  nPin
//
//  Created by Hamza Nizameddin on 03/09/2021.
//

import UIKit
import Foundation

/**
 Extension to the UIColor object to handle conversion to and from Hex string.
  - Note: Provides a convenience initializer to create a UIColor object from a color Hex string. Also provides a toHex computed variable to get the color hex string from a existing UIColor object
 */
extension UIColor
{

	// MARK: - Initialization

	convenience init?(hex: String)
	{
		var hexNormalized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
		hexNormalized = hexNormalized.replacingOccurrences(of: "#", with: "")

		// Helpers
		var rgb: UInt64 = 0
		var r: CGFloat = 0.0
		var g: CGFloat = 0.0
		var b: CGFloat = 0.0
		var a: CGFloat = 1.0
		let length = hexNormalized.count

		// Create Scanner
		Scanner(string: hexNormalized).scanHexInt64(&rgb)

		if length == 6 {
			r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
			g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
			b = CGFloat(rgb & 0x0000FF) / 255.0

		} else if length == 8 {
			r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
			g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
			b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
			a = CGFloat(rgb & 0x000000FF) / 255.0

		} else {
			return nil
		}

		self.init(red: r, green: g, blue: b, alpha: a)
	}
	
	// MARK: - Convenience Methods

	var toHex: String?
	{
		// Extract Components
		guard let components = cgColor.components, components.count >= 3 else {
			return nil
		}

		// Helpers
		let r = Float(components[0])
		let g = Float(components[1])
		let b = Float(components[2])
		var a = Float(1.0)

		if components.count >= 4 {
			a = Float(components[3])
		}

		// Create Hex String
		let hex = String(format: "%02lX%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255), lroundf(a * 255))

		return hex
	}

}
