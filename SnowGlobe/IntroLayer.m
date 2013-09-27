/*
 * cocos2d for iPhone: http://www.cocos2d-iphone.org
 *
 * Copyright (c) 2008-2010 Ricardo Quesada
 * Copyright (c) 2011 Zynga Inc.
 * Copyright (c) 2013 Lars Birkemose
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

#import "IntroLayer.h"
#import "SnowGlobeLayer.h"

//------------------------------------------------------------------------------

@implementation IntroLayer

//------------------------------------------------------------------------------
#pragma mark - create
//------------------------------------------------------------------------------

// Helper class method that creates a Scene with the IntroLayer as the only child.
+ (CCScene *)scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	IntroLayer *layer = [IntroLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return(scene);
}

// 
- (id)init
{
    self = [super init];
    NSAssert(self, @"Unable to create class");

    // initialize the intro layer
    
    // ask director for the window size
    CGSize size = [[CCDirector sharedDirector] winSize];
    
    CCSprite *background;
    
    // ************************************************************
    // it is stuff like this, we want to get rid of in next version
    if( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone )
    {
        background = [CCSprite spriteWithFile:@"intro.png"];
    }
    else
    {
        background = [CCSprite spriteWithFile:@"intro-ipad.png"];
    }
    // scale the background to fit any resolution
    background.scale = size.width / background.contentSize.width;
    // end of stuff we want to get rid of
    // ************************************************************

    // place it at screen center
    background.position = ccp(size.width/2, size.height/2);
    
    // add the background as a child to this Layer
    [self addChild: background];
    
    // done
	return(self);
}

//------------------------------------------------------------------------------
#pragma mark - system callbacks
//------------------------------------------------------------------------------

- (void)onEnter
{
    // remember to call super first
	[super onEnter];
    
    // anything which should be enabled when the scene gets focus, should go here
    
    // enable touch handling
    [[[CCDirector sharedDirector] touchDispatcher] addStandardDelegate:self priority:0];
}

- (void)onExit
{
    // anything which should be disabled when the scene looses focus, should go here
    
    // disable touch
    [[[CCDirector sharedDirector] touchDispatcher] removeDelegate:self];
    
    // remember to call super last
    [super onExit];
}

//------------------------------------------------------------------------------
#pragma mark - touch handling
//------------------------------------------------------------------------------

- (void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    // any touch will trigger the main scene
	[[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:1.0 scene:[SnowGlobeLayer scene]]];
}

//------------------------------------------------------------------------------

@end
