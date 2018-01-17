//
//  AKZitaReverb.swift
//  AudioKit
//
//  Created by Aurelius Prochazka, revision history on Github.
//  Copyright © 2018 AudioKit. All rights reserved.
//

/// 8 FDN stereo zitareverb algorithm, imported from Faust.
///
open class AKZitaReverb: AKNode, AKToggleable, AKComponent, AKInput {
    public typealias AKAudioUnitType = AKZitaReverbAudioUnit
    /// Four letter unique description of the node
    public static let ComponentDescription = AudioComponentDescription(effect: "zita")

    // MARK: - Properties

    private var internalAU: AKAudioUnitType?
    private var token: AUParameterObserverToken?

    fileprivate var predelayParameter: AUParameter?
    fileprivate var crossoverFrequencyParameter: AUParameter?
    fileprivate var lowReleaseTimeParameter: AUParameter?
    fileprivate var midReleaseTimeParameter: AUParameter?
    fileprivate var dampingFrequencyParameter: AUParameter?
    fileprivate var equalizerFrequency1Parameter: AUParameter?
    fileprivate var equalizerLevel1Parameter: AUParameter?
    fileprivate var equalizerFrequency2Parameter: AUParameter?
    fileprivate var equalizerLevel2Parameter: AUParameter?
    fileprivate var dryWetMixParameter: AUParameter?

    /// Ramp Time represents the speed at which parameters are allowed to change
    @objc open dynamic var rampTime: Double = AKSettings.rampTime {
        willSet {
            internalAU?.rampTime = newValue
        }
    }

    /// Delay in ms before reverberation begins.
    @objc open dynamic var predelay: Double = 60.0 {
        willSet {
            if predelay == newValue {
                return
            }
            if internalAU?.isSetUp ?? false {
                if let existingToken = token {
                    predelayParameter?.setValue(Float(newValue), originator: existingToken)
                    return
                }
            }
            internalAU?.setParameterImmediately(.predelay, value: newValue)
        }
    }

    /// Crossover frequency separating low and middle frequencies (Hz).
    @objc open dynamic var crossoverFrequency: Double = 200.0 {
        willSet {
            if crossoverFrequency == newValue {
                return
            }
            if internalAU?.isSetUp ?? false {
                if let existingToken = token {
                    crossoverFrequencyParameter?.setValue(Float(newValue), originator: existingToken)
                    return
                }
            }
            internalAU?.setParameterImmediately(.crossoverFrequency, value: newValue)
        }
    }

    /// Time (in seconds) to decay 60db in low-frequency band.
    @objc open dynamic var lowReleaseTime: Double = 3.0 {
        willSet {
            if lowReleaseTime == newValue {
                return
            }
            if internalAU?.isSetUp ?? false {
                if let existingToken = token {
                    lowReleaseTimeParameter?.setValue(Float(newValue), originator: existingToken)
                    return
                }
            }
            internalAU?.setParameterImmediately(.lowReleaseTime, value: newValue)
        }
    }

    /// Time (in seconds) to decay 60db in mid-frequency band.
    @objc open dynamic var midReleaseTime: Double = 2.0 {
        willSet {
            if midReleaseTime == newValue {
                return
            }
            if internalAU?.isSetUp ?? false {
                if let existingToken = token {
                    midReleaseTimeParameter?.setValue(Float(newValue), originator: existingToken)
                    return
                }
            }
            internalAU?.setParameterImmediately(.midReleaseTime, value: newValue)
        }
    }

    /// Frequency (Hz) at which the high-frequency T60 is half the middle-band's T60.
    @objc open dynamic var dampingFrequency: Double = 6_000.0 {
        willSet {
            if dampingFrequency == newValue {
                return
            }
            if internalAU?.isSetUp ?? false {
                if let existingToken = token {
                    dampingFrequencyParameter?.setValue(Float(newValue), originator: existingToken)
                    return
                }
            }
            internalAU?.setParameterImmediately(.dampingFrequency, value: newValue)
        }
    }

