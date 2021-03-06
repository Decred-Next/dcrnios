//
//  NavMenuFloatingButtons.swift
//  Decred Wallet
//
// Copyright (c) 2019-2020 The Decred developers
// Use of this source code is governed by an ISC
// license that can be found in the LICENSE file.

import UIKit

class NavMenuFloatingButtons: UIView {
    
    let sendButton = UIButton(type: .custom)
    let receiveButton = UIButton(type: .custom)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)
        self.layer.backgroundColor = UIColor.appColors.primary.cgColor
        self.layer.cornerRadius = 24
        
        self.createButtons()
    }
    
    private func createButtons() {
        self.sendButton.setImage(UIImage(named: "ic_send"), for: .normal)
        self.sendButton.setTitle(LocalizedStrings.send.localizedCapitalized, for: .normal)
        self.sendButton.set(fontSize: 17, name: "Source Sans Pro")
        self.sendButton.imageEdgeInsets = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 24)
        self.sendButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
        self.sendButton.translatesAutoresizingMaskIntoConstraints = false
        self.sendButton.clipsToBounds = true
        self.sendButton.setTitleColor(UIColor.appColors.text, for: .normal)
        self.sendButton.addTarget(self, action: #selector(self.sendTapped), for: .touchUpInside)

        self.receiveButton.setImage(UIImage(named: "ic_receive"), for: .normal)
        self.receiveButton.setTitle(LocalizedStrings.receive.localizedCapitalized, for: .normal)
        self.receiveButton.set(fontSize: 17, name: "Source Sans Pro")
        self.receiveButton.setTitleColor(UIColor.appColors.text, for: .normal)
        self.receiveButton.imageEdgeInsets = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 22)
        self.receiveButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
        self.receiveButton.translatesAutoresizingMaskIntoConstraints = false
        self.receiveButton.clipsToBounds = true
        self.receiveButton.addTarget(self, action: #selector(self.receiveTapped), for: .touchUpInside)
        
        let separator = UIView(frame: CGRect.zero)
        separator.layer.backgroundColor = UIColor(displayP3Red: 1, green: 1, blue: 1, alpha: 0.7).cgColor
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.clipsToBounds = true
        self.backgroundColor = UIColor.appColors.primary
        
        self.addSubview(self.sendButton)
        self.addSubview(self.receiveButton)
        self.addSubview(separator)
        
        let constraints = [           
            self.sendButton.heightAnchor.constraint(equalTo: self.heightAnchor),
            self.sendButton.widthAnchor.constraint(equalToConstant: 120),
            self.sendButton.topAnchor.constraint(equalTo: self.topAnchor),
            self.sendButton.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 5),
            
            self.receiveButton.heightAnchor.constraint(equalTo: self.heightAnchor),
            self.receiveButton.widthAnchor.constraint(equalToConstant: 120),
            self.receiveButton.topAnchor.constraint(equalTo: self.topAnchor),
            self.receiveButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -5),
            
            separator.heightAnchor.constraint(equalToConstant: 24), // Height of 24pts from mockup
            separator.widthAnchor.constraint(equalToConstant: 1),
            separator.topAnchor.constraint(equalTo: self.topAnchor, constant: 12), // Position separator 12pts below floating buttons topAnchor
            separator.centerXAnchor.constraint(equalTo: self.centerXAnchor),
        ]
        NSLayoutConstraint.activate(constraints)
        self.layoutIfNeeded()
        
    }
    
    @objc func sendTapped(_ sender: UIButton) {
        var errorValue: ObjCBool = false
        
       do {
            try WalletLoader.shared.multiWallet.allWalletsAreWatchOnly(&errorValue)
            if errorValue.boolValue {
                if let navigationTabController = NavigationMenuTabBarController.instance?.view {
                    Utils.showBanner(in: navigationTabController, type: .error, text: "Only wallet is watching only")
                }
                return
            }
        } catch {
            if let navigationTabController = NavigationMenuTabBarController.instance?.view {
                Utils.showBanner(in: navigationTabController, type: .error, text: error.localizedDescription)
                return
            }
        }
        
        if WalletLoader.shared.multiWallet.isSyncing() {
            if let navigationTabController = NavigationMenuTabBarController.instance?.view {
                Utils.showBanner(in: navigationTabController, type: .error, text: LocalizedStrings.waitForSync)
            }
            return
        } else if !WalletLoader.shared.multiWallet.isConnectedToDecredNetwork() {
            if let navigationTabController = NavigationMenuTabBarController.instance?.view {
                Utils.showBanner(in: navigationTabController, type: .error, text: LocalizedStrings.notConnected)
            }
            return
        }
        
        DispatchQueue.main.async {
            let sendVC = SendViewController.instance
            sendVC.modalPresentationStyle = .overFullScreen
            self.window?.rootViewController?.present(sendVC, animated: true)
        }
    }
    
    @objc func receiveTapped(_ sender: UIButton) {
        if WalletLoader.shared.multiWallet.isSyncing() {
            if let navigationTabController = NavigationMenuTabBarController.instance?.view {
                Utils.showBanner(in: navigationTabController, type: .error, text: LocalizedStrings.waitForSync)
            }
            return
        } else if !WalletLoader.shared.multiWallet.isConnectedToDecredNetwork() {
            if let navigationTabController = NavigationMenuTabBarController.instance?.view {
                Utils.showBanner(in: navigationTabController, type: .error, text: LocalizedStrings.notConnected)
            }
            return
        }
        
        DispatchQueue.main.async {
            let receiveVC = ReceiveViewController.instantiate(from: .Receive)
            receiveVC.modalPresentationStyle = .overFullScreen
            self.window?.rootViewController?.present(receiveVC, animated: true)
        }
    }
}
