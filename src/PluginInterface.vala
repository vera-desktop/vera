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

using Peas;

namespace Vera {
		
	public enum StartupPhase {
		/**
		 * StartupPhase enum.
		 * The current phase will be given to all plugins during startup
		 * (VeraPlugin.startup()).
		 * 
		 * Plugins need to listen for the appropriate phase and act
		 * accordingly.
		 * 
		 * For example, a plugin implementing a panel (such as the tint2 plugin)
		 * needs to show it when the StartupPhase is PANEL.
		 * 
		 * *DO NOT* use INIT for initialization stuff. There is the method
		 * init() that will be called as soon as the plugin has been loaded.
		*/
		
		INIT, /* Initialization stuff */
		WM, /* WindowManager stuff (+ compositing managers, if any) */
		PANEL, /* Panel and other applications which permanently take desktop space */
		DESKTOP, /* Anything that draws on the desktop */
		OTHER, /* Other autostart applications */
		SESSION /* Hot load (plugin loaded via DBus) */
		
	}
	
	public interface VeraPlugin : ExtensionBase {
		/**
		 * This is the VeraPlugin interface.
		 * Currently it's very simple.
		 * 
		 * init(Display display) will be called as soon as the plugin
		 * gets loaded into vera by the PluginManager.
		 * You need to properly cast the display when needed by looking 
		 * at the server_type property.
		 * 
		 * startup(StartupPhase phase) instead will be called directly
		 * by vera during the various startup phases.
		 * See the doc of the StartupPhase enum for more informations.
		 * 
		 * shutdown() will be called as soon as the plugin gets unloaded
		 * from vera.
		*/
		
		public abstract void init(Display display) throws Error;
		public abstract void startup(StartupPhase phase);	
		public abstract void shutdown() throws Error;
	}

}
