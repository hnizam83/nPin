//
//  PasscodeViewController.swift
//  nPin
//
//  Created by Hamza Nizameddin on 02/08/2021.
//

import UIKit
import LocalAuthentication
import KeychainSwift

class DeprecatedNewPasscodeViewController: UIViewController
{
	@IBOutlet weak var enterPasscodeLabel: UILabel!
	@IBOutlet weak var circlesStackView: UIStackView!
	@IBOutlet weak var placeholderCircle: UIImageView!
	@IBOutlet var circles: [UIImageView]!
	@IBOutlet weak var circlesStackViewBottomConstraint: NSLayoutConstraint!
	@IBOutlet weak var deleteButton: UIButton!
	@IBOutlet weak var hiddenButton: UIButton!
	
	@IBOutlet weak var verticalStackView: UIStackView!
	@IBOutlet weak var verticalStackViewVerticalConstraint: NSLayoutConstraint!
	@IBOutlet var horizontalStackViews: [UIStackView]!
	@IBOutlet var buttons: [UIButton]!
	@IBOutlet weak var errorLabel: UILabel!
		
	private var passcode: String = ""
	private var passcodeLength: Int = 6
	
	private var firstPasscode: String = ""
	private var secondPasscode: String = ""
	
	private let keychainPassword = (UIApplication.shared.delegate as!AppDelegate).keychainPassword
	
	// MARK: - View Controller Life Cycle
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		self.setupFormatting()
		
	}
	
	override func viewDidAppear(_ animated: Bool)
	{
		super.viewDidAppear(animated)
		
	}
	
	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)
		self.errorLabel.isHidden = true
		self.resetNumpad()
	}
	
	// MARK: - Event Handlers
	
	@IBAction func buttonPressed(_ sender: UIButton)
	{
		if(passcode.count < 6)
		{
			let circle = circles[passcode.count]
			circle.image = UIImage(systemName: nPin.filledCircleImageName)
			circle.setNeedsDisplay()
			passcode += sender.titleLabel!.text!
		}
		
		if(passcode.count >= 6)
		{
			if firstPasscode.count == 0 {
				firstPasscode = passcode
				enterPasscodeLabel.text = NSLocalizedString("Confirm New Passcode", comment: "Label to confirm new passcode entry")
				errorLabel.isHidden = true
				resetNumpad()
			} else {
				if passcode == firstPasscode {
					//keychain.set(passcode, forKey: nPin.passcodeKey)
					if let navigationController = self.navigationController {
						navigationController.popViewController(animated: true)
					} else {
						dismiss(animated: true, completion: nil)
					}
				} else {
					DispatchQueue.main.async {
						self.enterPasscodeLabel.text = NSLocalizedString("Enter New Passcode", comment: "Label for new passcode entry")
						self.errorLabel.isHidden = false
						self.firstPasscode = ""
						self.circlesStackView.shake(shakeCount: 5)
						self.resetNumpad()
					}
					
				}
			}
		}
	}
	
	@IBAction func deleteButtonPressed(_ sender: UIButton)
	{
		if self.passcode.count > 0
		{
			self.passcode.removeLast()
			self.circles[self.passcode.count].image = UIImage(systemName: nPin.emptyCircleImageName)
		}
	}
	
	// MARK: - Reset numpad
	
	func resetNumpad()
	{
		passcode = ""
		for circle in circles {
			circle.image = UIImage(systemName: nPin.emptyCircleImageName)
		}
	}
	
	// MARK: - Formatting
	
	private func setupFormatting()
	{
		// calculate the button size based on the view width
		let buttonSize: CGFloat = (self.view.frame.width - 20) * 0.20
		let buttonCornerRadius = buttonSize * 0.50
		let buttonLabelFontSize = buttonSize * 0.50
		let circleSize = buttonSize * 0.20
		let circleStackViewSpacing = buttonSize * 0.30
		let verticalStackViewSpacing = buttonSize * 0.25
		let verticalStackViewVerticalConstraintConstant = buttonSize * 0.50
		let horizontalStackViewSpacing = buttonSize * 0.30
		let enterPasscodeLabelFontSize = buttonSize * 0.25
		let deleteButtonPointSize = buttonSize * 0.35
		
		// set the font size for the "Enter Passcode" label
		enterPasscodeLabel.font = UIFont(name: nPin.fontName, size: enterPasscodeLabelFontSize)
		
		// set the stack view spacing based on the button size
		verticalStackView.spacing = verticalStackViewSpacing
		for horizontalStackView in horizontalStackViews {
			horizontalStackView.spacing = horizontalStackViewSpacing
		}
		
		// offset the stack view vertical center spacing by buttonSize in order to center it on the 5
		verticalStackViewVerticalConstraint.constant = verticalStackViewVerticalConstraintConstant
		
		// modify the button sizes by changing their width and height constraints
		// then make the buttons rounded
		for button in buttons
		{
			for oldConstraint in button.constraints {
				button.removeConstraint(oldConstraint)
			}
			let widthConstraint = NSLayoutConstraint(item: button, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1.0, constant: buttonSize)
			let heightConstraint = NSLayoutConstraint(item: button, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1.0, constant: buttonSize)
			NSLayoutConstraint.activate([heightConstraint, widthConstraint])
			button.layer.cornerRadius = buttonCornerRadius
			button.titleLabel?.font = UIFont.systemFont(ofSize: buttonLabelFontSize)
		}
		
		// generate the circles on top of the numpad to the length of the passcode
		placeholderCircle.removeFromSuperview()
		circles = []
		for _ in 1...passcodeLength
		{
			let circle = UIImageView(image: UIImage(systemName: nPin.emptyCircleImageName))
			circle.frame = CGRect(x: 0.0, y: 0.0, width: circleSize, height: circleSize)
			circle.tintColor = UIColor.label
			circlesStackView.addArrangedSubview(circle)
			let widthConstraint = NSLayoutConstraint(item: circle, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1.0, constant: circleSize)
			let heightConstraint = NSLayoutConstraint(item: circle, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1.0, constant: circleSize)
			NSLayoutConstraint.activate([heightConstraint, widthConstraint])
			circles.append(circle)
		}
		circlesStackView.spacing = circleStackViewSpacing
		circlesStackView.setNeedsDisplay()
		
		let largeConfiguration = UIImage.SymbolConfiguration(pointSize: deleteButtonPointSize, weight: .bold, scale: .large)
		self.deleteButton.setImage(UIImage(systemName: nPin.deleteButtonImageName, withConfiguration: largeConfiguration), for: .normal)
		
		self.setButtonConstraints(button: self.deleteButton, width: buttonSize, height: buttonSize)
		self.setButtonConstraints(button: self.hiddenButton, width: buttonSize, height: buttonSize)
	}
	
	private func setButtonConstraints(button: UIButton, width: CGFloat, height: CGFloat)
	{
		button.removeConstraints(button.constraints)
		
		let widthConstraint = NSLayoutConstraint(item: button, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: width)
		let heightConstraint = NSLayoutConstraint(item: button, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: height)
		NSLayoutConstraint.activate([widthConstraint, heightConstraint])
	}
}
