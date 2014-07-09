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
		
		POWEROFF = 1,
		REBOOT = 2,
		SUSPEND = 3;
		
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
		
		private logindInterface logind;
		
		public DBusService() {
			/**
			 * Constructs the Service.
			 * 
			 * This constructor connects to logind (via the logindInterface)
			 * so that we will be able to actually execute the logind-bound
			 * actions.
			*/
						
			this.logind = Bus.get_proxy_sync(
				BusType.SYSTEM,
				"org.freedesktop.login1",
				"/org/freedesktop/login1"
			);
			
		}
		
		[DBus (visible = false)]
		public static void start_handler() {
			/**
			 * Starts the service.
			 * To be used internally.
			*/
			
			DBusService handler = new DBusService();
			
			Bus.own_name(
				BusType.SESSION,
				"org.semplicelinux.vera",
				BusNameOwnerFlags.NONE,
				(connection) => {
					// Register the object
					try {
						connection.register_object("/org/semplicelinux/vera", handler);
					} catch (IOError e) {
						warning("Couldn't register ExitHandler: %s", e.message);
					}
				},
				() => {},
				(connection, name) => warning("Unable to acquire bus %s", name)
			);
		}
		
		public void PowerOff() {
			/**
			 * Shutdowns the system.
			*/
			
			ExitDialog dialog = new ExitDialog(ExitAction.POWEROFF);
			
			int result = dialog.run();
			if (result == Gtk.ResponseType.YES) {
				// Yes! We should poweroff!
				this.logind.PowerOff(true);
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
				// Yes! We should suspend!
				this.logind.Reboot(true);
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
				this.logind.Suspend(true);
			}
			
			dialog.destroy();
			
		}
		
	}

}
