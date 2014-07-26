/*
 * vera - a simple, lightweight, GTK3 based desktop environment
 * Copyright (C) 2014  Eugenio "g7" Paolantonio and the Semplice Project
 * 
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 * 
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 * 
 * Authors:
 *    Eugenio "g7" Paolantonio <me@medesimo.eu>
*/

/*
 * TODO:
 * - Clean-up things
 * - Moar comments please
*/

namespace Vera {

    public class XlibDisplay : Object, Display {
	/**
	 * This class talks to the X server via the xcb
	 * library.
	*/
			
	public DisplayServer server_type {
	    get {
		    return DisplayServer.XLIB;
	    }
	}
	
	private weak Gdk.Display gdk_display;
	private weak Gdk.Screen screen;
	public Gdk.Window root_window;
	private Gdk.X11.Window x11_root_window;
	public weak X.Display display;
	public weak X.Window xrootwindow;
	private weak X.Screen xscreen;
		
	public XlibDisplay() {
	    
	    // Get default gdk display
	    this.gdk_display = Gdk.Display.get_default();
	    
	    // Get default xdisplay
	    this.display = Gdk.X11.get_default_xdisplay();
	    //message(display.number_of_screens().to_string());
	    
	    // Get rootwindow
	    this.root_window = Gdk.get_default_root_window();
	    
	    this.xrootwindow = this.display.root_window(0);
	    
	    // And set x11_root_window!
	    this.x11_root_window = (Gdk.X11.Window)this.root_window;
	}
		
	public void open() {
	    /**
	     * Opens the connection.
	    */

	}
		
	public void close() {
	    /**
	     * Closes the connection.
	    */
	
	}
	

        public new void send_to_root_window(Gdk.EventButton evnt) {
	    /**
	     * Forwards the Gdk.EventButton evnt to the root window.
	     * Adapted from xfdesktop.
	    */
	    
	    X.ButtonEvent xev = X.ButtonEvent();
	    X.ButtonEvent xev2 = X.ButtonEvent();

	    X.Event tev = X.Event();
	    X.Event tev2 = X.Event();

	    if (evnt.type == Gdk.EventType.BUTTON_PRESS || evnt.type == Gdk.EventType.BUTTON_RELEASE) {
		if (evnt.type == Gdk.EventType.BUTTON_PRESS) {
		    xev.type = X.EventType.ButtonPress;
		    // for rox, the famous "blackbox_hack"
		    display.ungrab_pointer((int)evnt.time);
		} else {
		    xev.type = X.EventType.ButtonRelease;
		}

		xev.button = (int)evnt.button;
		xev.x = (int)evnt.x; // for icewm
		xev.y = (int)evnt.y;
		xev.x_root = (int)evnt.x_root;
		xev.y_root = (int)evnt.y_root;
		xev.state = (int)evnt.state;

		xev2.type = 0;
	    /*
	    } else if (evnt_type == Gdk.EventType.SCROLL) {
		xev.type = X.EventType.ButtonPress;
		xev.button = evnt.scroll.direction + 4;
		xev.x = (int)evnt.scroll.x; // for icewm
		xev.y = (int)evnt.scroll.y;
		xev.x_root = (int)evnt.scroll.x_root;
		xev.y_root = (int)evnt.scroll.y_root;
		xev.state = (int)evnt.scroll.state;

		xev2.type = X.EventType.ButtonRelease;
		xev2.button = xev.button;
	    */
	    } else {
		return;
	    }

	    //xev.window = Gdk.X11.Window.get_xid(this.root_window);
	    xev.window = this.x11_root_window.get_xid();
	    //xev.root = xev.window;
	    //xev.subwindow = null;
	    xev.time = evnt.time;
	    xev.same_screen = true;

	    tev.xbutton = xev;

	    display.send_event(
		xev.window,
		false,
		X.EventMask.ButtonPressMask | X.EventMask.ButtonReleaseMask,
		ref tev
	    );

	    if (xev2.type == 0)
		return;

	    // Button release for scroll event
	    xev2.window = xev.window;
	    //xev2.root = xev.root;
	    xev2.subwindow = xev.subwindow;
	    xev2.time = xev.time;
	    xev2.x = xev.x;
	    xev2.y = xev.y;
	    xev2.x_root = xev.x_root;
	    xev2.y_root = xev.y_root;
	    xev2.state = xev.state;
	    xev2.same_screen = xev.same_screen;

	    tev2.xbutton = xev2;

	    display.send_event(
		xev2.window,
		false,
		X.EventMask.ButtonPressMask | X.EventMask.ButtonReleaseMask,
		ref tev2
	    );

	}
    }
}
