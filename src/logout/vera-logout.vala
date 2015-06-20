/*
 * vera-logout - graphical interface to vera's logout methods
 * Copyright (C) 2015  Eugenio "g7" Paolantonio and the Semplice Project
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

namespace Vera.Logout {

	public class Main : Object {
		/**
		 * Main class.
		*/
		
		private static Settings settings;
		
		private static Vera.VeraInterface vera_interface = null;
		
		private static bool ninja_shortcut = false;
		private static bool poweroff = false;
		private static bool reboot = false;
		private static bool suspend = false;
		private static bool hibernate = false;
		private static bool logout = false;
		private static bool lock = false;
		
		/* Vera Interface */
		private const OptionEntry[] vera_options = {
			/* Ninja Shortcut */
			{ "ninja-shortcut", 'n', 0, OptionArg.NONE, ref ninja_shortcut, "Ninja shortcut (last executed exit action)", null },
			
			/* PowerOff */
			{ "poweroff", 'p', 0, OptionArg.NONE, ref poweroff, "Power offs the system", null },
			
			/* Reboot */
			{ "reboot", 'r', 0, OptionArg.NONE, ref reboot, "Reboots the system", null },
			
			/* Suspend */
			{ "suspend", 's', 0, OptionArg.NONE, ref suspend, "Suspends the system", null },
			
			/* Hibernate */
			{ "hibernate", 'i', 0, OptionArg.NONE, ref hibernate, "Hibernates the system", null },
			
			/* Logout */
			{ "logout", 'o', 0, OptionArg.NONE, ref logout, "Logouts the user", null },
			
			/* Lock */
			{ "lock", 'k', 0, OptionArg.NONE, ref lock, "Locks the session", null },
			
			// The end
			{ null }
		};

		private static int show_dialog(ExitAction action) {
			/**
			 * Shows a dialog, and returns its ResponseType.
			*/
			
			int result;
			
			if (
				/* Force the dialog if in live mode */
				(action == ExitAction.LOCK && FileUtils.test("/etc/semplice-live-mode", FileTest.EXISTS)) ||
				((action != ExitAction.SWITCH_USER && action != ExitAction.LOCK) && !settings.get_boolean("hide-exit-window"))
			) {
				ExitDialog dialog = new ExitDialog(
					action,
					settings.get_int("exit-window-countdown")
				);
				result = dialog.run();
				dialog.destroy();
			} else {
				/* Should hide, set result to ResponseType.YES */
				result = Gtk.ResponseType.YES;
			}
			
			return result;
			
		}
		
		public static void call_vera(ExitAction action) {
			/**
			 * Calls vera through DBus to actually execute the action.
			*/
			
			switch (action) {
				
				case ExitAction.NINJA_SHORTCUT:
					vera_interface.NinjaShortcut();
					break;
				
				case ExitAction.POWEROFF:
					vera_interface.PowerOff();
					break;
				
				case ExitAction.REBOOT:
					vera_interface.Reboot();
					break;
				
				case ExitAction.SUSPEND:
					vera_interface.Suspend();
					break;
				
				case ExitAction.LOGOUT:
					vera_interface.Logout();
					break;
				
				case ExitAction.LOCK:
					vera_interface.Lock();
					break;
				
				case ExitAction.HIBERNATE:
					vera_interface.Hibernate();
					break;
					
			}
			
		}

		public static int main(string[] args) {
			/**
			 * Main entry point for vera-logout.
			*/

			/* Translations */
			Intl.setlocale(LocaleCategory.MESSAGES, "");
			Intl.textdomain(GETTEXT_PACKAGE);
			Intl.bind_textdomain_codeset(GETTEXT_PACKAGE, "utf-8");
			
			Gtk.init(ref args);

			if (args.length == 1) {
				stdout.puts("You need to specify at least an argument! See -h for more details.\n");
				return 1;
			}
			
			/*
			 * We support only one option at a time, so we need to check
			 * if this is the case.
			 * It seems that the OptionContext doesn't have an option for
			 * this, so we need to manually do the check.
			 * This is a bit tricky because there are some arguments with
			 * require an argument, so we can't do a simple 'args.length > 2'.
			*/
			bool found_one = false;
			foreach (string arg in args) {
				if (arg.has_prefix("-")) {
					if (found_one)
						error("Only an argument is permitted!");
					else
						found_one = true;
				}
			}
			
			// Parse arguments
			try {
				OptionContext optcontext = new OptionContext("");
				optcontext.set_help_enabled(true);
				optcontext.set_ignore_unknown_options(false);
				optcontext.add_main_entries(vera_options, null);
				
				optcontext.parse(ref args);
			} catch (OptionError e) {
				stdout.printf("error: %s\n", e.message);
				stdout.puts("Use the -h switch to see the full list of available command line arguments.\n");
				return 1;
			}
			
			try {
				
				/* Create Settings object */
				settings = new Settings("org.semplicelinux.vera");
			
				/* Connect to DBus */
				vera_interface = Bus.get_proxy_sync(
					BusType.SESSION,
					"org.semplicelinux.vera",
					"/org/semplicelinux/vera"
				);
								
				/* Execute action! */
				Vera.ExitAction? action = null;
				if (ninja_shortcut)
					action = Vera.ExitAction.NINJA_SHORTCUT;
				else if (poweroff)
					action = Vera.ExitAction.POWEROFF;
				else if (reboot)
					action = Vera.ExitAction.REBOOT;
				else if (suspend)
					action = Vera.ExitAction.SUSPEND;
				else if (hibernate)
					action = Vera.ExitAction.HIBERNATE;
				else if (logout)
					action = Vera.ExitAction.LOGOUT;
				else if (lock)
					action = Vera.ExitAction.LOCK;
				
				/* Show the dialog and do things */
				if (
					show_dialog(
						(action == ExitAction.NINJA_SHORTCUT) ?
							(ExitAction)settings.get_enum("last-exit-action") :
							action
					) == Gtk.ResponseType.YES
				)
					call_vera(action);
				
			} catch (Error e) {
				error(e.message);
			}
			
			/* Gtk.Dialog.run() actually calls Gtk.main() for us. */
			
			return 0;
		}
	
	}

}
