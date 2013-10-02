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

#import "SnowGlobe.h"
#import "SnowGlobeLayer.h"

//------------------------------------------------------------------------------
// a lot of constants

const int    SnowGlobeFlakeCount                = 700;
const int    SnowGlobeFlakeBlockerCount         = 70;
const int    SnowGlobeFlakeDisturberCount       = 25;

const double SnowGlobeFlakeMass                 = 1.0f;
const double SnowGlobeFlakeDisturberMass        = 250.0f;

const double SnowGlobeFlakeSize                 = 3.0f;
const double SnowGlobeFlakeRadius               = (SnowGlobeFlakeSize / 2);
const double SnowGlobeFlakeElasticity           = 0.2f;
const double SnowGlobeFlakeFriction             = 5.1f;
const double SnowGlobeFlakeVelocityLimit        = 100.0f;

const double SnowGlobeFlakeScaleMin             = 1.00f;
const double SnowGlobeFlakeScaleMax             = 1.50f;
const double SnowGlobeFlakeTilt                 = 30.0f;
const Byte   SnowGlobeFlakeOpacity              = 220;
const int    SnowGlobeFlakeTextureCount         = 4;

const double SnowGlobeGlassRadius               = 145.0f;
const double SnowGlobeGlassThickness            = 1.0f;
const double SnowGlobeGlassFloor                = -105.0f;
const int    SnowGlobeGlassSegmentCount         = 32;
const double SnowGlobeGlassElasticity           = 0.2f;
const double SnowGlobeGlassFriction             = 1.5f;

const int    SnowGlobePosTries                  = 99;

const int    SnowGlobeCollisionGroupGlass       = 17;

const double SnowGlobeMaxShakeStrength          = 3.0f;
const double SnowGlobeShakeGain                 = 0.15f;

const Byte   SnowGlobeOverlayOpacity            = 128;

//------------------------------------------------------------------------------

@implementation SnowGlobe
{
	NSMutableSet *_chipmunkObjects;
#if SNOWGLOBE_USE_BATCHING != 0
    CCSpriteBatchNode *_batch;
#else
    CCNode *_batch;
#endif
    NSString *_name;
    NSString *_location;
}

//------------------------------------------------------------------------------

+ (SnowGlobe *)snowGlobe
{
	return([[[ self alloc] init] autorelease]);
}

//------------------------------------------------------------------------------

