//
//  PasscodeViewController.swift
//  nPin
//
//  Created by Hamza Nizameddin on 18/07/2021.
//

import UIKit
import LocalAuthentication
import KeychainSwift

/**
 Login view controller class
 
 - Authors: Hamza Nizameddin
 - Note: View controller to manage logging into the app. On first boot, displays the NewPasscodeViewController to create a new passcode. Subsequently, displays a number pad to enter a 6-digit passcode to access the app. If the BiometricId switch is activated in the settings view controller, also allows access via FaceId or TouchId. Also provides a "Forgot Password" button to reset the app passcode using the device passcode or biometric login.
*/

class LoginViewController: UIViewController
{
	// MARK: - IBOutlets
	
	/**Label displaying "Enter Passcode" above the number pad.*/
	@IBOutlet weak var enterPasscodeLabel: UILabel!
	/**Horizontal StackView containing all the circles that are filled as the user enters the passcode.*/
	@IBOutlet weak var circlesStackView: UIStackView!
	/**A placeholder for a circle UIImageView created in the Storyboard that will be replaced by dynamically generated circle images.*/
	@IBOutlet weak var placeholderCircle: UIImageView!
	/**Array of UIImageViews of the circles that are filled as the user enters the passcode. */
	@IBOutlet var circles: [UIImageView]!
	/**Bottom constraint for circlesStackView to adjust distance to the number pad.*/
	@IBOutlet weak var circlesStackViewBottomConstraint: NSLayoutConstraint!
	/**UIButton in the bottom left of the number pad displaying either a FaceID or TouchID SFSymbol image to allow for biometric login to the app.*/
	@IBOutlet weak var biometricIdButton: UIButton!
	/**UIButton in the bottom right of the number pad used as a backspace.*/
	@IBOutlet weak var deleteButton: UIButton!
	
	/**Vertical UIStackView containing all the buttons of the number pad.*/
	@IBOutlet weak var verticalStackView: UIStackView!
	/**Constraint on verticalStackView to set its vertical center.*/
	@IBOutlet weak var verticalStackViewVerticalConstraint: NSLayoutConstraint!
	/**Array of horizontal UIStackViews containing the rows of buttons of the number pad.*/
	@IBOutlet var horizontalStackViews: [UIStackView]!
	/**Array of UIButtons 0-9 of the number pad*/
	@IBOutlet var buttons: [UIButton]!
	
	// MARK: - Varibales
	/**Point size of the number pad buttons' font. Also used to calculate all the other font sizes and distances between various elements in the View Controller*/
	private var numpadBottomButtonsPointSize: CGFloat = 60.0
	/**UITabBarController that is displayed once the user logs in.*/
	var childTabBarController: UITabBarController?

	/**Passcode string entered so far by the user.**/
	private var passcode: String = ""
	/**Length of the desired passcode string.*/
	private let passcodeSize: Int = nPin.passcodeSize
	
	/**Type of Biometric ID supported by the device.*/
	private var biometryType: LABiometryType = .none
	/**Set to true to automatically lauch biometric identification when the View Controller appears. Set to false so the user needs to press the biometricIdButton to launch biometric identification (used when the user manually logs out of the device).*/
	var loginWithBiometricIdOnViewDidAppear: Bool = true
	
	/**Number of failed login attempts.*/
	private var failedLoginAttempts: Int = 0
	/**Date when the timeout lock expires. If nil, then there is no lockout in effect.*/
	var timeoutExpiryDate: Date?
	/**UIAlertController to display timeout lock message and remaining time.**/
	private var timeoutAlert: UIAlertController?
	/**Timer object used to display remaining time in the timeout lock.**/
	private var timer: Timer?

