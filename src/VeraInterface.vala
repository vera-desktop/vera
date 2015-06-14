/*
 * vera - a simple, lightweight, GTK3 based desktop environment
 * Copyright (C) 2014-2015  Eugenio "g7" Paolantonio and the Semplice Project
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

/* This Interface is used by separate binaries to talk to vera's DBus interface */

namespace Vera {

	[DBus (name = "org.semplicelinux.vera")]
	public interface VeraInterface : Object {
		/**
		 * Main interface to org.semplicelinux.vera.
		*/
		
		public abstract void UnloadPlugin(string name) throws IOError;
		public abstract void LoadPlugin(string name) throws IOError;
		public abstract void NinjaShortcut() throws IOError;
		public abstract void PowerOff() throws IOError;
		public abstract void Reboot() throws IOError;
		public abstract void Suspend() throws IOError;
		public abstract void Hibernate() throws IOError;
		public abstract void Logout() throws IOError;
		public abstract void Lock() throws IOError;
		public abstract void SwitchUser() throws IOError;
		public abstract void SwitchUserTo(string user) throws IOError;
		public abstract void SwitchToGuest() throws IOError;
		
	}

}
