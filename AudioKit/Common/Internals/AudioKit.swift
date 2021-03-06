//
//  AudioKit.swift
//  AudioKit
//
//  Created by Aurelius Prochazka, revision history on Github.
//  Copyright © 2018 AudioKit. All rights reserved.
//

#if !os(tvOS)
import CoreAudioKit
#endif

#if !os(macOS)
import UIKit
#endif
import Dispatch

public typealias AKCallback = () -> Void

/// Function type for MIDI callbacks
public typealias AKMIDICallback = (MIDIByte, MIDIByte, MIDIByte) -> Void

/// Top level AudioKit managing class
@objc open class AudioKit: NSObject {

    #if !os(macOS)
    static let deviceSampleRate = AVAudioSession.sharedInstance().sampleRate
    #else
    static let deviceSampleRate: Double = 44_100
    #endif

    // MARK: - Internal audio engine mechanics

    /// Reference to the AV Audio Engine
    @objc public static internal(set) var engine: AVAudioEngine {
        get {
            _ = AudioKit.deviceSampleRate // read the original sample rate before any reference to AVAudioEngine happens, so value is retained
            return _engine
        }
        set {
            _engine = newValue
        }
    }

    static internal(set) var _engine = AVAudioEngine()

    /// Reference to singleton MIDI

    #if !os(tvOS)
    public static let midi = AKMIDI()
    #endif

    @objc static var finalMixer = AKMixer()

    // MARK: - Device Management

    /// An audio output operation that most applications will need to use last
    @objc public static var output: AKNode? {
        didSet {
            do {
                try updateSessionCategoryAndOptions()
                output?.connect(to: finalMixer)
                engine.connect(finalMixer.avAudioNode, to: engine.outputNode)

                } catch {
                AKLog("Could not set output: \(error)")
            }
        }
    }

    #if os(macOS)
    /// Enumerate the list of available devices.
    @objc public static var devices: [AKDevice]? {
        EZAudioUtilities.setShouldExitOnCheckResultFail(false)
        return EZAudioDevice.devices().map { AKDevice(ezAudioDevice: $0 as! EZAudioDevice) }
    }
    #endif

    /// Enumerate the list of available input devices.
    @objc public static var inputDevices: [AKDevice]? {
        #if os(macOS)
            EZAudioUtilities.setShouldExitOnCheckResultFail(false)
            return EZAudioDevice.inputDevices().map { AKDevice(ezAudioDevice: $0 as! EZAudioDevice) }
        #else
            var returnDevices = [AKDevice]()
            if let devices = AVAudioSession.sharedInstance().availableInputs {
                for device in devices {
                    if device.dataSources == nil || device.dataSources!.isEmpty {
                        returnDevices.append(AKDevice(name: device.portName, deviceID: device.uid))
                    } else {
                        for dataSource in device.dataSources! {
                            returnDevices.append(AKDevice(name: device.portName,
                                                          deviceID: "\(device.uid) \(dataSource.dataSourceName)"))
                        }
                    }
                }
                return returnDevices
            }
            return nil
        #endif
    }

    /// Enumerate the list of available output devices.
    @objc public static var outputDevices: [AKDevice]? {
        #if os(macOS)
            EZAudioUtilities.setShouldExitOnCheckResultFail(false)
            return EZAudioDevice.outputDevices().map { AKDevice(ezAudioDevice: $0 as! EZAudioDevice) }
        #else
            let devs = AVAudioSession.sharedInstance().currentRoute.outputs
            if devs.isNotEmpty {
                var outs = [AKDevice]()
                for dev in devs {
                    outs.append(AKDevice(name: dev.portName, deviceID: dev.uid))
                }
                return outs
            }
            return nil
        #endif
    }

    /// The name of the current input device, if available.
    @objc public static var inputDevice: AKDevice? {
        #if os(macOS)
            if let dev = EZAudioDevice.currentInput() {
                return AKDevice(name: dev.name, deviceID: dev.deviceID)
            }
        #else
            if let dev = AVAudioSession.sharedInstance().preferredInput {
                return AKDevice(name: dev.portName, deviceID: dev.uid)
            } else {
                let inputDevices = AVAudioSession.sharedInstance().currentRoute.inputs
                if inputDevices.isNotEmpty {
                    for device in inputDevices {
                        let dataSourceString = device.selectedDataSource?.description ?? ""
                        let id = "\(device.uid) \(dataSourceString)".trimmingCharacters(in: [" "])
                        return AKDevice(name: device.portName, deviceID: id)
                    }
                }
            }
        #endif
        return nil
    }

    /// The name of the current output device, if available.
    @objc public static var outputDevice: AKDevice? {
        #if os(macOS)
            if let dev = EZAudioDevice.currentOutput() {
                return AKDevice(name: dev.name, deviceID: dev.deviceID)
            }
        #else
            let devs = AVAudioSession.sharedInstance().currentRoute.outputs
            if devs.isNotEmpty {
                return AKDevice(name: devs[0].portName, deviceID: devs[0].uid)
            }

        #endif
        return nil
    }

        /// Change the preferred input device, giving it one of the names from the list of available inputs.
    @objc public static func setInputDevice(_ input: AKDevice) throws {
        #if os(macOS)
            try AKTry {
                var address = AudioObjectPropertyAddress(
                    mSelector: kAudioHardwarePropertyDefaultInputDevice,
                    mScope: kAudioObjectPropertyScopeGlobal,
                    mElement: kAudioObjectPropertyElementMaster)
                var devid = input.deviceID
                AudioObjectSetPropertyData(
                    AudioObjectID(kAudioObjectSystemObject),
                    &address, 0, nil, UInt32(MemoryLayout<AudioDeviceID>.size), &devid)
            }
        #else
            if let devices = AVAudioSession.sharedInstance().availableInputs {
                for device in devices {
                    if device.dataSources == nil || device.dataSources!.isEmpty {
                        if device.uid == input.deviceID {
                            do {
                                try AVAudioSession.sharedInstance().setPreferredInput(device)
                            } catch {
                                AKLog("Could not set the preferred input to \(input)")
                            }
                        }
                    } else {
                        for dataSource in device.dataSources! {
                            if input.deviceID == "\(device.uid) \(dataSource.dataSourceName)" {
                                do {
                                    try AVAudioSession.sharedInstance().setInputDataSource(dataSource)
                                } catch {
                                    AKLog("Could not set the preferred input to \(input)")
                                }
                            }
                        }
                    }
                }
            }

            if let devices = AVAudioSession.sharedInstance().availableInputs {
                for dev in devices {
                    if dev.uid == input.deviceID {
                        do {
                            try AVAudioSession.sharedInstance().setPreferredInput(dev)
                        } catch {
                            AKLog("Could not set the preferred input to \(input)")
                        }
                    }
                }
            }
        #endif
    }

    /// Change the preferred output device, giving it one of the names from the list of available output.
    @objc public static func setOutputDevice(_ output: AKDevice) throws {
        #if os(macOS)
            try AKTry {
                var id = output.deviceID
                if let audioUnit = AudioKit.engine.outputNode.audioUnit {
                    AudioUnitSetProperty(audioUnit,
                                         kAudioOutputUnitProperty_CurrentDevice,
                                         kAudioUnitScope_Global, 0,
                                         &id,
                                         UInt32(MemoryLayout<DeviceID>.size))
                }
            }
        #else
            //not available on ios
        #endif
    }

    // MARK: - Disconnect node inputs

    /// Disconnect all inputs
    @objc public static func disconnectAllInputs() {
        engine.disconnectNodeInput(finalMixer.avAudioNode)
    }
}
