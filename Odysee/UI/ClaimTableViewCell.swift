//
//  FileTableViewCell.swift
//  Odysee
//
//  Created by Akinwale Ariwodola on 08/11/2020.
//

import UIKit

class ClaimTableViewCell: UITableViewCell {

    static let nib = UINib(nibName: "ClaimTableViewCell", bundle: nil)
    static let spacemanImage = UIImage(named: "spaceman")

    @IBOutlet var channelImageView: UIImageView!
    @IBOutlet var thumbnailImageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var publisherLabel: UILabel!
    @IBOutlet var publishTimeLabel: UILabel!
    @IBOutlet var durationView: UIView!
    @IBOutlet var durationLabel: UILabel!
    
    var currentClaim: Claim?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let publisherTapGesture = UITapGestureRecognizer(target: self, action: #selector(self.publisherTapped(_:)))
        publisherLabel.addGestureRecognizer(publisherTapGesture)
        channelImageView.rounded()
        channelImageView.backgroundColor = Helper.lightPrimaryColor
        thumbnailImageView.backgroundColor = Helper.lightPrimaryColor
    }
    
    static func imagePrefetchURLs(claim: Claim) -> [URL] {
        if claim.claimId == "placeholder" || claim.claimId == "new" {
            return []
        }
        
        var result = [URL]()
        if let thumbnailUrl = claim.value?.thumbnail?.url.flatMap(URL.init) {
            result.append(thumbnailUrl)
        }
        return result
    }
    
    func setClaim(claim: Claim) {
        if (currentClaim != nil && claim.claimId != currentClaim!.claimId) {
            // reset the thumbnail image (to prevent the user from seeing image load changes when scrolling due to cell reuse)
            thumbnailImageView.image = nil
            thumbnailImageView.backgroundColor = nil
            channelImageView.image = nil
            channelImageView.backgroundColor = nil
        }
        
        thumbnailImageView.backgroundColor = claim.claimId == "placeholder" ? UIColor.systemGray5 : UIColor.clear
        titleLabel.backgroundColor = claim.claimId == "placeholder" ? UIColor.systemGray5 : UIColor.clear
        publisherLabel.backgroundColor = claim.claimId == "placeholder" ? UIColor.systemGray5 : UIColor.clear
        publishTimeLabel.backgroundColor = claim.claimId == "placeholder" ? UIColor.systemGray5 : UIColor.clear
        durationView.isHidden = claim.claimId == "placeholder" || claim.claimId == "new"
        
        if claim.claimId == "placeholder" {
            titleLabel.text = nil
            publisherLabel.text = nil
            publishTimeLabel.text = nil
            return
        }
        
        if claim.claimId == "new" {
            titleLabel.text = String.localized("New Upload")
            publisherLabel.text = nil
            publishTimeLabel.text = nil
            thumbnailImageView.image = Self.spacemanImage
            return
        }
        
        currentClaim = claim
        
        let isChannel = claim.name!.starts(with: "@")
        channelImageView.isHidden = !isChannel
        thumbnailImageView.isHidden = isChannel
        
        titleLabel.text = isChannel ? claim.name : claim.value?.title
        publisherLabel.text = isChannel ? claim.name : claim.signingChannel?.name
        if claim.value?.source == nil  && !isChannel {
            publisherLabel.text = "LIVE"
        }
        // load thumbnail url
        if let thumbnailUrl = claim.value?.thumbnail?.url.flatMap(URL.init) {
            if isChannel {
                channelImageView.load(url: thumbnailUrl)
            } else {
                thumbnailImageView.load(url: thumbnailUrl)
            }
        } else {
            if isChannel {
                thumbnailImageView.image = Self.spacemanImage
                thumbnailImageView.backgroundColor = Helper.lightPrimaryColor
            } else {
                channelImageView.image = Self.spacemanImage
                channelImageView.backgroundColor = Helper.lightPrimaryColor
            }
        }
        
        var releaseTime: Double = Double(claim.value?.releaseTime ?? ("0"))!
        if (releaseTime == 0) {
            releaseTime = Double(claim.timestamp ?? 0)
        }
        if releaseTime > 0 {
            let date = Date(timeIntervalSince1970: releaseTime) // TODO: Timezone check / conversion?
            publishTimeLabel.text = Helper.fullRelativeDateFormatter.localizedString(for: date, relativeTo: Date())
        } else {
            publishTimeLabel.text = String.localized("Pending")
        }
        
        var duration: Int64 = 0
        if (claim.value?.video != nil || claim.value?.audio != nil) {
            let streamInfo = claim.value?.video ?? claim.value?.audio
            duration = streamInfo?.duration ?? 0
        }
        
        durationView.isHidden = duration <= 0
        if (duration > 0) {
            if (duration < 60) {
                durationLabel.text = String(format: "0:%02d", duration)
            } else {
                durationLabel.text = Helper.durationFormatter.string(from: TimeInterval(duration))
            }
        }
    }
    
    @objc func publisherTapped(_ sender: Any) {
        if currentClaim!.signingChannel != nil {
            let channelClaim = currentClaim!.signingChannel!
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            
            let currentVc = UIApplication.currentViewController()
            if let channelVc = currentVc as? ChannelViewController {
                if channelVc.channelClaim?.claimId == channelClaim.claimId {
                    // if we already have the channel page open, don't do anything
                    return
                }
            }
            
            let vc = appDelegate.mainController.storyboard?.instantiateViewController(identifier: "channel_view_vc") as! ChannelViewController
            vc.channelClaim = channelClaim
            appDelegate.mainNavigationController?.pushViewController(vc, animated: true)
        }
    }
}
