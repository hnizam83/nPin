//
//  ShowPinViewController.swift
//  nPin
//
//  Created by Hamza Nizameddin on 19/07/2021.
//

import UIKit

/**
View controller class to display pin codes.
 
 - Author: Hamza Nizameddin
 - Note: View controller to display pin codes. If fake pin is enabled in settings and the user inputs an incorrect last digit, the fake pin will be displayed instead. If random pins is enabled in settings then random pins will be generated and displayed with the real pin. If reverse pin is enabled in settings then the pin will be displayed in reverse order.
*/
class DisplayViewContoller: UIViewController
{
	/**Vertical UIStackView containing all the labels displaying the real and random PIN codes.*/
	@IBOutlet weak var labelsStackView: UIStackView!
	/**Array of UILabels displaying the real and random PIN codes.*/
	@IBOutlet var labels: [UILabel]!
	
	/**PIN code to be displayed. Passed from the calling view controller.*/
	public var pinCode: String = ""
	/**If true, display PIN code in reverse.*/
	public var reverse: Bool = false
	/**If true, display 4 random PIN codes with the real one*/
	public var randomPins: Bool = false
	/**Array of real and random PIN codes to be displayed.**/
	public var displayPinCodes: [String] = []
	
	/**UserDefaults.standard to store all application settings.*/
	private let defaults = UserDefaults.standard
	
	// MARK: - View Controller Life Cycle
	/**
	 Overrides viewDidLoad function.
	  - Authors: Hamza Nizameddin
	  - Note: Retrieves the PIN display security, reverse PIN code and random PIN codes settings. Displays the PIN code(s) and formats them according to the size of the device display.
	 */
	override func viewDidLoad()
	{
        super.viewDidLoad()
		
		let pinDisplaySecurity = self.defaults.bool(forKey: nPin.pinDisplaySecurityKey)
		let reversePin = self.defaults.bool(forKey: nPin.reversePinKey)
		let randomPin = self.defaults.bool(forKey: nPin.randomPinKey)
		
		if((pinDisplaySecurity && reversePin) == true) {
			self.pinCode = String(self.pinCode.reversed())
		}
		
		self.displayPinCodes.append(pinCode)
		
		if((pinDisplaySecurity && randomPin) == true)
		{
			
			for _ in 1...(self.labels.count - 1) {
				self.displayPinCodes.append(Card.generateRandomPin(4))
			}
			self.displayPinCodes.shuffle()
			let maxWidth = self.view.frame.width - 100
			for i in 0..<self.labels.count
			{
				let label = self.labels[i]
				label.isHidden = false
				let widthConstraint = NSLayoutConstraint(item: label, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1.0, constant: CGFloat.random(in: label.frame.width...maxWidth))
				NSLayoutConstraint.activate([widthConstraint])
				label.text = self.displayPinCodes[i]
			}
			
			
		}
		else
		{
			for i in 1..<self.labels.count {
				self.labels[i].isHidden = true
			}
			self.labels[0].text = pinCode
			self.labelsStackView.alignment = .center
		}
		
    }
	
	/**
	 Overrides viewDidDisappear function.
	  - Authors: Hamza Nizameddin
	 */
	override func viewDidDisappear(_ animated: Bool)
	{
		super.viewDidDisappear(true)
		self.navigationController?.popViewController(animated: true)
	}
}
