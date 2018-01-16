//
//  AKTremoloAudioUnit.h
//  AudioKit
//
//  Created by Aurelius Prochazka, revision history on Github.
//  Copyright © 2017 AudioKit. All rights reserved.
//

#pragma once
#import "AKAudioUnit.h"

@interface AKTremoloAudioUnit : AKAudioUnit
@property (nonatomic) float frequency;
@property (nonatomic) float depth;

- (void)setupWaveform:(int)size;
- (void)setWaveformValue:(float)value atIndex:(UInt32)index;
@end
