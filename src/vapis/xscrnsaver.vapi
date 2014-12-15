/*
 * xscrnsaver.vapi - basic libxss bindings for vala
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

[CCode (cprefix = "", lower_case_cprefix = "", cheader_filename="X11/extensions/scrnsaver.h")]
namespace XScreenSaver {

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
	
	[CCode (cname = "XScreenSaverQueryInfo")]
	public XScreenSaver.Info query_info(X.Display display, X.Drawable drawable);

}
