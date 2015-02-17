//
//  TextToSpeechViewController.swift
//  CityAudioTour
//
//  Created by Red_iMac on 2/12/15.
//  Copyright (c) 2015 SE491-591. All rights reserved.
//

import UIKit
import AVFoundation

class TextToSpeechViewController: UIViewController, AVSpeechSynthesizerDelegate {
    
    var receiveID : Int?
    var synthersizer = AVSpeechSynthesizer()
    var utterance = AVSpeechUtterance(string: "")
    
    var service = CATAzureService()
    
    @IBOutlet weak var attractionLabel: UILabel!
    @IBOutlet weak var speechContent: UITextView!
    
    @IBAction func BackToMapView(sender: UIBarButtonItem) {
        navigationController?.popToRootViewControllerAnimated(true)
    }

    @IBAction func playAudio(sender: UIButton) {
        
        if !synthersizer.speaking{
            utterance = AVSpeechUtterance(string: speechContent.text)
            utterance.rate = 0.1
            synthersizer.speakUtterance(utterance)
        } else if synthersizer.paused{
            synthersizer.continueSpeaking()
        }
    }
    
    @IBAction func stopAudio(sender: UIButton) {
        synthersizer.stopSpeakingAtBoundary(.Immediate)
    }
    
    @IBAction func pauseAudio(sender: AnyObject) {
        synthersizer.pauseSpeakingAtBoundary(.Immediate)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.retrieveDataFromServer()
        // Set text view to start at the top line
        speechContent.scrollRangeToVisible(NSMakeRange(0, 0))
        self.synthersizer.delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidDisappear(animated: Bool) {
        synthersizer.stopSpeakingAtBoundary(.Word)
    }
    
    func retrieveDataFromServer() {
       
        var attractionContent = service.GetAttractionContentByID(receiveID!)
        attractionLabel.attributedText = NSAttributedString(string: attractionContent.Title)
        speechContent.attributedText = NSAttributedString(string: attractionContent.Description)
        
    }
    
    func speechSynthesizer(synthesizer: AVSpeechSynthesizer!, didFinishSpeechUtterance utterance: AVSpeechUtterance!) {
        speechContent.attributedText = NSAttributedString(string: utterance.speechString)
    }
    
    func speechSynthesizer(synthesizer: AVSpeechSynthesizer!, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance!) {
        let s = (utterance.speechString as NSString).substringWithRange(characterRange)
        println("about to say \(s)")
        let mutableAttributedString = NSMutableAttributedString(string: utterance.speechString)
        mutableAttributedString.addAttribute(NSForegroundColorAttributeName, value: UIColor.redColor(), range: characterRange)
        speechContent.attributedText = mutableAttributedString
    }

    func speechSynthesizer(synthesizer: AVSpeechSynthesizer!, didCancelSpeechUtterance utterance: AVSpeechUtterance!) {
        speechContent.attributedText = NSAttributedString(string: utterance.speechString)
    }
    

    
}
