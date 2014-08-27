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
	
	[DBus (name = "org.semplicelinux.vera.Screenshot")]
	public class Screenshot : Object {
		
		/**
		 * This class exposes logind's methods to shutdown/reboot/suspend/hibernate
		 * the system.
		 * 
		 * When calling the method, a dialog is shown requiring the user
		 * to confirm its decision and - eventually - the Locks that prevent
		 * the system to properly execute the specified action.
		*/

		public DBusConnection connection = null;
		public uint? identifier = null;

		public Screenshot() {


		}
		
		[DBus (visible = false)]
		public static Screenshot start_handler() {
			/**
			 * Starts the ExitHandler.
			 * To be used internally.
			*/
			
			Screenshot handler = new Screenshot();
			
			uint identifier = Bus.own_name(
				BusType.SESSION,
				"org.semplicelinux.vera.Screenshot",
				BusNameOwnerFlags.NONE,
				(connection) => {
					// Register the object
					try {
						handler.connection = connection;
						connection.register_object("/org/semplicelinux/vera/Screenshot", handler);
					} catch (IOError e) {
						warning("Couldn't register Screenshot: %s", e.message);
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

		private void take_screenshot(Gdk.Window window) {
			/**
			 * Internally used to actually take the screenshot.
			*/
			
			int width = window.get_width();
			int height = window.get_height();
			
			Cairo.ImageSurface surface = new Cairo.ImageSurface(Cairo.Format.ARGB32, width, height);
			Gdk.Pixbuf pixbuf = Gdk.pixbuf_get_from_window(window, 0, 0, width, height);
			
			Cairo.Context cx = new Cairo.Context(surface);
			Gdk.cairo_set_source_pixbuf(cx, pixbuf, 0, 0);
			cx.paint();
			
			ScreenshotSaveDialog dialog = new ScreenshotSaveDialog();
			dialog.response.connect(
				(response_id) => {
					if (response_id == Gtk.ResponseType.ACCEPT) {
						surface.write_to_png(dialog.get_filename());
					}
					
					dialog.destroy();
				}
			);
			
			dialog.show();
		}

		
		public void Full(int delay) {
			/**
			 * Takes a screenshot of the entire desktop.
			*/
			
			Timeout.add_seconds(
				delay,
				() => {
					this.take_screenshot(Gdk.get_default_root_window());
					
					return false;
				}
			);
		
		}

		public void CurrentWindow(int delay) {
			/**
			 * Takes a screenshot of the current window.
			*/
			
			Timeout.add_seconds(
				delay,
				() => {
			
					/*
					 * We need to get the active window.
					 * Gdk provides a nice way to do this, but unfortunately
					 * is a window in Gdk's terms, without the window manager
					 * border.
					 * 
					*/
					
					Gdk.Window window;
					
					window = Gdk.Screen.get_default().get_active_window();
					
					if (unlikely(window == null) || unlikely(window.is_destroyed()) || unlikely(window.get_type_hint() == Gdk.WindowTypeHint.DESKTOP)) {
						// No active window? (or destroyed)
						window = Gdk.get_default_root_window();
					} else {
						// Destoyed?
						window = window.get_toplevel();
					}
					
					this.take_screenshot(window);
					
					return false;
				}
			);
		
		}
		
	}

}
