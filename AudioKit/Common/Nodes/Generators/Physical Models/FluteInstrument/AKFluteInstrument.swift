//
//  AKFlute.swift
//  AudioKit
//
//  Created by Aurelius Prochazka, revision history on Github.
//  Copyright (c) 2016 Aurelius Prochazka. All rights reserved.
//

import AVFoundation

/// STK Flutee
///
/// - Parameters:
///   - frequency: Variable frequency. Values less than the initial frequency will be doubled until it is greater than that.
///   - amplitude: Amplitude
///
open class AKFluteInstrument: AKPolyphonicNode, AKComponent {
    public typealias AKAudioUnitType = AKFluteInstrumentAudioUnit
    public static let ComponentDescription = AudioComponentDescription(generator: "skfl")

    // MARK: - Properties

    internal var internalAU: AKAudioUnitType?
    internal var token: AUParameterObserverToken?

    fileprivate var frequencyParameter: AUParameter?
    fileprivate var amplitudeParameter: AUParameter?

    /// Ramp Time represents the speed at which parameters are allowed to change
    open var rampTime: Double = AKSettings.rampDuration {
        willSet {
            if rampTime != newValue {
                internalAU?.rampTime = newValue
                internalAU?.setUpParameterRamp()
            }
        }
    }

    /// Variable frequency. Values less than the initial frequency will be doubled until it is greater than that.
    open var frequency: Double = 110 {
        willSet {
            if frequency != newValue {
                frequencyParameter?.setValue(Float(newValue), originator: token!)
            }
        }
    }

    /// Amplitude
    open var amplitude: Double = 0.5 {
        willSet {
            if amplitude != newValue {
                amplitudeParameter?.setValue(Float(newValue), originator: token!)
            }
        }
    }

    /// Tells whether the node is processing (ie. started, playing, or active)
    open var isStarted: Bool {
        return internalAU!.isPlaying()
    }

    // MARK: - Initialization

    /// Initialize the mandolin with defaults
    override convenience init() {
        self.init(frequency: 110)
    }

    /// Initialize the STK Flute model
    ///
    /// - Parameters:
    ///   - frequency: Variable frequency. Values less than the initial frequency will be doubled until it is greater than that.
    ///   - amplitude: Amplitude
    ///
    public init(
        frequency: Double = 440,
        amplitude: Double = 0.5) {


        self.frequency = frequency
        self.amplitude = amplitude

        _Self.register()

        super.init()
        AVAudioUnit.instantiate(with: _Self.ComponentDescription, options: []) {
            avAudioUnit, error in

            guard let avAudioUnitGenerator = avAudioUnit else { return }

            self.avAudioNode = avAudioUnitGenerator
            self.internalAU = avAudioUnitGenerator.auAudioUnit as? AKAudioUnitType

            AudioKit.engine.attach(self.avAudioNode)
        }

        guard let tree = internalAU?.parameterTree else { return }

        frequencyParameter = tree["frequency"]
        amplitudeParameter = tree["amplitude"]

        token = tree.token (byAddingParameterObserver: {
            address, value in

            DispatchQueue.main.async {
                if address == self.frequencyParameter!.address {
                    self.frequency = Double(value)
                } else if address == self.amplitudeParameter!.address {
                    self.amplitude = Double(value)
                }
            }
        })
        internalAU?.frequency = Float(frequency)
        internalAU?.amplitude = Float(amplitude)
    }

    /// Trigger the sound with an optional set of parameters
    ///   - frequency: Frequency in Hz
    /// - amplitude amplitude: Volume
    ///
    open func trigger(frequency: Double, amplitude: Double = 1) {
        self.frequency = frequency
        self.amplitude = amplitude
        self.internalAU!.start()
        self.internalAU!.triggerFrequency(Float(frequency), amplitude: Float(amplitude))
    }
    
    open func controlChange(channel: Int, value: Double) {
        self.internalAU!.controlChange(Int32(channel), value: Float(value * 127))
    }

    /// Function to start, play, or activate the node, all do the same thing
    open func start() {
        self.internalAU!.start()
    }

    /// Function to stop or bypass the node, both are equivalent
    open func stop() {
        self.internalAU!.stop()
    }
    /// Function to start, play, or activate the node, all do the same thing
    open override func play(noteNumber: MIDINoteNumber, velocity: MIDIVelocity) {
        print("play flute note: \(noteNumber) vel: \(velocity)")
        self.internalAU!.startNote(Int32(noteNumber), velocity: Int32(velocity))
    }
    
    /// Function to stop or bypass the node, both are equivalent
    open override func stop(noteNumber: MIDINoteNumber) {
        //
//        print("stop flute")
        self.internalAU!.stopNote(Int32(noteNumber))
    }
    
    open func afterTouch(noteNumber: MIDINoteNumber, velocity: Double) {
        self.internalAU!.controlChange(Int32(noteNumber), value: Float(velocity * 127))
    }
}
