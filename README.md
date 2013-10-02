SnowGlobe
=========
This snowglobe app, demonstrates the power of cocos2d and chipmunk2d.

As you will find out, this snow globe demo, is easily the most realistic you can find. 
It uses chipmunk2d to simulate what seems to be a very complex environment. To simulate this, it uses three kinds of snow flakes

1) 
Normal round and very light snow flakes. These are by far the majority of the snow flakes.
2)
Very light snow flakes like 1), but square.
To keep the collision calculations fast, the majority of the snow flakes are spheres. This however, results in all snowflakes rolling off obstacles.
To keep some of the snow flakes laying on obstacles, a small percentage of the snow flakes are square
3)
Very heavy snow flakes
An even lower pertentage of the snow flakes are much heavier than the rest of the snow flakes. 250 times.
This means that these snow flakes will plow through any other snow flake, and create an impression of currents in the liquid.


This version uses the "old" obj-c chipmunk2d, which is a payed tool. Worth the money though.
As soon as the new free version is out, I will update this demo to use it.

/Birkemose
