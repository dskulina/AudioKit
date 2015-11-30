//: [TOC](Table%20Of%20Contents) | [Previous](@previous) | [Next](@next)
//:
//: ---
//:
//: ## AK
Distortion
//: ### Add description
import XCPlayground
import AudioKit

//: Change the source to "mic" to process your voice
let source = "player"

//: This is set-up, the next thing to change is in the next section:
let audiokit = AKManager.sharedInstance
let mic = AKMicrophone()
let bundle = NSBundle.mainBundle()
let file = bundle.pathForResource("PianoBassDrumLoop", ofType: "wav")
let player = AKAudioPlayer(file!)
player.looping = true
let playerWindow: AKAudioPlayerWindow
let distortion: AKDistortion

switch source {
case "mic":
    distortion = AKDistortion(mic)
default:
    distortion = AKDistortion(player)
    playerWindow = AKAudioPlayerWindow(player)
}
distor//: Set the parameters of the distortion here
tion.delay = 0.1 // Milliseconds
distortion.decay = 1.0 // Rate
distortion.delayMix = 50 // Percent

distor//: These are the decimator-specific parameters
tion.decimation = 50 // Percent
distortion.rounding = 0 // Percent
distortion.decimationMix = 50 // Percent
distortion.linearTerm = 50 // Percent
distortion.squaredTerm = 50 // Percent
distortion.cubicTerm = 50 // Percent
distortion.polynomialMix = 50 // Percent
distortion.ringModFreq1 = 100 // Hertz
distortion.ringModFreq2 = 100 // Hertz
distortion.ringModBalance = 50 // Percent
distortion.ringModMix = 0 // Percent
distortion.softClipGain = -6 // dB
distortion.finalMix = 50 // Percent

var distortionWindow = AKDistortionWindow(distortion)

audiokit.audioOutput = distortion
audiokit.start()

XCPlaygroundPage.currentPage.needsIndefiniteExecution = true

//: [TOC](Table%20Of%20Contents) | [Previous](@previous) | [Next](@next)