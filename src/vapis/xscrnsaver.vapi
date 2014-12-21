/*
 * xscrnsaver.vapi - libxss bindings for vala
 * Copyright (C) 2014  Eugenio "g7" Paolantonio
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

[CCode (cprefix = "", lower_case_cprefix = "", cheader_filename="X11/extensions/scrnsaver.h,X11/extensions/saver.h")]
namespace XScreenSaver {

	public enum State {
		[CCode (cname = "ScreenSaverOff")]
		OFF,
		[CCode (cname = "ScreenSaverOn")]
		ON,
		[CCode (cname = "ScreenSaverCycle")]
		CYCLE,
		[CCode (cname = "ScreenSaverDisabled")]
		DISABLED
	}
	
	[CCode (cname = "ScreenSaverNotifyMask")]
	public const int NotifyMask;
	
	[CCode (cname = "ScreenSaverCycleMask")]
	public const int CycleMask;

	[CCode (cname = "XScreenSaverNotifyEvent", destroy_function = "", has_type_id = false)]
	public struct NotifyEvent {
		
		int type;          /* of event */
		ulong serial;      /* # of the last request processed by server */
		bool send_event;   /* true if this came from a SendEvent request */
		X.Display display; /* Display this event was read from */
		X.Window window;   /* screen saver window */
		X.Window root;     /* root window of event screen */
		int state;         /* ScreenSaverOff, ScreenSaverOn, ScreenSaverCycle */
		int kind;          /* ScreenSaverBlanked, ...Internal, ...External */
		bool forced;       /* extents of new region */
		X.Time time;       /* event timestamp */
	}

	[CCode (cname = "XScreenSaverInfo", destroy_function = "", has_type_id = false)]
	public struct Info {
		
		[CCode (cname = "XScreenSaverAllocInfo")]
		public Info();
		
		X.Window window;    /* screen saver window */
		int state;          /* ScreenSaver{Off,On,Disabled} */
		int kind;           /* ScreenSaver{Blanked,Internal,External} */
		ulong til_or_since; /* milliseconds */
		ulong idle;         /* milliseconds */
		ulong eventMask;    /* events */
	}
	
	[CCode (cname = "XScreenSaverQueryExtension")]
	public bool query_extension(X.Display display, ref int event_base, ref int error_base);
	
	[CCode (cname = "XScreenSaverQueryVersion")]
	public X.Status query_version(X.Display display, ref int major_version, ref int minor_version);
	
	[CCode (cname = "XScreenSaverQueryInfo")]
	public XScreenSaver.Info query_info(X.Display display, X.Drawable drawable);
	
	[CCode (cname = "XScreenSaverSelectInput")]
	public void select_input(X.Display display, X.Drawable drawable, ulong eventMask);
	
	[CCode (cname = "XScreenSaverSetAttributes")]
	public void set_attributes(X.Display display, X.Drawable drawable, int x, int y,
	                           uint width, uint height, uint border_width, int depth,
	                           uint class, X.Visual visual, ulong valuemask,
	                           X.SetWindowAttributes attributes
	);
	
	[CCode (cname = "XScreenSaverUnsetAttributes")]
	public void unset_attributes(X.Display display, X.Drawable drawable);
	
	[CCode (cname = "XScreenSaverRegister")]
	public X.Status register(X.Display display, int screen, X.ID xid, X.Atom type);
	
	[CCode (cname = "XScreenSaverUnregister")]
	public X.Status unregister(X.Display display, int screen);
	
	[CCode (cname = "XScreenSaverGetRegistered")]
	public X.Status get_registered(X.Display display, int screen, X.ID xid, X.Atom type);
	
	[CCode (cname = "XScreenSaverSuspend")]
	public void suspend(X.Display display, bool suspend);

}
