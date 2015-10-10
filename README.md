vera
====

vera is a next-generation GTK+3-based Desktop Environment built for [Semplice Linux](http://semplice-linux.org).

Core concepts
-------------

Unlike other desktop environments, there is only a *core* executable and every
feature is implemented via plugins.

In detail, the vera core (i.e. this repository) contains:

* A PluginManager, needed to load plugins
* An XSETTINGS manager, based on [vera-xsettings](https://github.com/vera-desktop/vera-xsettings)
* A DBus interface to shutdown/reboot/suspend/hibernate/logout using logind with native dialogs
* A DBus interface to take screenshoots
* An autostart manager

In addition, the library (libvera), also contained here, features:

* A direct DBus interface for logind
* The plugin interface needed to create VeraPlugins
* Helper classes to talk with the graphical server (currently only X via Xlib is supported)

Settings
--------

vera uses DConf to store settings. Official plugins use the org.semplicelinux.vera.* domain
and also 3rd-party plugin makers are encouraged to do so.

The gschema shipped with this package permits to manage some features of the vera core, such as:

* Plugins
* The XSETTINGS manager (yes, you can disable it if you're nostalgic and want to use the good ol' gtkrc)
* Dreams

You can find those settings in /org/semplicelinux/vera.

Also, another gschema is shipped in the domain org.semplicelinux.vera.settings and it contains every
setting that will be exported through the XSETTINGS manager.

Building
--------

You need:

* valac (tested against vala 0.24)
* bake
* gcc
* gio-2.0
* gee-0.8
* libpeas-1.0
* gtk+-3.0
* gdk-x11-3.0
* gdk-3.0
* vera-xsettings

To compile vera, just execute

	bake

You find the result executable in ./src/vera, but you also need to install and compile the settings schemas.  
To do so, you can use the following:

	cd schemas
	sudo bake install
	sudo glib-compile-schemas /usr/share/glib-2.0/schemas

Installing
----------

Of course, you can install vera globally:

	sudo bake install # (from the top source directory)
	sudo glib-compile-schemas /usr/share/glib-2.0/schemas

