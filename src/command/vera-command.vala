/*
 * vera-command - simple wrapper to vera's DBus interface
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

namespace Vera.Command {

	public class Main : Object {
		/**
		 * Main class.
		*/
		
		private static Vera.VeraInterface vera_interface = null;
		
		private static string? load_plugin = null;
		private static string? unload_plugin = null;
		private static bool ninja_shortcut = false;
		private static bool poweroff = false;
		private static bool reboot = false;
		private static bool suspend = false;
		private static bool hibernate = false;
		private static bool logout = false;
		private static bool lock = false;
		private static bool switch_user = false;
		private static string? switch_user_to = null;
		private static bool switch_to_guest = false;
		
		private static bool interactive_screenshot = false;
		private static bool screenshot = false;
		private static bool window_screenshot = false;
		private static bool selection_screenshot = false;
		
		private static int screenshot_with_delay = 0;
		private static int window_screenshot_with_delay = 0;
		private static int selection_screenshot_with_delay = 0;
		
		/* Vera Interface */
		private const OptionEntry[] vera_options = {
			/* LoadPlugin */
			{ "load-plugin", 'l', 0, OptionArg.STRING, ref load_plugin, "Loads a plugin", "PLUGIN" },
			
			/* UnloadPlugin */
			{ "unload-plugin", 'u', 0, OptionArg.STRING, ref unload_plugin, "Unloads a plugin", "PLUGIN" },
			
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
			
			/* Switch user */
			{ "switch-user", 't', 0, OptionArg.NONE, ref switch_user, "Opens the Login dialog", null },
			
			/* Switch to user */
			{ "switch-to-user", 0, 0, OptionArg.STRING, ref switch_user_to, "Opens the Login dialog, hinting to the greeter the user to highlight", "USER" },
			
			/* Switch to guest */
			{ "switch-to-guest", 0, 0, OptionArg.NONE, ref switch_to_guest, "Switches to the guest user.", null },
			
			/* Interactive screenshot */
			{ "interactive-screenshot", 0, 0, OptionArg.NONE, ref interactive_screenshot, "Displays the 'Take a screenshot' window.", null },
			
			/* Screenshot */
			{ "screenshot", 'c', 0, OptionArg.NONE, ref screenshot, "Takes a screenshot", null },
			
			/* Window screenshot */
			{ "window-screenshot", 'w', 0, OptionArg.NONE, ref window_screenshot, "Takes a screenshot of the current active window", null },
			
			/* Selection screenshot */
			{ "selection-screenshot", 'e', 0, OptionArg.NONE, ref selection_screenshot, "Takes a screenshot of a selection.", null },
			
			/* Screenshot (with delay) */
			{ "screenshot-with-delay", 0, 0, OptionArg.INT, ref screenshot_with_delay, "Takes a screenshot, with delay", "DELAY" },
			
			/* Window screenshot (with delay) */
			{ "window-screenshot-with-delay", 0, 0, OptionArg.INT, ref window_screenshot_with_delay, "Takes a screenshot of the current active window, with delay", "DELAY" },
			
			/* Selection screenshot (with delay) */
			{ "selection-screenshot-with-delay", 0, 0, OptionArg.INT, ref selection_screenshot_with_delay, "Takes a screenshot of a selection, with delay", "DELAY" },
			
			// The end
			{ null }
		};
		
		public static int main(string[] args) {
			/**
			 * Hello!
			*/
			
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
			
				/* Connect to DBus */
				if (!(
					interactive_screenshot ||
					screenshot ||
					window_screenshot ||
					selection_screenshot ||
					screenshot_with_delay > 0 ||
					window_screenshot_with_delay > 0 ||
					selection_screenshot_with_delay > 0
				)) {
					vera_interface = Bus.get_proxy_sync(
						BusType.SESSION,
						"org.semplicelinux.vera",
						"/org/semplicelinux/vera"
					);
				}
								
				/* Execute action! */
				Vera.Launcher launch = null;
				if (load_plugin != null)
					vera_interface.LoadPlugin(load_plugin);
				else if (unload_plugin != null)
					vera_interface.UnloadPlugin(unload_plugin);
				else if (ninja_shortcut)
					launch = new Launcher({"vera-logout", "--ninja-shortcut"}, true);
				else if (poweroff)
					launch = new Launcher({"vera-logout", "--poweroff"}, true);
				else if (reboot)
					launch = new Launcher({"vera-logout", "--reboot"}, true);
				else if (suspend)
					launch = new Launcher({"vera-logout", "--suspend"}, true);
				else if (hibernate)
					launch = new Launcher({"vera-logout", "--hibernate"}, true);
				else if (logout)
					launch = new Launcher({"vera-logout", "--logout"}, true);
				else if (lock)
					launch = new Launcher({"vera-logout", "--lock"}, true);
				else if (switch_user)
					vera_interface.SwitchUser();
				else if (switch_user_to != null)
					vera_interface.SwitchUserTo(switch_user_to);
				else if (switch_to_guest)
					vera_interface.SwitchToGuest();
				else if (interactive_screenshot)
					launch = new Launcher({"vera-screenshot", "--interactive-screenshot"}, true);
				else if (screenshot)
					launch = new Launcher({"vera-screenshot", "--screenshot"}, true);
				else if (window_screenshot)
					launch = new Launcher({"vera-screenshot", "--window-screenshot"}, true);
				else if (selection_screenshot)
					launch = new Launcher({"vera-screenshot", "--selection-screenshot"}, true);
				else if (screenshot_with_delay > 0)
					launch = new Launcher({"vera-screenshot", "--screenshot-with-delay=%d".printf(screenshot_with_delay)}, true);
				else if (window_screenshot_with_delay > 0)
					launch = new Launcher({"vera-screenshot", "--window-screenshot-with-delay=%d".printf(window_screenshot_with_delay)}, true);
				else if (selection_screenshot_with_delay > 0)
					launch = new Launcher({"vera-screenshot", "--selection-screenshot-with-delay=%d".printf(selection_screenshot_with_delay)}, true);
				
				if (launch != null)
					launch.launch();
				
			} catch (Error e) {
				error(e.message);
			}
			
			return 0;
		}
	
	}

}
