---
title: Spotify shortcut on linux
subtitle: Using dbus to map shortcuts to Spotify
description: I love Spotify, and I love my linux environment, but I didn't knew how to map shortcuts to the Spotify linux client: we can do it easily using dbus!
---

I'm using Opensuse with KDE, and I love this environnement. Also, I love to listen to my music on Spotify using the linux (beta) client, but I didn't knew how to define shortcuts to control the app.
It's actually really easy to achieve using dbus.

Ok, so first: *What is dbus?* This is the answer from the [official site](http://www.freedesktop.org/wiki/Software/dbus/):

	D-Bus is a message bus system, a simple way for applications to talk to one another.[...]

Hum, it sounds great. Now, I don't want to dive into details in this article. I just want a simple shortcut to my spotify app. How can I do? Let's see if Spotify let us call the app through dbus.

I use *qdbus* to explore my apps. Or even better, *qdbusviewer* which gives me an UI on top of *qdbus*.
In the search field, I enter "spotify" and find a package name "com.spotify.qt".

![Spotify in qdbusviewer](/img/spotify-dbus-shortcut/qdbusviewer1.png)

At this point, you will have to expore the possibilities in the right panel. And we can test it directly!
If you expand *org.freedesktop.MediaPlayer2*, you will find a list of available methods. Double-click on the one you want to test, and let the magic happen. Using *Method: PlayPause* will toggle your music for example.

![Exposed methods in qdbusviewer](/img/spotify-dbus-shortcut/qdbusviewer2.png)

Now, we just have to map it with kde shortcuts. In system *settings > shortcut > custom*, you can add a new global custom shortcut, using *dbus command*. There, in *trigger*, you define your shortcut keys, and in action its effect.
In *RemoteApplications*, specify the package name, in *Remote object*, the object at top-level of the method you want to use from qdbusviewer, and finally, in *Function*, type the method you want to use. You can see the parrallel between qdbusviewer and these settings in the two images below.

![PlayPause method, on object org.mrpis.MediaPlayer2](/img/spotify-dbus-shortcut/qdbusviewer3.png)

![KDE shortcut settings](/img/spotify-dbus-shortcut/shortcut-settings.png)

That's it!
