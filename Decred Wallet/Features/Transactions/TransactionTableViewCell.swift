//
//  TransactionTableViewCell.swift
//  Decred Wallet
//
// Copyright (c) 2018-2020 The Decred developers
// Use of this source code is governed by an ISC
// license that can be found in the LICENSE file.

import UIKit
import Dcrlibwallet

class TransactionTableViewCell: UITableViewCell {
    @IBOutlet weak var txTypeIconImageView: UIImageView!
    @IBOutlet weak var txAmountOrTicketStatusLabel: UILabel! // holds amount for regular txs and ticket status for staking txs
    @IBOutlet weak var stakingTxAmountLabel: UILabel! // staking txs only, holds amount for different ticket states
    @IBOutlet weak var voteRewardLabel: Label! // vote tx only
    @IBOutlet weak var voteRewardLabelPadding: UILabel!
    @IBOutlet weak var txDateLabel: UILabel!
    @IBOutlet weak var daysCounterLabel: UILabel! // voted, revoked and expired tickets only
    @IBOutlet weak var txStatusIconImageView: UIImageView!
    @IBOutlet weak var walletNameLabel: Label!
    
    override class func height() -> CGFloat {
        return 56
    }

    func displayInfo(for transaction: Transaction, hideWalletLabel: Bool = true) {
        let txConfirmations = transaction.confirmations
        let isConfirmed = Settings.spendUnconfirmed || txConfirmations > 1

        let txDate = Date(timeIntervalSince1970: TimeInterval(transaction.timestamp))
        let ageInDays = txDate.daysFromNow
        var txDateString: String

        if ageInDays == 0 {
            txDateString = LocalizedStrings.today
        } else if ageInDays == -1 {
            txDateString = LocalizedStrings.yesterday
        } else {
            let txDateIsInCurrentYear = Calendar.current.isDate(txDate, equalTo: Date(), toGranularity: .year)
            txDateString = txDate.toString(format: txDateIsInCurrentYear ? "MMM dd" : "MMM dd, YYYY")
        }

        self.txDateLabel.text = isConfirmed ? txDateString : LocalizedStrings.pending
        self.txDateLabel.textColor = isConfirmed ? UIColor.appColors.text4 : UIColor.appColors.text3
        self.txStatusIconImageView.image = isConfirmed ? UIImage(named: "ic_confirmed") : UIImage(named: "ic_pending")

        self.stakingTxAmountLabel.isHidden = transaction.type == DcrlibwalletTxTypeRegular
        self.daysCounterLabel.isHidden = !(transaction.type == DcrlibwalletTxTypeVote || transaction.type == DcrlibwalletTxTypeRevocation)
        self.voteRewardLabel.isHidden = !(transaction.type == DcrlibwalletTxTypeVote || transaction.type == DcrlibwalletTxTypeRevocation)
        
        self.walletNameLabel.isHidden = hideWalletLabel
        
        let wallet = WalletLoader.shared.multiWallet.wallet(withID: transaction.walletID)!
        if !hideWalletLabel {
            self.walletNameLabel.text = wallet.name
        }

        if transaction.type == DcrlibwalletTxTypeRegular {
            self.displayRegularTxInfo(transaction)
        } else if transaction.type == DcrlibwalletTxTypeMixed {
            self.displayMixedTxInfo(transaction)
        } else if transaction.type == DcrlibwalletTxTypeVote {
            self.displayVoteTxInfo(transaction, ageInDays: transaction.daysToVoteOrRevoke)
            
        } else if transaction.type == DcrlibwalletTxTypeRevocation {
            self.displayRevocationTxInfo(transaction, ageInDays: transaction.daysToVoteOrRevoke)
            
        } else if transaction.type == DcrlibwalletTxTypeTicketPurchase {
            self.displayTicketPurchaseInfo(transaction, wallet: wallet)
        }
    }
    
    func displayRegularTxInfo(_ transaction: Transaction) {
        let amountString = Utils.amountShowedInEightDecimals(amount: DcrlibwalletAmountCoin(transaction.amount), smallerTextSize: 13.0, textColor: UIColor.appColors.text1)
        if transaction.direction == DcrlibwalletTxDirectionSent {
            let attributedString = NSMutableAttributedString(string:"-")
            attributedString.append(amountString)
            self.txAmountOrTicketStatusLabel.attributedText = attributedString
            self.txTypeIconImageView?.image = UIImage(named: "ic_send")
        } else if transaction.direction == DcrlibwalletTxDirectionReceived {
            self.txAmountOrTicketStatusLabel.attributedText = amountString
            self.txTypeIconImageView?.image = UIImage(named: "ic_receive")
        } else if transaction.direction == DcrlibwalletTxDirectionTransferred {
            self.txAmountOrTicketStatusLabel.attributedText = amountString
            self.txTypeIconImageView?.image = UIImage(named: "ic_fee")
        }

    }
    
