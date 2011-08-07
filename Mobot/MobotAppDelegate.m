//
//  MobotAppDelegate.m
//  Mobot
//
//  Created by Joachim Bengtsson on 2011-08-06.
//  Copyright 2011 Third Cog Software. All rights reserved.
//

#import "MobotAppDelegate.h"
#import "CoCAAudioUnit.h"
#import <CoreAudio/CoreAudio.h>
#import "PrivateUtil.h"

@interface MobotAppDelegate () <CoCAAudioUnitRenderDelegate>
@property(nonatomic,retain) CoCAAudioUnit *outputUnit;
@property NSUInteger cycles;
@property(retain) NSMutableData *spill;
@property(retain) NSMutableData *charactersToPlay;
@property(retain) NSData *one, *zero;
@end

static const CGFloat zeroHz = 1200, oneHz = 2400;

@implementation MobotAppDelegate
@synthesize window = _window, outputUnit = _outputUnit, cycles = _cycles, charactersToPlay = _charactersToPlay, spill = _spill;
@synthesize one, zero;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.charactersToPlay = [NSMutableData data];
    self.spill = [NSMutableData data];
    self.outputUnit = [CoCAAudioUnit defaultOutputUnit];
    [_outputUnit setRenderDelegate:self];
    [_outputUnit setup];

}
-(OSStatus)audioUnit:(CoCAAudioUnit*)audioUnit
     renderWithFlags:(AudioUnitRenderActionFlags*)ioActionFlags
                  at:(const AudioTimeStamp*)inTimeStamp
               onBus:(UInt32)inBusNumber
          frameCount:(UInt32)inNumberFrames
           audioData:(AudioBufferList *)ioData;
{
    AudioBuffer *buffer = &(ioData->mBuffers[0]);
    float *channelBuffer = (float*)(buffer->mData);
    
    bzero(channelBuffer, inNumberFrames*sizeof(float));
    
    if(_spill.length > 0) {
        NSRange thisRange = NSMakeRange(0, MIN(_spill.length, inNumberFrames*sizeof(float)));
        NSData *thisData = [_spill subdataWithRange:thisRange];
        [_spill setData:[_spill subdataWithRange:NSMakeRange(NSMaxRange(thisRange), _spill.length - NSMaxRange(thisRange))]];
        [thisData getBytes:channelBuffer];
        channelBuffer += thisRange.length/sizeof(float);
        inNumberFrames -= thisRange.length;
    }
    
    NSUInteger symbolLength = self.one.length;
    NSUInteger charactersThatWillFit = inNumberFrames/(symbolLength*8) + 1;
    charactersThatWillFit = MIN([_charactersToPlay length], charactersThatWillFit);
    NSUInteger samplesNeeded = charactersThatWillFit*symbolLength*8;
    NSInteger overflowSamples = samplesNeeded-inNumberFrames;
    
    NSMutableData *output = [NSMutableData dataWithLength:samplesNeeded*sizeof(float)];
    
    NSRange thisRange = NSMakeRange(0, charactersThatWillFit);
    NSData *thisData = [_charactersToPlay subdataWithRange:thisRange];
    [_charactersToPlay setData:[_charactersToPlay subdataWithRange:NSMakeRange(NSMaxRange(thisRange), _charactersToPlay.length - NSMaxRange(thisRange))]];
    
    
    
    NSRange r = NSMakeRange(0, symbolLength);
    for(int i = 0; i < samplesNeeded; i++) {
        char byte = ((char*)[thisData bytes])[i];
        for(int d = 0; d < 7; d++) {
            char bit = byte >> d & 1;
            NSData *bitD = bit?one:zero;
            [output replaceBytesInRange:r withBytes:[bitD bytes]];
            r.location += r.length;
        }
    }
    
    
    
    
    for(int sample = 0; sample < inNumberFrames; sample++) {
        channelBuffer[sample] = sinf(f)*volume;
        f += (pitch*2*M_PI)/44100;
    }
    
    memcpy(ioData->mBuffers[1].mData, ioData->mBuffers[0].mData, inNumberFrames*sizeof(float));
    
    return noErr;
}

- (IBAction)playText:(id)sender {
    self.charactersToPlay = [[[[sender stringValue] dataUsingEncoding:NSUTF8StringEncoding] mutableCopy] autorelease];
    [_outputUnit start];
}

- (IBAction)changeBaudRate:(NSSlider*)sender {
    self.cycles = sender.intValue;
    CGFloat baud = zeroHz/_cycles;
    baudRateDescription.stringValue = [NSString stringWithFormat:@"%d oscillations per 0 symbol = %f.0 baud", _cycles, baud];
    
    NSUInteger sampleCountPerSymbol = 44000./baud;
    float samples[sampleCountPerSymbol];
    static const float volume = .5;
    
    for(int i = 0; i < sampleCountPerSymbol; i++)
        samples[i] = sin(zeroHz)*volume;
    self.zero = [NSData dataWithBytes:samples length:sampleCountPerSymbol*sizeof(float)];
    
    for(int i = 0; i < sampleCountPerSymbol; i++)
        samples[i] = sin(oneHz)*volume;
    self.one = [NSData dataWithBytes:samples length:sampleCountPerSymbol*sizeof(float)];
    
    
    
}
@end
