//
//  Util.swift
//  FFmpegKitSwift
//
//  Created by Mark Khmelnitskii on 30.06.2022.
//

import UIKit

func notNull(_ string: String?, _ valuePrefix: String) -> String {
    guard let string = string else { return "" }
    return String(format:"%@%@", valuePrefix, string)
}

func addUIAction(_ asyncUpdateUIBlock: @escaping () -> Void) {
    DispatchQueue.main.async {
        asyncUpdateUIBlock()
    }
}

class Util: NSObject {
    static func applyButtonStyle(_ button: UIButton) {
        button.tintColor = .white
        button.setTitleColor(.white, for: .normal)
        button.layer.backgroundColor = UIColor(displayP3Red:46.0/256, green:204.0/256, blue:113.0/256, alpha:1.0).cgColor
        button.layer.borderWidth = 1.0
        button.layer.borderColor = UIColor(displayP3Red:39.0/256, green:174.0/256, blue:96.0/256, alpha:1.0).cgColor
        button.layer.cornerRadius = 5.0
    }
    static func applyEditTextStyle(_ textField: UITextField) {
        textField.layer.borderWidth = 1.0
        textField.layer.borderColor = UIColor(displayP3Red:52.0/256, green:152.0/256, blue:219.0/256, alpha:1.0).cgColor
        textField.layer.cornerRadius = 5.0
    }
    static func applyHeaderStyle(_ label: UILabel) {
        label.layer.borderWidth = 1.0
        label.layer.borderColor = UIColor(displayP3Red:231.0/256, green:76.0/256, blue:60.0/256, alpha:1.0).cgColor
        label.layer.cornerRadius = 5.0
    }
    static func applyOutputTextStyle(_ textView: UITextView) {
        textView.layer.backgroundColor = UIColor(displayP3Red:241.0/256, green:196.0/256, blue:15.0/256, alpha:1.0).cgColor
        textView.layer.borderWidth = 1.0
        textView.layer.borderColor = UIColor(displayP3Red:243.0/256, green:156.0/256, blue:18.0/256, alpha:1.0).cgColor
        textView.layer.cornerRadius = 5.0
    }
    static func applyPickerViewStyle(_ pickerView:UIPickerView!) {
        pickerView.layer.backgroundColor = UIColor(displayP3Red:155.0/256, green:89.0/256, blue:182.0/256, alpha:1.0).cgColor
        pickerView.layer.borderWidth = 1.0
        pickerView.layer.borderColor = UIColor(displayP3Red:142.0/256, green:68.0/256, blue:173.0/256, alpha:1.0).cgColor
        pickerView.layer.cornerRadius = 5.0
    }
    static func applyVideoPlayerFrameStyle(_ playerFrame:UILabel!) {
        playerFrame.layer.backgroundColor = UIColor(displayP3Red:236.0/256, green:240.0/256, blue:241.0/256, alpha:1.0).cgColor
        playerFrame.layer.borderWidth = 1.0
        playerFrame.layer.borderColor = UIColor(displayP3Red:185.0/256, green:195.0/256, blue:199.0/256, alpha:1.0).cgColor
        playerFrame.layer.cornerRadius = 5.0
    }
    static func alert(_ controller: UIViewController, withTitle title: String, message: String, andButtonText buttonText: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let defaultAction = UIAlertAction(title: buttonText, style: .default)
        alert.addAction(defaultAction)
        controller.present(alert, animated:true, completion:nil)
    }
}
