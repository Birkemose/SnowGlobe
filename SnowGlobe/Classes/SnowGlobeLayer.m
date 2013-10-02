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

/**
 *  Damping slightly above 1.00 gives by far the most "dynamic" and believeable simulation.
 *  As particles will continue to gain speed, the simulation might get never get to rest, if there are no objects inside the globe, to slow them down
 */
const double    SnowGlobeDamping                        = 1.050f;

const CGPoint   SnowGlobePosition                       = { 0.50f, 0.55f };
const double    SnowGlobeShakeStrength                  = 1.0f;

const CGPoint   SnowGlobeNamePosition                   = { 0.50f, 0.18f };
const float     SnowGlobeNameSize                       = 36.0f;
const CGPoint   SnowGlobeLocationPosition               = { 0.50f, 0.12f };
const float     SnowGlobeLocationSize                   = 20.0f;

const float     SnowGlobeNextMargin                     = 0.65f;

const NSString *SnowGlobeSelectedContentKey             = @"selected.content";

//------------------------------------------------------------------------------

@implementation SnowGlobeLayer
{
    ChipmunkSpace *_space;
    SnowGlobeContent *_content;
    SnowGlobe *_snowGlobe;
    NSArray *_contentList;
    NSInteger _selectedContent;
    CCLabelTTF *_labelName;
    CCLabelTTF *_labelLocation;
}

//------------------------------------------------------------------------------

+ (CCScene *)scene
{
    // create a scene, and add a snow globe layer to it
	CCScene *scene = [[[CCScene alloc] init] autorelease];
	SnowGlobeLayer *layer = [[[SnowGlobeLayer alloc] init] autorelease];
	[scene addChild:layer];
    
	// return the scene
	return(scene);
}

//------------------------------------------------------------------------------

- (id)init {
	self = [super init];
    
    // get size
    CGSize size = [CCDirector sharedDirector].winSize;
    
    // create list of valid content
    _contentList = [[NSArray arrayWithObjects:@"mermaid.plist", @"tajmahal.plist", nil] retain];
	
    // load selected content from user defaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    _selectedContent = [defaults integerForKey:(NSString *)SnowGlobeSelectedContentKey] % _contentList.count;
    NSString *content = [_contentList objectAtIndex:_selectedContent];
    
	// init chipmunk
	_space = [[ChipmunkSpace alloc] init];
	_space.gravity = CGPointMake(0, -SnowGlobeGravity);
	_space.damping = SnowGlobeDamping;
	
    // create content
    _content = [SnowGlobeContent contentWithPlist:content andSpace:_space];
    _content.position = ccp(size.width * SnowGlobePosition.x, size.height * SnowGlobePosition.y);
    [self addChild:_content];
    [_space add:_content];
     
    // create snowglobe
    _snowGlobe = [SnowGlobe snowGlobe];
    _snowGlobe.position = _content.position;
    [self addChild:_snowGlobe];
    [_space add:_snowGlobe];
    
    // show information
    _labelName = [CCLabelTTF labelWithString:_content.name fontName:@"Arial" fontSize:SnowGlobeNameSize * _snowGlobe.contentScale];
    _labelName.position = ccp(size.width * SnowGlobeNamePosition.x, size.height * SnowGlobeNamePosition.y);
    [self addChild:_labelName];
    
    _labelLocation = [CCLabelTTF labelWithString:_content.location fontName:@"Arial" fontSize:SnowGlobeLocationSize * _snowGlobe.contentScale];
    _labelLocation.position = ccp(size.width * SnowGlobeLocationPosition.x, size.height * SnowGlobeLocationPosition.y);
    [self addChild:_labelLocation];
    
    // next button
    CCMenuItemSprite *button = [CCMenuItemSprite itemWithNormalSprite:[CCSprite spriteWithSpriteFrameName:@"next.png"]
                                                       selectedSprite:[CCSprite spriteWithSpriteFrameName:@"next.png"]
                                                               target:self
                                                             selector:@selector(nextPressed:)];
    CCMenu *menu = [CCMenu menuWithItems:button, nil];
    menu.position = ccp(size.width - button.contentSize.width * SnowGlobeNextMargin, button.contentSize.height * SnowGlobeNextMargin);
    [self addChild:menu];
    
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
    // step physics at a fixed interval
    // this means, that dt gets bigger than SnowGlobeSimulationInterval, the simulation will start to slow down
	[_space step:SnowGlobeSimulationInterval];
    
	[_snowGlobe updatePositions];
}

//------------------------------------------------------------------------------
// touch handing
//------------------------------------------------------------------------------

- (void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    // convert touch position to a coordinate in physics space
    CGPoint pos = [[CCDirector sharedDirector] convertTouchToGL:[touches anyObject]];
    pos = [_snowGlobe convertToNodeSpace:pos];
    
	// shake snow globe content
	[_snowGlobe shake:pos strength:SnowGlobeShakeStrength];
}

//------------------------------------------------------------------------------

- (void)nextPressed:(id)sender
{
    // get next content
    _selectedContent ++;
    _selectedContent %= _contentList.count;
    
    // save selected content to NSUserDefaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:_selectedContent forKey:(NSString *)SnowGlobeSelectedContentKey];
    [defaults synchronize];
    
    // remove old content, create some new, and add it
    [_space remove:_content];
    [_content createContentWithPlist:[_contentList objectAtIndex:_selectedContent]];
    [_space add:_content];
    
    // also update the labels
    _labelName.string = _content.name;
    _labelLocation.string = _content.location;
}

//------------------------------------------------------------------------------

@end
