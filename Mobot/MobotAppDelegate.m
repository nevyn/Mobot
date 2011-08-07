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
#import "TCRingBuffer.h"

@interface MobotAppDelegate () <CoCAAudioUnitRenderDelegate>
@property(nonatomic,retain) CoCAAudioUnit *outputUnit;
@property NSUInteger cycles;
@property(retain) NSData *one, *zero;
@property(retain) TCRingBuffer *buffer;
@end

static const CGFloat zeroHz = 1200, oneHz = 2400;

@implementation MobotAppDelegate
@synthesize window = _window, outputUnit = _outputUnit, cycles = _cycles, buffer;
@synthesize one, zero;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self changeBaudRate:baudRateSlider];
    self.buffer = [[[TCRingBuffer alloc] initWithCapacity:22050*sizeof(float)] autorelease];
    self.outputUnit = [CoCAAudioUnit defaultOutputUnit];
    [_outputUnit setRenderDelegate:self];
    [_outputUnit setup];
    [_outputUnit start];

}
-(OSStatus)audioUnit:(CoCAAudioUnit*)audioUnit
     renderWithFlags:(AudioUnitRenderActionFlags*)ioActionFlags
                  at:(const AudioTimeStamp*)inTimeStamp
               onBus:(UInt32)inBusNumber
          frameCount:(UInt32)inNumberFrames
           audioData:(AudioBufferList *)ioData;
{
    AudioBuffer *abuf = &(ioData->mBuffers[0]);
    float *channelBuffer = (float*)(abuf->mData);
    
    [buffer getBytes:(char*)channelBuffer ofLength:inNumberFrames*sizeof(float)];
    
    memcpy(ioData->mBuffers[1].mData, ioData->mBuffers[0].mData, inNumberFrames*sizeof(float));
    
    return noErr;
}

- (IBAction)playText:(id)sender {
    NSData *chars = [[inputField stringValue] dataUsingEncoding:NSUTF8StringEncoding];
    dispatch_async(dispatch_get_global_queue(0, 0), ^(void) {
        
        /*for(int i = 0; i < 1400; i++) {
            [buffer writeBytes:[zero bytes] ofLength:[zero length]];
        }
        return;*/
        
        /*for(int i = 0; i < chars.length; i++) {
            float channelBuffer[512];
            static float f = 0;
            static const float volume = 0.5;
            static const float pitch = 340;
            static const NSUInteger inNumberFrames = 512;
            for(int sample = 0; sample < inNumberFrames; sample++) {
                channelBuffer[sample] = sinf(f)*volume;
                f += (pitch*2*M_PI)/44100;
            }
            [buffer writeBytes:(char*)channelBuffer ofLength:512*sizeof(float)];
        }
        return;*/
        
        NSString *spaces = @"________";
        NSMutableString *bitsStr = [NSMutableString string];

    
        for(NSUInteger chari = 0, c = chars.length; chari < c; chari++) {
            char byte = ((char*)[chars bytes])[chari];
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [charDetail setStringValue:[NSString stringWithFormat:@"%d = %c = ", byte, byte]];
                [bits setStringValue:[[NSNumber numberWithChar:byte] binaryRepresentation]];
            });
            for(int d = 7; d > -1; d--) {
                char bit = byte >> d & 1;
                NSData *bitD = bit?one:zero;
                [buffer writeBytes:[bitD bytes] ofLength:bitD.length];
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    [bitsStr setString:spaces];
                    [bitsStr replaceCharactersInRange:NSMakeRange(7-d, 1) withString:bit?@"1":@"0"];
                    highlightedBits.stringValue = bitsStr;
                });
            }
        }
    });
}

- (IBAction)changeBaudRate:(NSSlider*)sender {
    self.cycles = sender.intValue;
    CGFloat baud = zeroHz/_cycles;
    baudRateDescription.stringValue = [NSString stringWithFormat:@"%d oscillations per 0 symbol = %.0f baud", _cycles, baud];
    
    NSUInteger sampleCountPerSymbol = 44000./baud;
    float samples[sampleCountPerSymbol];
    static const float volume = .5;
    float f = 0;
    for(int i = 0; i < sampleCountPerSymbol; i++) {
        samples[i] = sinf(f)*volume;
        f += (zeroHz*2*M_PI)/44100;
    }
    self.zero = [NSData dataWithBytes:samples length:sampleCountPerSymbol*sizeof(float)];
    
    f = 0;
    for(int i = 0; i < sampleCountPerSymbol; i++) {
        samples[i] = sinf(f)*volume;
        f += (oneHz*2*M_PI)/44100;
    }
    self.one = [NSData dataWithBytes:samples length:sampleCountPerSymbol*sizeof(float)];
    
    //buffer.capacity = sampleCountPerSymbol*sizeof(float)*1.2;
}
@end
