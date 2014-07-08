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
		
		/*
		 * Command-line arguments
		*/
		
		private static bool enable_autostart = false;
		private static bool disable_autostart = false;
		[CCode (array_length = false, array_null_terminated = true)]
		private static string[] plugins = null;
		
		private const OptionEntry[] options = {
			/* Enable autostart */
			{ "enable-autostart", 0, 0, OptionArg.NONE, ref enable_autostart, "Autostart applications", null },
			
			/* Disable autostart */
			{ "disable-autostart", 0, 0, OptionArg.NONE, ref disable_autostart, "Do not autostart applications", null },
			
			/* Plugins */
			{ "plugins", 'p', 0, OptionArg.STRING_ARRAY, ref plugins, "Plugins to launch (will override dconf)", "PLUGINS" },
			
			/* The end */
			{ null }
		};
		
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
				message("xsettings manager is disabled, you need to configure toolkit settings yourself.");
			}
			
			// Should we handle autostart?
			if (enable_autostart || (this.settings.get_boolean("enable-autostart") && !disable_autostart)) {
				this.autostart_manager = new AutostartManager(this.settings);
			} else {
				message("Autostart manager not started, as requested.");
			}
			
			// Should we enable plugins?
			if (this.settings.get_boolean("enable-plugins")) {
				// Yes!
				foreach (string plug in plugins) {
					message(plug);
				}
				this.plugin_manager = new PluginManager(this.display, this.settings, plugins);
				this.plugin_manager.load_all_plugins();
			} else {
				message("plugins are disabled, vera will be a bit useless.");
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
		
		
		public static int main(string[] args) {
			/**
			 * This is the main entrypoint for Vera.
			*/
			
			Gtk.init(ref args);

			/* Parse arguments */
			try {
				OptionContext optcontext = new OptionContext("- Next generation DE written for Semplice Linux.");
				optcontext.set_help_enabled(true);
				optcontext.set_ignore_unknown_options(false);
				optcontext.add_main_entries(options, null);
				optcontext.add_group(Gtk.get_option_group(true));
				
				optcontext.parse(ref args);
			} catch (OptionError e) {
				stdout.printf("error: %s\n", e.message);
				stdout.puts("Use the -h switch to see the full list of available command line arguments.\n");
				return 1;
			}
			
			/*
			 * If both enable_autostart and disable_autostart are true,
			 * prefer disable_autostart.
			 * We need to do this so vera-session can be sure to not
			 * autostart again applications if we crash.
			*/
			
			if (enable_autostart && disable_autostart)
				enable_autostart = false;
			
			Main vera = new Main();
			
			Gtk.main();
			return 0;

		}
		
	}

}


