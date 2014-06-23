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
	
	public class Main : GLib.Object {
		
		public Display display = new XlibDisplay();
		
		private XsettingsManager xsettingsmanager;
		
		private Settings settings;
				
		public Main() {
			/**
			 * Main() is the main class of the Vera desktop enviroment.
			 * From here everything will start.
			*/
			
			// Connect to server
			this.display.open();
			
			// Settings
			this.settings = new Settings("org.semplicelinux.vera");
			
			// Start ExitHandler
			ExitHandler.start_handler();
			
			// Should we start the screenshooter?
			if (this.settings.get_boolean("enable-screenshot")) {
				Screenshot.start_handler();
			} else {
				message("Internal screenshooter not started, as requested.");
			}
			
			// Should we start the XsettingsManager?
			if (this.settings.get_boolean("enable-xsettings")) {
				this.xsettingsmanager = new XsettingsManager((XlibDisplay)this.display);
			} else {
				warning("xsettings manager is disabled, you need to configure toolkit settings yourself.");
			}
			
			// Should we enable plugins?
			if (this.settings.get_boolean("enable-plugins")) {
				
				PluginManager manager = new PluginManager(this.display, this.settings);
				manager.load_all_plugins();
				
				// INIT
				manager.startup_all_plugins(StartupPhase.INIT);
				
				// WM
				manager.startup_all_plugins(StartupPhase.WM);
				
				// DESKTOP
				manager.startup_all_plugins(StartupPhase.DESKTOP);
				
				// PANEL
				manager.startup_all_plugins(StartupPhase.PANEL);
				
				// OTHER
				manager.startup_all_plugins(StartupPhase.OTHER);
			} else {
				warning("plugins are disabled, vera will be a bit useless.");
			}
			
			
			message("Vera initialized.");
		}
		
	}

	int main(string[] args) {
		/**
		 * This is the main entrypoint for Vera.
		*/
		
		Gtk.init(ref args);
		
		Main vera = new Main();
		
		Gtk.main();
		return 0;

	}

}


