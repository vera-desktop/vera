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

const string GETTEXT_PACKAGE = "vera";

namespace Vera {
		
	public class Main : Object {
		
		/* Final exit code */
		public static int exit_code = 0;
		
		/* Final exit action */
		public static ExitAction exit_action = ExitAction.NONE;
		
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
		
		/* DBus service */
		private DBusService service;
		
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
		
		private bool has_touchpad() {
			/**
			 * Returns true if the machine has a touchpad,
			 * false otherwise.
			*/
			
			try {
				File file = File.new_for_path("/proc/bus/input/devices");
				
				DataInputStream dat = new DataInputStream(file.read());
				
				string line;
				while ((line = dat.read_line(null)) != null) {
					if ("touchpad" in line.down())
						return true;
				}
			} catch (Error e) {}
			
			return false;
			
		}
		
		private void on_idle_timeout_changed() {
			/**
			 * Fired when the idle-timeout setting has been changed.
			*/
			
			this.display.set_idle_timeout(
				this.settings.get_int("idle-timeout") * 60
			);
			
		}
				
				
		public Main() {
			/**
			 * Main() is the main class of the Vera desktop enviroment.
			 * From here everything will start.
			*/

			/* Set XDG_CURRENT_DESKTOP, if it's not already set */
			if (Environment.get_variable("XDG_CURRENT_DESKTOP") == null)
				Environment.set_variable("XDG_CURRENT_DESKTOP", "Vera", true);
			
			/* Set XDG menu prefix */
			Environment.set_variable("XDG_MENU_PREFIX", "vera-", true);

			/* Cursor (before the WM kicks in) */
			Gdk.get_default_root_window().set_cursor(new Gdk.Cursor(Gdk.CursorType.LEFT_PTR));
			
			/* Check for touchpads and, if any, configure tap */
			if (has_touchpad()) {
				
				new Launcher(
					{
						"synclient",
						"TapButton1=1",
						"TapButton2=2",
						"TapButton3=3",
						"VertTwoFingerScroll=1",
						"HorizTwoFingerScroll=1",
						"VertEdgeScroll=1"
					},
					true /* sync */
				).launch();
			
			}

			// Connect to server
			this.display.open();
						
			// Settings
			this.settings = new Settings("org.semplicelinux.vera");
			
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
				this.plugin_manager = new PluginManager(this.display, this.settings, plugins);
				this.plugin_manager.load_all_plugins();
			} else {
				message("plugins are disabled, vera will be a bit useless.");
			}

			/* XCURSOR_THEME env variable */
			if (this.xsettings_manager != null)
				Environment.set_variable("XCURSOR_THEME", this.xsettings_manager.get_cursor_theme(), true);
			
			/* Idle timeout (disabled until we replace xscreensaver) */
			//this.settings.changed["idle-timeout"].connect(this.on_idle_timeout_changed);
			//this.on_idle_timeout_changed();

			/* Start DBus service */
			this.service = DBusService.start_handler(this.plugin_manager, this.settings, this.display);
				
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
		
		public void quit() {
			/**
			 * Cleanup
			*/
			
			message("Cleanup...");
			
			try {
				/* Quit the org.semplicelinux.vera DBus service */
				this.service.quit();
			} catch (Error e) {
			}
			
			/* Execute the shutdown operation (PowerOff, Reboot, Terminate) */
			this.service.execute_action(exit_action);
		}

		private static void pre_quit(int exit) {
			/**
			 * Stops the main loop, and stores the exit_code so that
			 * we are able to properly return it after cleanup.
			*/
			
			exit_code = exit;
			
			Gtk.main_quit();
		}
		
		public static int main(string[] args) {
			/**
			 * This is the main entrypoint for Vera.
			*/
			
			/* Translations */
			Intl.setlocale(LocaleCategory.MESSAGES, "");
			Intl.textdomain(GETTEXT_PACKAGE); 
			Intl.bind_textdomain_codeset(GETTEXT_PACKAGE, "utf-8"); 
			
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

			/* Handle posix signals */
			Posix.signal(Posix.SIGQUIT, pre_quit);
			Posix.signal(Posix.SIGTERM, pre_quit);
			Posix.signal(Posix.SIGINT, pre_quit);

			Main vera = new Main();
			
			Gtk.main();
			
			/* When we are here, we need to do some cleanup... */
			vera.quit();
			
			return exit_code;

		}
		
	}

}