    /// Center frequency of second-order Regalia Mitra peaking equalizer section 1.
    @objc open dynamic var equalizerFrequency1: Double = 315.0 {
        willSet {
            if equalizerFrequency1 == newValue {
                return
            }
            if internalAU?.isSetUp ?? false {
                if let existingToken = token {
                    equalizerFrequency1Parameter?.setValue(Float(newValue), originator: existingToken)
                    return
                }
            }
            internalAU?.setParameterImmediately(.equalizerFrequency1, value: newValue)
        }
    }

    /// Peak level in dB of second-order Regalia-Mitra peaking equalizer section 1
    @objc open dynamic var equalizerLevel1: Double = 0.0 {
        willSet {
            if equalizerLevel1 == newValue {
                return
            }
            if internalAU?.isSetUp ?? false {
                if let existingToken = token {
                    equalizerLevel1Parameter?.setValue(Float(newValue), originator: existingToken)
                    return
                }
            }
            internalAU?.setParameterImmediately(.equalizerLevel1, value: newValue)
        }
    }

    /// Center frequency of second-order Regalia Mitra peaking equalizer section 2.
    @objc open dynamic var equalizerFrequency2: Double = 1_500.0 {
        willSet {
            if equalizerFrequency2 == newValue {
                return
            }
            if internalAU?.isSetUp ?? false {
                if let existingToken = token {
                    equalizerFrequency2Parameter?.setValue(Float(newValue), originator: existingToken)
                    return
                }
            }
            internalAU?.setParameterImmediately(.equalizerFrequency2, value: newValue)
        }
    }

    /// Peak level in dB of second-order Regalia-Mitra peaking equalizer section 2
    @objc open dynamic var equalizerLevel2: Double = 0.0 {
        willSet {
            if equalizerLevel2 == newValue {
                return
            }
            if internalAU?.isSetUp ?? false {
                if let existingToken = token {
                    equalizerLevel2Parameter?.setValue(Float(newValue), originator: existingToken)
                    return
                }
            }
            internalAU?.setParameterImmediately(.equalizerLevel2, value: newValue)
        }
    }

    /// 0 = all dry, 1 = all wet
    @objc open dynamic var dryWetMix: Double = 1.0 {
        willSet {
            if dryWetMix == newValue {
                return
            }
            if internalAU?.isSetUp ?? false {
                if let existingToken = token {
                    dryWetMixParameter?.setValue(Float(newValue), originator: existingToken)
                    return
                }
            }
            internalAU?.setParameterImmediately(.dryWetMix, value: newValue)
        }
    }

    /// Tells whether the node is processing (ie. started, playing, or active)
    @objc open dynamic var isStarted: Bool {
        return internalAU?.isPlaying ?? false
    }

    // MARK: - Initialization

