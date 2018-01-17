//
//  Compressor.h
//
//  Created by Mike Gazzaruso on 26/05/14.
//
//

#pragma once

#include "pluginconstants.h"
#include "CDelay.h"

class Compressor {
    
public:
    Compressor(float fThreshold, float fRatio, float fAttack, float fRelease,
               int iSampleRate);
    float Process(float fInputSignal, bool bLimitOn, float fSensitivity);
    void setParameters(float fThreshold, float fRatio, float fAttack,
                       float fRelease);
    float getCompGain();
    
    // Private
private:
    CEnvelopeDetector envDetector;
    CDelay delayLookAhead;
    float theThreshold, theRatio, theAttack, theRelease;
    float calcCompressorGain(float fDetectorValue, float fThreshold, float fRatio,
                             float fKneeWidth, bool bLimit);
    float compGain;
};