- (id)init
{
	self = [super init];
    
	// chipmunk data
	_chipmunkObjects = [[NSMutableSet set] retain];

	// sprite batch node
#if SNOWGLOBE_USE_BATCHING != 0
	_batch = [CCSpriteBatchNode batchNodeWithFile:@"flakes.png" capacity:SnowGlobeFlakeCount];
#else
    _batch = [CCNode node];
#endif
    [self addChild:_batch];
    
    // calculate placement scale
    _contentScale = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 2.0f : 1.0f;
	   
    // create the globe
	double angle	= 0.0f;
    CGPoint p0, p1;
    p1 = CGPointMake(0, SnowGlobeGlassRadius);
	// loop through segments
	for (int count = 1; count <= SnowGlobeGlassSegmentCount; count ++)
    {
		// calculate position
		p0 = p1;
		angle = 2 * M_PI / SnowGlobeGlassSegmentCount;
		angle *= count;
		p1.x = sinf(angle) * SnowGlobeGlassRadius;
		p1.y = cosf(angle) * SnowGlobeGlassRadius;
		// create segment shape
		ChipmunkShape *shape = [ChipmunkSegmentShape segmentWithBody:[ChipmunkBody staticBody] from:p0 to:p1 radius:SnowGlobeGlassThickness];
		shape.elasticity = SnowGlobeGlassElasticity;
		shape.friction = SnowGlobeGlassFriction;
        shape.group = SnowGlobeCollisionGroupGlass;
		shape.layers = SnowGlobeCollisionLayerAll;
        shape.collisionType = SnowGlobeCollisionIdGlass;
        // add the shape to the chipmunk objects
		[_chipmunkObjects addObject:shape];
	}
    
	// add floor
    p0 = CGPointMake(-SnowGlobeGlassRadius, SnowGlobeGlassFloor);
    p1 = CGPointMake(SnowGlobeGlassRadius, SnowGlobeGlassFloor);
	ChipmunkShape *floor = [ChipmunkSegmentShape segmentWithBody:[ChipmunkBody staticBody] from:p0 to:p1 radius:SnowGlobeGlassThickness];
	floor.elasticity = SnowGlobeGlassElasticity;
	floor.friction = SnowGlobeGlassFriction;
    floor.group = SnowGlobeCollisionGroupGlass;
	floor.layers = SnowGlobeCollisionLayerAll;
    floor.collisionType = SnowGlobeCollisionIdGlass;
    // add the floor to the chipmunk objects
	[_chipmunkObjects addObject:floor];
    
	// precalc
	double radius = SnowGlobeGlassRadius - SnowGlobeGlassThickness;
    
    // preload sprite sheet
    [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"flakes.plist"];
	
	// create snowflakes
	for (int count = 0; count < SnowGlobeFlakeCount; count ++)
    {
        CGPoint pos;
        ChipmunkBody *body;
        ChipmunkShape *shape;
        
		// find a position (brute way of creating even distribution)
        // there might be more elegant ways, but at least this one works
		for ( int count = 0; count < SnowGlobePosTries; count ++ ) {
            pos = CGPointMake(CCRANDOM_MINUS1_1() * radius, CCRANDOM_MINUS1_1() * radius);
            // break if position is inside snowglobe ( extra check for the flat floor)
            if ((ccpLength(pos) < radius) && (pos.y > (SnowGlobeGlassFloor + SnowGlobeGlassThickness))) break;
		}
        
		// create sprite
		CCSprite *flake	= [CCSprite spriteWithSpriteFrameName:[NSString stringWithFormat:@"flake.%d.png", arc4random() % SnowGlobeFlakeTextureCount]];
		flake.scale	= SnowGlobeFlakeScaleMin + (CCRANDOM_0_1() * (SnowGlobeFlakeScaleMax - SnowGlobeFlakeScaleMin));
		flake.rotation	= CCRANDOM_MINUS1_1() * SnowGlobeFlakeTilt;
		flake.opacity = SnowGlobeFlakeOpacity;
        
        // check if disturber
		BOOL isDisturber = !((count % (SnowGlobeFlakeCount / SnowGlobeFlakeDisturberCount)));
        
		// create physics
        double mass = (isDisturber) ? SnowGlobeFlakeDisturberMass : SnowGlobeFlakeMass;
        
        // create the physics
        if (count % (SnowGlobeFlakeCount / SnowGlobeFlakeBlockerCount))
        {
            body = [[ChipmunkBody alloc] initWithMass:mass andMoment:cpMomentForCircle(mass, 0, SnowGlobeFlakeRadius, CGPointZero)];
            shape = [ChipmunkCircleShape circleWithBody:body radius:SnowGlobeFlakeRadius offset:CGPointZero];
        }
        else
        {
            body = [[ChipmunkBody alloc] initWithMass:mass andMoment:cpMomentForBox(mass, SnowGlobeFlakeSize, SnowGlobeFlakeSize)];
            shape = [ChipmunkPolyShape boxWithBody:body width:SnowGlobeFlakeSize height:SnowGlobeFlakeSize];
#if SNOWGLOBE_SPECIAL_SHOW != 0
            flake.color = ccBLUE;
#endif
        }

        // set body data
        body.pos = pos;
        body.velLimit = SnowGlobeFlakeVelocityLimit;
        
        // set shape data
        shape.elasticity= SnowGlobeFlakeElasticity;
        shape.friction = SnowGlobeFlakeFriction;
        shape.group = CP_NO_GROUP;
        
        shape.layers = SnowGlobeCollisionLayerAll;
        shape.collisionType	= SnowGlobeCollisionIdSnowFlakes;
        
#if SNOWGLOBE_SPECIAL_SHOW != 0
        if (isDisturber) flake.color = ccRED;
#endif
        
        // remember physics in flake for fast access
        flake.userObject = body;
        
        // add the sprite to the batch
        [_batch addChild:flake];
        
		// add physics to chipmunk objects
		[_chipmunkObjects addObject:body];
		[_chipmunkObjects addObject:shape];
		
	}
    
    // create the glass sprite overlay
    CCSprite *overlay = [CCSprite spriteWithFile:@"snowglobe.png"];
    overlay.opacity = SnowGlobeOverlayOpacity;
	[self addChild:overlay];
    
    //
	// done
	return(self);
}

//------------------------------------------------------------------------------

- (void)updatePositions
{
	for (CCSprite *flake in _batch.children)
    {
		ChipmunkBody *body = (ChipmunkBody *)flake.userObject;
        
		// clamp the body pos to be inside globe
        if ((ccpLength(body.pos) > ( SnowGlobeGlassRadius - SnowGlobeGlassThickness)) || (body.pos.y < (SnowGlobeGlassFloor + SnowGlobeGlassThickness)))
        {
            body.pos = ccpMult(ccpNormalize(body.pos), SnowGlobeGlassRadius - SnowGlobeGlassThickness - SnowGlobeFlakeSize);
            if (body.pos.y < (SnowGlobeGlassFloor + SnowGlobeGlassThickness + SnowGlobeFlakeSize))
                body.pos = ccp(body.pos.x, SnowGlobeGlassFloor + SnowGlobeGlassThickness + SnowGlobeFlakeSize);
            body.force = CGPointZero;
        }
        
        // set position
		flake.position = ccpMult(body.pos, _contentScale);
	}
}

//------------------------------------------------------------------------------

- (void)shake:(CGPoint)pos strength:(double)strength
{
    strength = clampf(strength, -SnowGlobeMaxShakeStrength, SnowGlobeMaxShakeStrength);
	for (CCSprite *flake in _batch.children)
    {
		ChipmunkBody *body = (ChipmunkBody *)flake.userObject;
        CGPoint force = ccpSub( pos, body.pos);
        force = ccpMult( force, SnowGlobeShakeGain * CCRANDOM_MINUS1_1() * body.mass * strength );
        //
        [body applyImpulse:force offset:CGPointZero];
	}
}

//------------------------------------------------------------------------------

@end