    /// Initialize this reverb node
    ///
    /// - Parameters:
    ///   - input: Input node to process
    ///   - predelay: Delay in ms before reverberation begins.
    ///   - crossoverFrequency: Crossover frequency separating low and middle frequencies (Hz).
    ///   - lowReleaseTime: Time (in seconds) to decay 60db in low-frequency band.
    ///   - midReleaseTime: Time (in seconds) to decay 60db in mid-frequency band.
    ///   - dampingFrequency: Frequency (Hz) at which the high-frequency T60 is half the middle-band's T60.
    ///   - equalizerFrequency1: Center frequency of second-order Regalia Mitra peaking equalizer section 1.
    ///   - equalizerLevel1: Peak level in dB of second-order Regalia-Mitra peaking equalizer section 1
    ///   - equalizerFrequency2: Center frequency of second-order Regalia Mitra peaking equalizer section 2.
    ///   - equalizerLevel2: Peak level in dB of second-order Regalia-Mitra peaking equalizer section 2
    ///   - dryWetMix: 0 = all dry, 1 = all wet
    ///
    @objc public init(
        _ input: AKNode? = nil,
        predelay: Double = 60.0,
        crossoverFrequency: Double = 200.0,
        lowReleaseTime: Double = 3.0,
        midReleaseTime: Double = 2.0,
        dampingFrequency: Double = 6_000.0,
        equalizerFrequency1: Double = 315.0,
        equalizerLevel1: Double = 0.0,
        equalizerFrequency2: Double = 1_500.0,
        equalizerLevel2: Double = 0.0,
        dryWetMix: Double = 1.0) {

        self.predelay = predelay
        self.crossoverFrequency = crossoverFrequency
        self.lowReleaseTime = lowReleaseTime
        self.midReleaseTime = midReleaseTime
        self.dampingFrequency = dampingFrequency
        self.equalizerFrequency1 = equalizerFrequency1
        self.equalizerLevel1 = equalizerLevel1
        self.equalizerFrequency2 = equalizerFrequency2
        self.equalizerLevel2 = equalizerLevel2
        self.dryWetMix = dryWetMix

        _Self.register()

        super.init()
        AVAudioUnit._instantiate(with: _Self.ComponentDescription) { [weak self] avAudioUnit in
            guard let strongSelf = self else {
                AKLog("Error: self is nil")
                return
            }
            strongSelf.avAudioNode = avAudioUnit
            strongSelf.internalAU = avAudioUnit.auAudioUnit as? AKAudioUnitType
            input?.connect(to: strongSelf)
        }

        guard let tree = internalAU?.parameterTree else {
            AKLog("Parameter Tree Failed")
            return
        }

        predelayParameter = tree["predelay"]
        crossoverFrequencyParameter = tree["crossoverFrequency"]
        lowReleaseTimeParameter = tree["lowReleaseTime"]
        midReleaseTimeParameter = tree["midReleaseTime"]
        dampingFrequencyParameter = tree["dampingFrequency"]
        equalizerFrequency1Parameter = tree["equalizerFrequency1"]
        equalizerLevel1Parameter = tree["equalizerLevel1"]
        equalizerFrequency2Parameter = tree["equalizerFrequency2"]
        equalizerLevel2Parameter = tree["equalizerLevel2"]
        dryWetMixParameter = tree["dryWetMix"]

        token = tree.token(byAddingParameterObserver: { [weak self] _, _ in

            guard let _ = self else {
                AKLog("Unable to create strong reference to self")
                return
            } // Replace _ with strongSelf if needed
            DispatchQueue.main.async {
                // This node does not change its own values so we won't add any
                // value observing, but if you need to, this is where that goes.
            }
        })

        self.internalAU?.setParameterImmediately(.predelay, value: predelay)
        self.internalAU?.setParameterImmediately(.crossoverFrequency, value: crossoverFrequency)
        self.internalAU?.setParameterImmediately(.lowReleaseTime, value: lowReleaseTime)
        self.internalAU?.setParameterImmediately(.midReleaseTime, value: midReleaseTime)
        self.internalAU?.setParameterImmediately(.dampingFrequency, value: dampingFrequency)
        self.internalAU?.setParameterImmediately(.equalizerFrequency1, value: equalizerFrequency1)
        self.internalAU?.setParameterImmediately(.equalizerLevel1, value: equalizerLevel1)
        self.internalAU?.setParameterImmediately(.equalizerFrequency2, value: equalizerFrequency2)
        self.internalAU?.setParameterImmediately(.equalizerLevel2, value: equalizerLevel2)
        self.internalAU?.setParameterImmediately(.dryWetMix, value: dryWetMix)
    }

    // MARK: - Control

    /// Function to start, play, or activate the node, all do the same thing
    @objc open func start() {
        internalAU?.start()
    }

    /// Function to stop or bypass the node, both are equivalent
    @objc open func stop() {
        internalAU?.stop()
    }
}