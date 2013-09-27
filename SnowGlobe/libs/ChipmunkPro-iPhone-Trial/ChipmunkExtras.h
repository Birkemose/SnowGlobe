// Copyright 2013 Howling Moon Software. All rights reserved.
// See http://chipmunk2d.net/legal.php for more information.

#define ChipmunkGetObject(s) s->data
#define ChipmunkGetData(s) [s->data data]

@interface ChipmunkBody (Extras)

/// Get an affine transform to match this body.
- (CGAffineTransform)affineTransform;

@end

/// Redundant API used to implement higher level functionality such as addObject.
@interface ChipmunkSpace (Extras)

/// Add a body to the space. Normally you would simply use ChipmunkSpace.add:.
- (ChipmunkBody *)addBody:(ChipmunkBody *)obj;
/// Remove a body to the space. Normally you would simply use ChipmunkSpace.remove:.
- (ChipmunkBody *)removeBody:(ChipmunkBody *)obj;

/// Add a shape to the space. Normally you would simply use ChipmunkSpace.add:.
- (ChipmunkShape *)addShape:(ChipmunkShape *)obj;
/// Remove a shape to the space. Normally you would simply use ChipmunkSpace.remove:.
- (ChipmunkShape *)removeShape:(ChipmunkShape *)obj;

/// Add a static shape to the space. Normally you would simply create a static shape use ChipmunkSpace.add:.
- (ChipmunkShape *)addStaticShape:(ChipmunkShape *)obj;
/// Remove a static shape to the space. Normally you would simply create a static shape use ChipmunkSpace.remove:.
- (ChipmunkShape *)removeStaticShape:(ChipmunkShape *)obj;

/// Add a constraint to the space. Normally you would simply use ChipmunkSpace.add:.
- (ChipmunkConstraint *)addConstraint:(ChipmunkConstraint *)obj;
/// Remove a constraint to the space. Normally you would simply use ChipmunkSpace.remove:.
- (ChipmunkConstraint *)removeConstraint:(ChipmunkConstraint *)obj;

@end
