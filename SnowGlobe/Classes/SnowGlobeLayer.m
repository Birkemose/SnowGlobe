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

#import "SnowGlobeLayer.h"
#import "GameConfig.h"

//------------------------------------------------------------------------------

const double    SnowGlobeSimulationInterval             = ( 1.0f / 60.0f );
const double    SnowGlobeGravity                        = 1.00f;
const double    SnowGlobeDamping                        = 1.05f;
const CGPoint   SnowGlobePosition                       = { 0.50, 0.60 };
const double    SnowGlobeShakeStrength                  = 1.0f;

//------------------------------------------------------------------------------

@implementation SnowGlobeLayer
{
    ChipmunkSpace *_space;
    SnowGlobeContent *_content;
    SnowGlobe *_snowGlobe;
}

//------------------------------------------------------------------------------

+ (CCScene *)scene
{
    // create a scene, and add a snow globe layer to it
	CCScene *scene = [[CCScene alloc] init];
	SnowGlobeLayer *layer = [[SnowGlobeLayer alloc] init];
	[scene addChild:layer];
    
	// return the scene
	return(scene);
}

//------------------------------------------------------------------------------

- (id)init {
	self = [super init];
	
	// init chipmunk
	_space = [[ChipmunkSpace alloc] init];
	_space.gravity = CGPointMake(0, -SnowGlobeGravity);
	_space.damping = SnowGlobeDamping;
	
    // create content
    _content = [SnowGlobeContent contentWithDictionary:@"mermaid.plist" andSpace:_space];
    _content.position = ccp(160, 265);
    [self addChild:_content];
    [_space add:_content];
     
    // create snowglobe
    _snowGlobe = [SnowGlobe snowGlobe];
    _snowGlobe.position = ccp(160, 265);
    [self addChild:_snowGlobe];
    [_space add:_snowGlobe];
     
	// done
	return( self );
}

//------------------------------------------------------------------------------

- (void)dealloc
{
    [_space release];
    [super dealloc];
}

//------------------------------------------------------------------------------

- (void)onEnter
{
    [super onEnter];
	// initialize touch
	[[[CCDirector sharedDirector] touchDispatcher] addStandardDelegate:self priority:0];
	// init animation
	[self scheduleUpdate];
}

//------------------------------------------------------------------------------

- (void)onExit
{
    [[[CCDirector sharedDirector] touchDispatcher] removeDelegate:self];
    [self unscheduleUpdate];
    [super onExit];
}
//------------------------------------------------------------------------------

- (void)update:( ccTime )dt
{
	[_space step:SnowGlobeSimulationInterval];
	[_snowGlobe updatePositions];
}

//------------------------------------------------------------------------------
// touch handing
//------------------------------------------------------------------------------

- (void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	// shake snow globe content
	[_snowGlobe shake:SnowGlobeShakeStrength];
}

//------------------------------------------------------------------------------

@end
