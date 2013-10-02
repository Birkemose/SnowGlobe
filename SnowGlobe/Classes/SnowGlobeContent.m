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

#import "SnowGlobeContent.h"
#import "SnowGlobe.h"
#import "SnowGlobeLayer.h"

//------------------------------------------------------------------------------
// various constants

const int       SnowGlobeMaxShapes                      = 99;

const double    SnowGlobeSegmentRadius                  = 1.0f;
const double    SnowGlobeSegmentElasticity              = 0.0f;
const double    SnowGlobeSegmentFriction                = 5.0f;

const id        SnowGlobeCollisionIdContent             = 0x100000;
const id        SnowGlobeCollisionIdSnowFlakes          = 0x100001;
const id        SnowGlobeCollisionIdDisturber           = 0x100002;
const id        SnowGlobeCollisionIdGlass               = 0x100003;

const int       SnowGlobeCollisionLayerGlobe            = 0x01;
const int       SnowGlobeCollisionLayerShape            = 0x02;
const int       SnowGlobeCollisionLayerShowFlakes       = 0x04;
const int       SnowGlobeCollisionLayerDisturber        = 0x08;
const int       SnowGlobeCollisionLayerAll              = 0x0F;

//------------------------------------------------------------------------------

@implementation SnowGlobeContent
{
	NSMutableSet *_chipmunkObjects;
    ChipmunkSpace *_space;
    CCSprite *_background;
}

//------------------------------------------------------------------------------

+ (SnowGlobeContent *)contentWithPlist:(NSString *)plist andSpace:(ChipmunkSpace *)space
{
	return([[[self alloc] initWithPlist:plist andSpace:space] autorelease]);
}

//------------------------------------------------------------------------------

- (id)initWithPlist:(NSString *)plist andSpace:(ChipmunkSpace *)space
{
	self = [super init];
	   
	// chipmunk data
	_chipmunkObjects = [[NSMutableSet set] retain];
    _space = space;
    
    // create content
    [self createContentWithPlist:plist];
    
	// done
	return(self);
}

//------------------------------------------------------------------------------

- (void)dealloc
{
    // clean up
    [_chipmunkObjects release];
    
    // done
    [super dealloc];
}

//------------------------------------------------------------------------------

- (void)createContentWithPlist:(NSString *)plist
{
    [self removeContent];

    // load content dictionry
	NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:plist]];

    // load name and location
    _name = [[dictionary objectForKey:@"name"] retain];
    _location = [[dictionary objectForKey:@"location"] retain];
    
	// create background
	_background = [CCSprite spriteWithFile:[dictionary objectForKey:@"background"]];
    [self addChild:_background];
	
    // this defines the size of the physics area
    // upper left corner is 0,0 to match textures
    // if this size mathces one of the tetures used ( ex for iPhone non retina ), the coordinates matches the texture coordinates
    CGSize shapeSize = CGSizeFromString([dictionary objectForKey:@"shape.size"]);
    
    if ([[dictionary objectForKey:@"shape.enabled"] boolValue])
    {
        // find upper left corner of image
		CGPoint offset = CGPointMake(-shapeSize.width * 0.5f, shapeSize.height * 0.5f);
		// load shapes
		for (int index = 0; index < SnowGlobeMaxShapes; index ++) {
			NSDictionary *shapeDir = [dictionary objectForKey:[NSString stringWithFormat:@"shape.%d", index]];
			if (shapeDir)
            {
                if ([[shapeDir objectForKey:@"enabled"] boolValue])
                {
                    // load shape data and calculate position
                    CGPoint p0 = CGPointFromString([shapeDir objectForKey:@"p0"]);
                    CGPoint p1 = CGPointFromString([shapeDir objectForKey:@"p1"]);
                    p0 = CGPointMake(offset.x + p0.x, offset.y - p0.y);
                    p1 = CGPointMake(offset.x + p1.x, offset.y - p1.y);
                    // create shape
                    ChipmunkShape *shape = [ChipmunkSegmentShape segmentWithBody:[ChipmunkBody staticBody] from:p0 to:p1 radius:SnowGlobeSegmentRadius];
                    shape.elasticity = SnowGlobeSegmentElasticity;
                    shape.friction = SnowGlobeSegmentFriction;
                    
                    // set up a collision type for collision handler
                    shape.collisionType	= SnowGlobeCollisionIdContent;
                    
                    // set up the objects a shape can collide with ( always include own type )
                    // a shape will thus not collide with a disturber
                    shape.layers = SnowGlobeCollisionLayerShape | SnowGlobeCollisionLayerShowFlakes;
                    
                    // add it to chipmunk objects
                    [_chipmunkObjects addObject:shape];
                }
			}
		}
		
		// add presolve collision handling to make shapes one-way for snowflakes
		[_space addCollisionHandler:self
                              typeA:SnowGlobeCollisionIdSnowFlakes
                              typeB:SnowGlobeCollisionIdContent
                              begin:NULL
                           preSolve:@selector(presolveSnowflakeContent:space:)
                          postSolve:NULL
                           separate:NULL];
    }
}

//------------------------------------------------------------------------------
// removes current content

- (void)removeContent
{
    [_location release];
    [_name release];
    [self removeAllChildrenWithCleanup:YES];
    [_chipmunkObjects removeAllObjects];
    [_space removeCollisionHandlerForTypeA:SnowGlobeCollisionIdSnowFlakes andB:SnowGlobeCollisionIdContent];
}

//------------------------------------------------------------------------------
// called every time a snowflake collides with a content shape

- (BOOL)presolveSnowflakeContent:(cpArbiter *)arbiter space:(ChipmunkSpace *)space
{
    // get the collision normal
	CGPoint normal = cpArbiterGetNormal(arbiter, 0);
    // if snowflake collided from above, return YES to accept collision
	return(normal.y <= 0);
}

//------------------------------------------------------------------------------

@end
