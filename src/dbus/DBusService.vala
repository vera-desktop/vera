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
	
	public enum ExitAction {
		
		NONE = 0,
		POWEROFF = 1,
		REBOOT = 2,
		SUSPEND = 3,
		LOGOUT = 4,
		LOCK = 5
		
	}
	
	[DBus (name = "org.semplicelinux.vera")]
	public class DBusService : Object {
		
		/**
		 * This class is the main vera DBus interface, published at
		 * org.semplicelinux.vera.
		 * 
		 * It exposes also logind's methods to shutdown/reboot/suspend/hibernate
		 * the system.
		 * 
		 * When calling a logind-bound method, a dialog is shown requiring the user
		 * to confirm its decision and - eventually - the Locks that prevent
		 * the system to properly execute the specified action.
		*/
		
		public DBusConnection connection = null;
		public uint? identifier = null;
		
		private Settings settings;
		private PluginManager plugin_manager = null;
		private logindInterface logind;
		
		public DBusService(PluginManager plugin_manager, Settings settings) {
			/**
			 * Constructs the Service.
			 * 
			 * This constructor connects to logind (via the logindInterface)
			 * so that we will be able to actually execute the logind-bound
			 * actions.
			*/
			
			this.plugin_manager = plugin_manager;
			this.settings = settings;
			
			this.logind = Bus.get_proxy_sync(
				BusType.SYSTEM,
				"org.freedesktop.login1",
				"/org/freedesktop/login1"
			);
			
		}
		
		[DBus (visible = false)]
		public static DBusService start_handler(PluginManager plugin_manager, Settings settings) {
			/**
			 * Starts the service.
			 * To be used internally.
			*/
			
			DBusService handler = new DBusService(plugin_manager, settings);
			
			uint identifier = Bus.own_name(
				BusType.SESSION,
				"org.semplicelinux.vera",
				BusNameOwnerFlags.NONE,
				(connection) => {
					// Register the object
					try {
						handler.connection = connection;
						connection.register_object("/org/semplicelinux/vera", handler);
					} catch (IOError e) {
						warning("Couldn't register ExitHandler: %s", e.message);
					}
				},
				() => {},
				(connection, name) => warning("Unable to acquire bus %s", name)
			);
			
			handler.identifier = identifier;
			
			return handler;
		}
		
		[DBus (visible = false)]
		public void quit() {
			/**
			 * Quits the service.
			*/
						
			if (this.connection == null && this.identifier == null) {
				warning("connection or identifier not specified. Please use start_handler() to start the service.");
				return;
			}
			
			this.connection.close_sync();
			Bus.unown_name(this.identifier);
		}
		
		private void store_exit_action(ExitAction action) {
			/**
			 * Stores the specified exit action as the last one.
			*/
			
			if (this.settings.get_boolean("lock-last-exit-action"))
				/* Locked */
				return;
			
			this.settings.set_enum("last-exit-action", (int)action);
			
		}
		
		public void UnloadPlugin(string name) {
			/**
			 * Unloads a plugin.
			*/
			
			if (this.plugin_manager != null)
				this.plugin_manager.unload_plugin(name);
		}
		
		public void LoadPlugin(string name) {
			/**
			 * Loads a plugin.
			*/
						
			if (this.plugin_manager != null && this.plugin_manager.load_plugin(name)) {				
				/*
				 * We also need to startup the plugin.
				 * We will send the SESSION phase.
				*/
				this.plugin_manager.startup_plugin_from_name(name, StartupPhase.SESSION);
			}
		}
		
		public void NinjaShortcut() {
			/**
			 * Executes the last stored exit action.
			*/
			
			if (!this.settings.get_boolean("ninja-shortcut"))
				/* Disabled */
				return;
			
			switch ((ExitAction)this.settings.get_enum("last-exit-action")) {
				
				case ExitAction.POWEROFF:
					this.PowerOff();
					break;
				
				case ExitAction.REBOOT:
					this.Reboot();
					break;
				
				case ExitAction.SUSPEND:
					this.Suspend();
					break;
				
				case ExitAction.LOGOUT:
					this.Logout();
					break;
				
				case ExitAction.LOCK:
					this.Lock();
					break;
					
			}
			
		}
		
		public void PowerOff() {
			/**
			 * Shutdowns the system.
			*/
			
			ExitDialog dialog = new ExitDialog(ExitAction.POWEROFF);
			
			int result = dialog.run();
			if (result == Gtk.ResponseType.YES) {
				/* Hand-off to vera */
				Main.exit_action = ExitAction.POWEROFF;
				this.store_exit_action(ExitAction.POWEROFF);
				Gtk.main_quit();
			}
			
			dialog.destroy();
		
		}
		
		public void Reboot() {
			/**
			 * Reboots the system.
			*/

			ExitDialog dialog = new ExitDialog(ExitAction.REBOOT);
			
			int result = dialog.run();
			if (result == Gtk.ResponseType.YES) {
				/* Hand-off to vera */
				Main.exit_action = ExitAction.REBOOT;
				this.store_exit_action(ExitAction.REBOOT);
				Gtk.main_quit();
			}
			
			dialog.destroy();
			
		}
		
		public void Suspend() {
			/**
			 * Suspends the system.
			*/
			
			ExitDialog dialog = new ExitDialog(ExitAction.SUSPEND);
			
			int result = dialog.run();
			if (result == Gtk.ResponseType.YES) {
				// Yes! We should suspend!
				this.store_exit_action(ExitAction.SUSPEND);
				this.logind.Suspend(true);
			}
			
			dialog.destroy();
			
		}
		
		public void Logout() {
			/**
			 * Logouts the user.
			*/

			ExitDialog dialog = new ExitDialog(ExitAction.LOGOUT);
			
			int result = dialog.run();
			if (result == Gtk.ResponseType.YES) {
				/*
				 * If we exit with status 0, we will automatically
				 * logout (vera-session will not restart us).
				 * So, we actually need to quit only the main loop,
				 * the quit() method in vera's main class will
				 * do the job.
				*/
				this.store_exit_action(ExitAction.LOGOUT);
				Gtk.main_quit();
			}
			
			dialog.destroy();
			
		}
		
		public void Lock() {
			/**
			 * Locks the user.
			*/
			
			message("Lock: nothing here, for now...");
			this.store_exit_action(ExitAction.LOCK);
			
		}

		
		[DBus (visible = false)]
		public void execute_action(ExitAction action) {
			/**
			 * Executes the specified action.
			*/
			
			switch (action) {
				
				case ExitAction.POWEROFF:
					this.logind.PowerOff(true);
					break;
				
				case ExitAction.REBOOT:
					this.logind.Reboot(true);
					break;
				
				case ExitAction.SUSPEND:
					this.logind.Suspend(true);
					break;
					
			}
			
		}
		
	}

}
