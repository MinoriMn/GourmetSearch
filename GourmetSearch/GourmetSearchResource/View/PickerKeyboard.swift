import UIKit
import Combine

// 参考: https://github.com/RyoHirota68/PickerKeyboard/blob/master/PickerKeyboard/PickerKeyboard.swift
class PickerKeyboard: UIControl {

    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func draw(_ rect: CGRect) {
     // Drawing code
     }
     */


    let list: [String]
    let selectedRow: PassthroughSubject<Int, Never>

    init?(coder aDecoder: NSCoder, list: [String], selected: PassthroughSubject<Int, Never>) {
        self.list = list
        self.selectedRow = selected
        super.init(coder: aDecoder)

        addTarget(self, action: #selector(tappedPickerKeyboard(_:)), for: .touchDown)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func tappedPickerKeyboard(_ sender: PickerKeyboard) {
        becomeFirstResponder()
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    override var inputAccessoryView: UIView? {

        let view = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))
        view.frame = CGRect(x: 0, y: 0, width: frame.width, height: 44)

        let closeButton = UIButton(type: .custom)
        closeButton.setTitle("閉じる", for: .normal)
        closeButton.sizeToFit()
        closeButton.addTarget(self, action: #selector(tappedCloseButton(_:)), for: .touchUpInside)
        closeButton.setTitleColor(UIColor(red: 0, green: 122/255, blue: 1, alpha: 1.0), for: .normal)

        view.contentView.addSubview(closeButton)

        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.widthAnchor.constraint(equalToConstant: closeButton.frame.size.width).isActive = true
        closeButton.heightAnchor.constraint(equalToConstant: closeButton.frame.size.height).isActive = true
        closeButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 5).isActive = true
        closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16).isActive = true

        return view
    }

    override var inputView: UIView? {

        let pickerView: UIPickerView = UIPickerView()
        pickerView.delegate = self
        pickerView.dataSource = self
        pickerView.autoresizingMask = [.flexibleHeight]

        // SafeAreaに対応させる為にUIViewを挟む
        let view = UIView()
        view.autoresizingMask = [.flexibleHeight]
        view.addSubview(pickerView)

        pickerView.translatesAutoresizingMaskIntoConstraints = false
        pickerView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        pickerView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        pickerView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor).isActive = true

        return view
    }

    @objc private func tappedCloseButton(_ sender: UIButton) {
        resignFirstResponder()
    }
}

extension PickerKeyboard: UIPickerViewDelegate, UIPickerViewDataSource {

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return list.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return list[row]
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedRow.send(row)
    }
}
