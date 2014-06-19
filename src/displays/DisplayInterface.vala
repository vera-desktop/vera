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
namespace Vera {
	
	public enum DisplayServer {
		NONE,
		XLIB,
		//WAYLAND,
		//MIR,
	}

	public interface Display : Object {
		
		/**
		 * This is vera's display interface.
		 * You need to subclass this if you want to add support for another
		 * display servers.
		*/
		
		public abstract DisplayServer server_type {
			get {
				return DisplayServer.NONE;
			}
		}
		
		public abstract void open();
		public abstract void close();
		
		//public virtual void send_to_root_window() {}
	} 

}