    func displayMixedTxInfo(_ transaction: Transaction) {
        self.txTypeIconImageView?.image = UIImage(named: "mixed_tx")
        self.txAmountOrTicketStatusLabel.attributedText = NSMutableAttributedString(string: LocalizedStrings.mixed)
        
        let mixAmount = Utils.amountShowedInEightDecimals(amount: DcrlibwalletAmountCoin(transaction.mixDenom), smallerTextSize: 11.0, textColor: UIColor.appColors.text1)
        if transaction.mixCount > 1 {
            let mixCount = NSMutableAttributedString(string: "\t x\(transaction.mixCount)")
            mixAmount.append(mixCount)
        }
        self.stakingTxAmountLabel.attributedText = mixAmount
    }
    
    func displayVoteTxInfo(_ transaction: Transaction, ageInDays: Int) {
        self.txAmountOrTicketStatusLabel.text = "\(LocalizedStrings.voted)"
        self.txTypeIconImageView?.image = UIImage(named: "ic_ticketVoted")

        self.stakingTxAmountLabel.attributedText = Utils.amountShowedInEightDecimals(amount: DcrlibwalletAmountCoin(transaction.amount), smallerTextSize: 11.0, textColor: UIColor.appColors.text3)
        self.voteRewardLabel.attributedText = Utils.getAttributedString(str: transaction.dcrVoteReward.round(8).description, siz: 11.0, TexthexColor: UIColor.white)
        self.daysCounterLabel.text = String(format: (ageInDays > 1 ? LocalizedStrings.days : LocalizedStrings.day), ageInDays)
    }
    
    func displayRevocationTxInfo(_ transaction: Transaction, ageInDays: Int) {
        self.txAmountOrTicketStatusLabel.text = "\(LocalizedStrings.revoked)"
        self.txTypeIconImageView?.image = UIImage(named: "ic_ticketRevoked")

        self.stakingTxAmountLabel.attributedText = Utils.amountShowedInEightDecimals(amount: DcrlibwalletAmountCoin(transaction.amount), smallerTextSize: 11.0, textColor: UIColor.appColors.text3)
        self.voteRewardLabel.attributedText = Utils.getAttributedString(str: transaction.dcrVoteReward.round(8).description, siz: 11.0, TexthexColor: UIColor.white)
        
        self.daysCounterLabel.text = String(format: (ageInDays > 1 ? LocalizedStrings.days : LocalizedStrings.day), ageInDays)
    }
    
    func displayTicketPurchaseInfo(_ transaction: Transaction, wallet: DcrlibwalletWallet) {
        self.txAmountOrTicketStatusLabel.text = "\(LocalizedStrings.ticket)"
        self.txTypeIconImageView?.image = UIImage(named: "ic_ticketImmature")
        self.stakingTxAmountLabel.attributedText = Utils.amountShowedInEightDecimals(amount: DcrlibwalletAmountCoin(transaction.amount), smallerTextSize: 11.0, textColor: UIColor.appColors.text3)

        let requireConfirmation = Settings.spendUnconfirmed ? 0 : 2
        let txConfirmations = transaction.confirmations

        if txConfirmations < requireConfirmation {
            self.txDateLabel.textColor = UIColor.appColors.text3
            self.txDateLabel.text = LocalizedStrings.pending
        } else if txConfirmations > BuildConfig.TicketMaturity {
            var errorValue: ObjCBool = false
            do {
                try wallet.ticketHasVotedOrRevoked(transaction.hash, ret0_: &errorValue)
                if errorValue.boolValue {
                    self.txAmountOrTicketStatusLabel.text = LocalizedStrings.purchased
                } else {
                    self.txAmountOrTicketStatusLabel.text = LocalizedStrings.live
                }
            } catch {
                Utils.showBanner(in: self, type: .error, text: error.localizedDescription)
            }
            
            self.txTypeIconImageView?.image = UIImage(named: "ic_ticketLive")
        } else {
            self.txAmountOrTicketStatusLabel.text = LocalizedStrings.immature
            self.txTypeIconImageView?.image = UIImage(named: "ic_ticketImmature")
        }
    }
}
