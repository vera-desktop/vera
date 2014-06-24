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
	
	public class Main : Object {
		
		// Display
		public Display display = new XlibDisplay();
		
		// XSETTINGS manager
		private XsettingsManager xsettings_manager = null;
		
		// Plugin manager
		private PluginManager plugin_manager = null;
		
		// Autostart manager
		private AutostartManager autostart_manager = null;
	
		// Settings
		private Settings settings;
		
		private void do_startup(StartupPhase phase) {
			/**
			 * Convenience method to get plugins and internal vera core
			 * sections (e.g. autostart) doing the same thing with
			 * only a call.
			*/
			
			if (this.plugin_manager != null)
				this.plugin_manager.startup_all_plugins(phase);
			
			if (this.autostart_manager != null)
				this.autostart_manager.startup(phase);
			
		}
				
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
				this.xsettings_manager = new XsettingsManager((XlibDisplay)this.display);
			} else {
				warning("xsettings manager is disabled, you need to configure toolkit settings yourself.");
			}
			
			// Should we handle autostart?
			if (this.settings.get_boolean("enable-autostart")) {
				this.autostart_manager = new AutostartManager();
			} else {
				warning("Autostart manager not started, as requested.");
			}
			
			// Should we enable plugins?
			if (this.settings.get_boolean("enable-plugins")) {
				// Yes!
				this.plugin_manager = new PluginManager(this.display, this.settings);
				this.plugin_manager.load_all_plugins();
			} else {
				warning("plugins are disabled, vera will be a bit useless.");
			}

				
			// INIT
			this.do_startup(StartupPhase.INIT);
			
			// WM
			this.do_startup(StartupPhase.WM);
			
			// DESKTOP
			this.do_startup(StartupPhase.DESKTOP);
			
			// PANEL
			this.do_startup(StartupPhase.PANEL);
			
			// OTHER
			this.do_startup(StartupPhase.OTHER);
			
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