	/**Shared application-wide DataStack.*/
	private let data = (UIApplication.shared.delegate as! AppDelegate).data
	/**UserDefaults.standard to store all application settings.*/
	private let defaults = UserDefaults.standard
	/**Shared application-wide KeychainPasswordManager object to handle passcode storage and authentication.*/
	private let keychainPassword = (UIApplication.shared.delegate as! AppDelegate).keychainPassword
	/**Shared application-wide IAPManager object to manage in-app purchases.*/
	private let iapManager = (UIApplication.shared.delegate as! AppDelegate).iapManager
	/**Hash method used to stored the passcode in the keychain.*/
	private let passcodeHashType = "sha256"
	
	/**Credit card digits passed into the View Controller when the user searches for a pin code using the device Spotlight Search feature.*/
	var spotlightSearchDigits: String?
	
	// MARK: - Life Cycle
	
	/**
	 Overrides viewDidLoad function. Calls setupFormatting() function to format the number pad according to the size of the device display. Also sets loginWithBiometricIdOnViewDidAppear to true in order to enable automatic biometric login.
	  - Authors: Hamza Nizameddin
	 */
    override func viewDidLoad()
	{
        super.viewDidLoad()
		
		self.setupFormatting()
		self.loginWithBiometricIdOnViewDidAppear = true
		
    }
	
