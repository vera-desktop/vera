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
	
	[DBus (name = "org.freedesktop.login1.Manager")]
	public interface logindInterface : Object {
		/**
		 * This interfaces directly talks to logind via DBus.
		*/ 
		
		public abstract void Hibernate(bool interactive) throws IOError;
		public abstract void HybridSleep(bool interactive) throws IOError;
		public abstract Variant[] ListInhibitors() throws IOError;
		public abstract void PowerOff(bool interactive) throws IOError;
		public abstract void Reboot(bool interactive) throws IOError;
		public abstract void Suspend(bool interactive) throws IOError;
		public abstract string GetSession(string id) throws IOError;
	}
	
	[DBus (name = "org.freedesktop.login1.Session")]
	public interface Session : Object {
		/**
		 * logind session.
		*/
		
		public abstract void SetIdleHint(bool hint) throws IOError;
		
		public abstract signal void Lock();
		public abstract signal void Unlock();
		
	}

}
