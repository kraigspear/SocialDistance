# SocialDistance

The New York Times recently did an article highlighting how droplets can spread with distance. As part of the article, they included a new feature in their App that using iOS Augmented Reality to judge distance. 

I wanted to see what it would take to reproduce this and other options besides Augmented Reality that could work. 

### AVFoundation

AVFoundation is the framework used to access cameras. It does allot more than snap pictures. For devices that have multiple cameras, you can access depth data. 

Similarly, to how your eyes work, with two vision detectors spaced apart, depth is calculated. 


Even though you can tell which pixels are closer / father in relation to each other, this is not an excellent way to detect the actual distance between a device and a point of interest. 

Depth-Map showing the brighter pixels as the closest, the darker as the furthest.

![DepthMap](Markdown/DepthMap.png?raw=true "Title")


### AVFoundation - CoreMotion

CoreMotion is the framework that provides information from device sensors related to the motion of the device. 

By overlaying a view on top of camera output to show distance based on the tilt of the device, we can provide an illusion of a circle encompassing six feet. 
This method might work, but without more devices, it isn't feasible to test thoroughly. 