	/**
	 Overrides viewWillAppear function. Calls resetNumpad() to reset the number pad. Calls setupBiometricId() to read the application settings and set up the biometric ID login feature and button on the number pad. Calls setupTimeout() to check if there is a timeout lock in effect and update the class variables accordingly. Calls updateAppIcon() of iapManager in order to change app icon to the premium version if it was purchased.
	  - Authors: Hamza Nizameddin
	 */
	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)
		
		self.resetNumpad()
		self.setupBiometricId()
		self.setupTimeout()
		self.iapManager.updateAppIcon()
	}
	
	/**
	 Overrides viewDidAppear function. Displays timeout lock alert if there is a timeout in effect. Performs automatic biometric ID authentication if loginWithBiometricIdOnViewDidAppear is set to true. If password is not set (i.e. on first launch or after an app reset) presents the new passcode view controller to set the passcode.
	  - Authors: Hamza Nizameddin
	 */
	override func viewDidAppear(_ animated: Bool)
	{
		super.viewDidAppear(animated)
		
		// Show timeout alert UI if timeout is not expired yet
		if let timeoutExpiryDate = self.timeoutExpiryDate {
			if timeoutExpiryDate > Date() {
				showTimeoutAlert()
			}
		} else {
			if self.loginWithBiometricIdOnViewDidAppear {
				loginWithDeviceAuthentication()
			}
		}
		
		// If passcode is not set yet (on first use or after reset) set it now
		if !keychainPassword.passwordExists() {
			perform(#selector(presentNewPasscodeVC), with: nil, afterDelay: 0)
		}
	}
	
	// MARK: - Event Handlers
	/**
	 Event handler for when the user presses any numpad numeric button.
	  - Authors: Hamza Nizameddin
	  - Note: If the passcode is not fully entered, i.e. less than passcodeLength, it will keep adding digits to the passcode variable and filling in circles. If the passcode is fully entered, it will test the entry to see if it matches the stored passcode. If there is a match, it will perform the segue to the Access View Controller. Otherwise, it will add 1 to the failedLoginAttemps counter, test to check if timeout lock is enabled in the settings and if the maximum number of permitted false attempts has been reached, in which case it will setup the timeout lock timer and show the timeout lock alert. Finally, it will shake the circles and reset the number pad.
	 */
	@IBAction func buttonPressed(_ sender: UIButton)
	{
		if(passcode.count < passcodeSize)
		{
			let circle = circles[passcode.count]
			circle.image = UIImage(systemName: nPin.filledCircleImageName)
			circle.setNeedsDisplay()
			passcode += sender.titleLabel!.text!
		}
		
		if(passcode.count >= 6)
		{
			if keychainPassword.testPassword(passcode)
			{
				if keychainPassword.hashType != passcodeHashType {
					keychainPassword.setHashType(newHashTypeString: passcodeHashType, currentPassword: passcode)
				}
				self.failedLoginAttempts = 0
				performSegue(withIdentifier: nPin.passcodeToAccessSegue, sender: self)
			}
			else
			{
				self.failedLoginAttempts += 1
				let timeoutLock = self.defaults.bool(forKey: nPin.timeoutLockKey)
				let maxRetries = self.defaults.integer(forKey: nPin.maxRetriesKey)
				let timeoutLength = self.defaults.integer(forKey: nPin.timeoutLengthKey)
				if timeoutLock == true && self.failedLoginAttempts >= maxRetries {
					self.timeoutExpiryDate = Date() + (Double(timeoutLength) * 60)
					self.defaults.set(self.timeoutExpiryDate, forKey: nPin.timeoutExpiryDateKey)
				}
				DispatchQueue.main.async {
					self.circlesStackView.shake(shakeCount: 5)
					self.resetNumpad()
					if self.timeoutExpiryDate != nil {
						self.showTimeoutAlert()
					}
				}
			}
		}
	}
	
	/**
	 Event handler for the delete (backspace) button.
	  - Authors: Hamza Nizameddin
	  - Note: If there is any entry in the passcode, deletes the last digit entered and empties a circle accordingly.
	 */
	@IBAction func deleteButtonPressed(_ sender: UIButton)
	{
		if self.passcode.count > 0
		{
			self.passcode.removeLast()
			self.circles[self.passcode.count].image = UIImage(systemName: nPin.emptyCircleImageName)
		}
	}
	
	/**
	 Event handler for the biometric ID button.
	  - Authors: Hamza Nizameddin
	 */
	@IBAction func biometricIdButtonPressed(_ sender: UIButton)
	{
		loginWithDeviceAuthentication()
	}
	
	/**
	 Event handler for the forgot passcode button at the bottom of the view controller.
	  - Authors: Hamza Nizameddin
	 */
	@IBAction func forgotPasscodeButtonPressed(_ sender: UIButton)
	{
		forgotPasscode()
	}
	
	// MARK: - New Passcode
	
	/**
	 Presents a new passcode view controller.
	  - Authors: Hamza Nizameddin
	  - Note: Presents a NewPasscodeViewController without asking for the current passcode. Used, on first run, after app reset and in case passcode is forgotten.
	 */
	@objc private func presentNewPasscodeVC()
	{
		let storyboard = UIStoryboard(name: nPin.mainStoryboardName, bundle: nil)
		let newPasscodeVC = storyboard.instantiateViewController(withIdentifier: nPin.newPasscodeViewControllerId) as! NewPasscodeViewController
		newPasscodeVC.isResetPasscode = true
		present(newPasscodeVC, animated: true)
	}
	
	// MARK: - Timeout
	
	/**
	 Sets up the timeout lock funcitonality in case several wrong passcodes attempts are made and the option is set in the settings.
	  - Authors: Hamza Nizameddin
	  - Note: This function first reads the value stored in User Defaults for timeoutExpiryDateKey to see if there is a timeout in effect and get the date time when it expires. If the timeout has expired, it will delete the value from User Defaults in order to allow for the user to attempt to log into the app again. If the timeout still hasn't expired, this will set the class variable timeoutExpiryDate to block any attempt to log into the app until the timeout expires.
	 */
	public func setupTimeout()
	{
		// check if there is a timeout in effect and set/unset self.timeoutExpiryDate
		if let timeoutExpiryDate = (self.defaults.object(forKey: nPin.timeoutExpiryDateKey) as? Date) {
			if timeoutExpiryDate <= Date() { //timeout already expired
				self.timeoutExpiryDate = nil
				self.defaults.removeObject(forKey: nPin.timeoutExpiryDateKey)
			} else { // timeout is still in effect
				self.timeoutExpiryDate = timeoutExpiryDate
			}
		} else { // no timeout date stored in iCloud keystore
			self.timeoutExpiryDate = nil
		}
	}
	
	/**
	 Displays the alert box with the remaining timeout countdown.
	  - Authors: Hamza Nizameddin
	  - Note: First checks if class variable timeoutExpiryDate is set, indicating there is a timeout lock in effect that hasn't expired yet. Displays an information alert box with a countdown timer. Sets the timer class variable to call the dismissTimeoutAlert() function to update the remaining time shown in the message or dismiss the alert box if the timeout has expired. All display strings are localized.
	 */
	public func showTimeoutAlert()
	{
		DispatchQueue.main.async
		{
			if let timeoutExpiryDate = self.timeoutExpiryDate,
			   timeoutExpiryDate > Date()
			{
				self.timeoutAlert = UIAlertController(title: NSLocalizedString("Passcode entry locked due to excessive failed attempts", comment: "Text indicating app was locked after too many failed attempts"), message: NSLocalizedString("Time remaining: ", comment: "Text to indicate time remaining until app can be used again") + self.getRemainingTime(until: self.timeoutExpiryDate!), preferredStyle: .alert)
				self.present(self.timeoutAlert!, animated: true)
				self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.dismissTimeoutAlert), userInfo: nil, repeats: true)
			}
		}
		
	}
	
	/**
	 Dismiss the timeout countdown alert box.
	 - Authors: Hamza Nizameddin
	 - Note: Function called by the timer set in showTimeoutAlert() First checks if class variable timeoutExpiryDate is set, indicating there is a timeout lock in effect. Updates the countdown timer in the timeout alert box and dismisses the alert text box when the timeout has expired.
	 */
	@objc private func dismissTimeoutAlert()
	{
		if let timeoutExpiryDate = self.timeoutExpiryDate {
			self.timeoutAlert?.message = "Time remaining: " + self.getRemainingTime(until: self.timeoutExpiryDate!)
			if timeoutExpiryDate <= Date() {
				timer?.invalidate()
				self.timeoutAlert?.dismiss(animated: true, completion: {
					self.defaults.removeObject(forKey: nPin.timeoutExpiryDateKey)
					self.timeoutExpiryDate = nil
				})
			}
		}
	}
	
	/**
	 Get a formatted string representing the time remaining until a certain date.
	  - Authors: Hamza Nizameddin
	  - Parameter until: The future date time.
	  - Returns: A formatted string representing the time remaining from now till the "until" parameter
	  - Note: The format of the returned string is hh:mm:ss
	 */
	func getRemainingTime(until endDate: Date) -> String
	{
		let remainingTime: Date = endDate - Date().timeIntervalSince1970
		let remainingMinutes = String(format: "%02d", Calendar.current.component(.minute, from: remainingTime))
		let remainingSeconds = String(format: "%02d", Calendar.current.component(.second, from: remainingTime))
		
		return remainingMinutes + ":" + remainingSeconds
	}
	
	// MARK: - Numpad reset
	
	/**
	 Resets the number pad for a new entry.
	  - Authors: Hamza Nizameddin
	 */
	func resetNumpad()
	{
		passcode = ""
		for circle in circles {
			circle.image = UIImage(systemName: nPin.emptyCircleImageName)
		}
	}
	
	// MARK: - Biometric ID
	
	/**
	 Set up BiometricID.
	 - Authors: Hamza Nizameddin
	 - Note: First obtains the Biometric ID capabilities of the device to deteremine whether Face ID, Touch ID or neither is available and sets the class variable biometryType accordingly. Also checks if Biometric ID is enabled in settins by reading the User Defaults value for the key nPin.biometricIdKey. Once it determines which type (if any) of Biometric ID is enabled, formats and displays the proper symbol in the lower left corner of the number pad for the user to press and login with biometrics.
	 */
	private func setupBiometricId()
	{
		// detect whether device has FaceID or TouchID or neither
		let context = LAContext()
		self.biometryType = .none
		let largeConfig = UIImage.SymbolConfiguration(pointSize: self.numpadBottomButtonsPointSize, weight: .regular, scale: .unspecified)
		if(context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) && self.defaults.bool(forKey: nPin.biometricIdKey))
		{
			biometryType = context.biometryType
			biometricIdButton.isEnabled = true
			biometricIdButton.tintColor = UIColor.label
		}
		switch self.biometryType
		{
			case .faceID:
				biometricIdButton.setImage(UIImage(systemName: nPin.faceIdImageName, withConfiguration: largeConfig), for: .normal)
			case .touchID:
				biometricIdButton.setImage(UIImage(systemName: nPin.touchIdImageName, withConfiguration: largeConfig), for: .normal)
			default:
				biometricIdButton.isEnabled = false
				biometricIdButton.tintColor = UIColor.clear
		}
	}
	
	/**
	 Log in using device authentication (device passcode or biometric ID).
	  - Authors: Hamza Nizameddin
	  - Parameter policy: LAPolicy whether to log in with only biometrics or biometrics and device passcode. Defaults to .deviceOwnerAuthenticationWithBiometrics.
	 */
	private func loginWithDeviceAuthentication(_ policy: LAPolicy = .deviceOwnerAuthenticationWithBiometrics)
	{
		var reason = ""
		if biometryType == .faceID {
			reason = "Login with FaceID"
		} else if biometryType == .touchID {
			reason = "Login with TouchID"
		} else {
			return
		}
		
		let context = LAContext()
		context.evaluatePolicy(policy, localizedReason: reason)
		{  success, error in
			DispatchQueue.main.async
			{
				guard success, error == nil else {
					print(error!.localizedDescription)
					return
				}
				for circle in self.circles {
					circle.image = UIImage(systemName: nPin.filledCircleImageName)
				}
				self.performSegue(withIdentifier: nPin.passcodeToAccessSegue, sender: self)
			}
		}
		
	}
	
	// MARK: - View Formatting
	
	/**
	 Sets up the formatting of the View Controller based on the size of the display.
	  - Authors: Hamza Nizameddin
	 */
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
		self.numpadBottomButtonsPointSize = buttonSize * 0.35
		
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
		for _ in 1...passcodeSize
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
		
		let largeConfiguration = UIImage.SymbolConfiguration(pointSize: self.numpadBottomButtonsPointSize, weight: .bold, scale: .large)
		self.deleteButton.setImage(UIImage(systemName: nPin.deleteButtonImageName, withConfiguration: largeConfiguration), for: .normal)
		
		self.setButtonConstraints(button: self.deleteButton, width: buttonSize, height: buttonSize)
		self.setButtonConstraints(button: self.biometricIdButton, width: buttonSize, height: buttonSize)
	}
	
	/**
	 Set constraints for UIButton for width and height.
	  - Authors: Hamza Nizameddin
	  - Parameters:
	   - button: UIButton to set constraints for.
	   - width: Width of the button.
	   - height: Height of the button.
	 */
	private func setButtonConstraints(button: UIButton, width: CGFloat, height: CGFloat)
	{
		button.removeConstraints(button.constraints)
		
		let widthConstraint = NSLayoutConstraint(item: button, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: width)
		let heightConstraint = NSLayoutConstraint(item: button, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: height)
		NSLayoutConstraint.activate([widthConstraint, heightConstraint])
	}
	

    
    // MARK: - Navigation
	/**
	 Overrides prepare function. Sets loginWithBiometricIdOnViewDidAppear to false. If the destination is the UITabBarController, checks if a string of digits was passed down from the device Spotlight search and sends them to the Access View Controller.
	  - Authors: Hamza Nizameddin
	 */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
	{
		self.loginWithBiometricIdOnViewDidAppear = false
		if let tabBarController = segue.destination as? UITabBarController
		{
			self.childTabBarController = tabBarController
			if let spotlightSearchDigits = spotlightSearchDigits {
				for child in tabBarController.children {
					if let accessNavigationController = child as? UINavigationController {
						if let accessViewController = accessNavigationController.topViewController as? AccessViewController {
							accessViewController.spotlightSearchDigits = spotlightSearchDigits
							self.spotlightSearchDigits = nil
							return
						}
					}
				}
			}
		}
    }
	
	// MARK: - Forgot Passcode
	
	/**
	 Allows user to authenticate using device passcode or biometrics in order to reset app passcode
	 - Authors: Hamza Nizameddin
	 */
	private func forgotPasscode()
	{
		let forgotPasscodeAlert = UIAlertController(title: NSLocalizedString("Forgot Passcode", comment: "Forgot passcode alert box title"), message: NSLocalizedString("Do you wish to reset app passcode or reset all data?", comment: "Forgot passcode alert box message"), preferredStyle: .alert)
		
		let forgotPasscodeCancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel button label"), style: .cancel, handler: nil)
		
		let forgotPasscodeResetPasscodeAction = UIAlertAction(title: NSLocalizedString("Reset Passcode", comment: "Reset Passcode button label"), style: .default) { [weak self] action in
			guard let self = self else {return}
			
			let reason = NSLocalizedString("Authenticate to Reset Passcode", comment: "Authentication reason to reset app")
			let context = LAContext()
			context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, error in
				DispatchQueue.main.async {
					self.presentNewPasscodeVC()
				}
			}
			
		}
		
