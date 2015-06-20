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
		
		private Session session;
		private logindInterface logind;
		
		private Display display;
		
		public DBusService(PluginManager plugin_manager, Settings settings, Display display) {
			/**
			 * Constructs the Service.
			 * 
			 * This constructor connects to logind (via the logindInterface)
			 * so that we will be able to actually execute the logind-bound
			 * actions.
			*/
			
			this.plugin_manager = plugin_manager;
			this.settings = settings;
			this.display = display;
			
			this.logind = Bus.get_proxy_sync(
				BusType.SYSTEM,
				"org.freedesktop.login1",
				"/org/freedesktop/login1"
			);
			
			this.session = Bus.get_proxy_sync(
				BusType.SYSTEM,
				"org.freedesktop.login1",
				this.logind.GetSession(Environment.get_variable("XDG_SESSION_ID"))
			);
			
			/* React on idle changes */
			this.display.idle_changed.connect(this.on_display_idle_changed);
			
			/* Connect Lock signal, unlock currently not supported */
			this.session.Lock.connect(this.on_lock_request);
		}
		
		private void on_display_idle_changed(bool on) {
			/**
			 * Fired when the display idle state changed.
			*/
			
			this.session.SetIdleHint(on);
			
			/*
			 * Even if logind knows about our idle state, it will not 
			 * trigger anything unless every session have their IdleHints
			 * set to True.
			 * This is of course unwanted, and thus we will Lock the screen
			 * anyway, if the user desires so.
			*/
			
			/* This is disabled until we replace xscreensaver */
			//if (on && this.settings.get_boolean("lock-on-idle"))
			//	this.on_lock_request();
			
		}
		
		private void on_lock_request() {
			/**
			 * Fired when the user (or logind) requested to activate the
			 * screen lock.
			*/
						
			new Launcher({"xscreensaver-command", "-lock"}).launch();
			
		}
		
		[DBus (visible = false)]
		public static DBusService start_handler(PluginManager plugin_manager, Settings settings, Display display) {
			/**
			 * Starts the service.
			 * To be used internally.
			*/
			
			DBusService handler = new DBusService(plugin_manager, settings, display);
			
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
						warning("Couldn't register DBus service: %s", e.message);
					}
				},
				() => {},
				(connection, name) => error("Unable to acquire bus %s, another instance running?", name)
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
				
				case ExitAction.HIBERNATE:
					this.Hibernate();
					break;
				
				case ExitAction.LOGOUT:
					this.Logout();
					break;
				
				case ExitAction.LOCK:
					this.Lock();
					break;
				
				/* Generic switch user */
				case ExitAction.SWITCH_USER:
					this.SwitchUser();
					break;
					
			}
			
		}
			
		
		public void PowerOff() {
			/**
			 * Shutdowns the system.
			*/
			
			/* Hand-off to vera */
			Main.exit_action = ExitAction.POWEROFF;
			this.store_exit_action(ExitAction.POWEROFF);
			Gtk.main_quit();
			
		}
		
		public void Reboot() {
			/**
			 * Reboots the system.
			*/

			/* Hand-off to vera */
			Main.exit_action = ExitAction.REBOOT;
			this.store_exit_action(ExitAction.REBOOT);
			Gtk.main_quit();
			
		}
		
		public void Suspend() {
			/**
			 * Suspends the system.
			*/
			
			/* Yes! We should suspend! */
			this.store_exit_action(ExitAction.SUSPEND);
			this.logind.Suspend(true);
			
		}
		
		public void Hibernate() {
			/**
			 * Hibernates the system.
			*/
						
			/* Yeah! */
			this.store_exit_action(ExitAction.HIBERNATE);
			this.logind.Hibernate(true);
			
		}
		
		public void Logout() {
			/**
			 * Logouts the user.
			*/

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
		
		public void Lock() {
			/**
			 * Locks the user.
			*/
			
			/*
			 * A word about logind's Lock() and Unlock() methods (on the
			 * session object):
			 * They need to be executed by a privileged user (--> root),
			 * so it's not possible for the normal user lock their own
			 * session via logind.
			 * 
			 * It seems it's a missing functionality ([1]), so hopefully
			 * one day we will only call logind's method to Lock the
			 * screen which will in turn fire the Lock signal and
			 * makes vera actually lock the screen.
			 * 
			 * Currently we need to both listen to that signal and also
			 * handle our (unprivileged) DBus call.
			 * 
			 * [1] https://www.mail-archive.com/systemd-devel@lists.freedesktop.org/msg20351.html
			*/
			
			this.on_lock_request();
			this.store_exit_action(ExitAction.LOCK);
			
		}
		
		public void SwitchUser() {
			/**
			 * Switches to another user.
			*/
			
			/* FIXME: Should check if the Lock signal is fired by dm-tool */
			new Launcher({ "dm-tool", "switch-to-greeter" }).launch();
			this.store_exit_action(ExitAction.SWITCH_USER);
			
		}
		
		public void SwitchUserTo(string user) {
			/**
			 * Switches to a defined user.
			*/
			
			/* FIXME: Should check if the Lock signal is fired by dm-tool */
			new Launcher({ "dm-tool", "switch-to-user", user }).launch();
			this.store_exit_action(ExitAction.SWITCH_USER);
			
		}
		
		public void SwitchToGuest() {
			/**
			 * Switches to the guest user.
			*/
			
			/* FIXME: Should check if the Lock signal is fired by dm-tool */
			new Launcher({ "dm-tool", "switch-to-guest"}).launch();
			this.store_exit_action(ExitAction.SWITCH_USER);
			
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
				
				case ExitAction.HIBERNATE:
					this.logind.Hibernate(true);
					break;
			}
			
		}
		
	}

}