//		let forgotPasscodeResetAppAction = UIAlertAction(title: NSLocalizedString("Reset App", comment: "Reset App button label"), style: .destructive) { [weak self] action in
//			guard let self = self else {return}
//			
//			let reason = NSLocalizedString("Authenticate to Reset App", comment: "Authentication reason")
//			
//			let context = LAContext()
//			
//			context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
//			{  success, error in
//				guard success, error == nil else {return}
//				DispatchQueue.main.async
//				{
//					let confirmAlert = UIAlertController(title: NSLocalizedString("Confirm", comment: "Confirm button label"), message: NSLocalizedString("Please type RESET in the box below to confirm App data reset", comment: "Text explaining how to confirm the reset procedure"), preferredStyle: .alert)
//					var confirmTextField = UITextField()
//					confirmAlert.addTextField { textField in
//						confirmTextField = textField
//						confirmTextField.placeholder = "RESET"
//					}
//					let confirmCancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel button label"), style: .cancel, handler: nil)
//					let confirmResetAction = UIAlertAction(title: NSLocalizedString("Reset", comment: "Reset button label"), style: .destructive) { [weak self] action in
//						guard let self = self else {return}
//						if confirmTextField.text == "RESET"
//						{
//							for key in nPin.settingsKeyList {
//								self.defaults.removeObject(forKey: key)
//							}
//							self.defaults.removeObject(forKey: nPin.timeoutExpiryDateKey)
//							self.keychainPassword.clear()
//							self.data.reset()
//							self.keychainPassword.deactivateSync(deleteCloudData: false)
//							self.data.iCloudSync = false
//							self.iapManager.resetKeystore()
//							self.presentNewPasscodeVC()
//						}
//					}
//					
//					confirmAlert.addAction(confirmResetAction)
//					confirmAlert.addAction(confirmCancelAction)
//					
//					self.present(confirmAlert, animated: true, completion: nil)
//				}
//			}
//		}
		
		forgotPasscodeAlert.addAction(forgotPasscodeCancelAction)
		forgotPasscodeAlert.addAction(forgotPasscodeResetPasscodeAction)
		//forgotPasscodeAlert.addAction(forgotPasscodeResetAppAction)
		
		DispatchQueue.main.async {
			self.present(forgotPasscodeAlert, animated: true, completion: nil)
		}
	}
    

}
