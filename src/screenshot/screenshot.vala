/*
 * vera - a simple, lightweight, GTK3 based desktop environment
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

const string GETTEXT_PACKAGE = "vera";

namespace Vera {
	
	public class Screenshot : Object {
		
		/**
		 * This applications makes screenshots.
		 * 
		 * It has an interactive frontend (Interactive()) as well
		 * as methods (Full(), Selection() and CurrentWindow()) to do
		 * the screenshot directly via DBus.
		 * 
		 * Note that for security reasons the ScreenshotSaveDialog will
		 * be always shown after taking the screenshot
		 * (i.e. it's not scriptable).
		*/

		/*
		 * Command-line arguments
		*/
		
		private static bool interactive_screenshot = false;
		private static bool full_screenshot = false;
		private static bool window_screenshot = false;
		private static bool selection_screenshot = false;

		private static int full_screenshot_with_delay = 0;
		private static int window_screenshot_with_delay = 0;
		private static int selection_screenshot_with_delay = 0;
		
		private const OptionEntry[] options = {
			/* Interactive screenshot */
			{ "interactive-screenshot", 0, 0, OptionArg.NONE, ref interactive_screenshot, "Displays the 'Take a screenshot' window.", null },
			
			/* Screenshot */
			{ "screenshot", 'c', 0, OptionArg.NONE, ref full_screenshot, "Takes a screenshot", null },
			
			/* Window screenshot */
			{ "window-screenshot", 'w', 0, OptionArg.NONE, ref window_screenshot, "Takes a screenshot of the current active window", null },
			
			/* Selection screenshot */
			{ "selection-screenshot", 'e', 0, OptionArg.NONE, ref selection_screenshot, "Takes a screenshot of a selection.", null },
			
			/* Screenshot (with delay) */
			{ "screenshot-with-delay", 0, 0, OptionArg.INT, ref full_screenshot_with_delay, "Takes a screenshot, with delay", "DELAY" },
			
			/* Window screenshot (with delay) */
			{ "window-screenshot-with-delay", 0, 0, OptionArg.INT, ref window_screenshot_with_delay, "Takes a screenshot of the current active window, with delay", "DELAY" },
			
			/* Selection screenshot (with delay) */
			{ "selection-screenshot-with-delay", 0, 0, OptionArg.INT, ref selection_screenshot_with_delay, "Takes a screenshot of a selection, with delay", "DELAY" },
			
			/* The end */
			{ null }
		};

		
		private Settings settings;

		public Screenshot() {
			/**
			 * Constructor
			*/
			
			this.settings = new Settings("org.semplicelinux.vera");
		}

		private void take_screenshot(
			Gdk.Window rootwindow,
			Gdk.Window? window = null,
			Gdk.Point? selection_source = null,
			int? selection_width = null,
			int? selection_height = null
		) {
			/**
			 * Internally used to actually take the screenshot.
			*/
			
			int width, height;
			int positionx = 0;
			int positiony = 0;
			
			if (window != null) {
				/* 
				 * CurrentWindow
				 *
				 * Unfortunately we can't use the neat way (Gdk.pixbuf_get_from_window()
				 * on the window directly) we use for the root window, as
				 * it will get correctly the screenshot of the application,
				 * but without window borders and with alpha fucked up.
				 * 
				 * Thus what we will do is simply to get the window region
				 * from the entire root window.
				 * Good pointers could be found at
				 * http://faq.pygtk.org/index.py?req=show&file=faq23.039.htp
				*/
				
				int x, y;
				
				window.get_geometry(out x, out y, out width, out height);
				
				width += x*2;
				height += y+x;
				
				window.get_root_origin(out positionx, out positiony);
			} else if (selection_source != null && selection_height != null && selection_width != null) {
				/* Selection */
				
				positionx = selection_source.x;
				positiony = selection_source.y;
				width = selection_width;
				height = selection_height;
				
			} else {
				/* Whole screen */
				
				width = rootwindow.get_width();
				height = rootwindow.get_height();
			}
			
			Cairo.ImageSurface surface = new Cairo.ImageSurface(Cairo.Format.ARGB32, width, height);
			Gdk.Pixbuf pixbuf = Gdk.pixbuf_get_from_window(
				rootwindow,
				positionx,
				positiony,
				width,
				height
			);
			
			if (pixbuf == null) {
				/* Error */
				warning("Unable to take screenshot.");
				return;
			}
			
			Cairo.Context cx = new Cairo.Context(surface);
			Gdk.cairo_set_source_pixbuf(cx, pixbuf, 0, 0);
			cx.paint();
			
			ScreenshotSaveDialog dialog = new ScreenshotSaveDialog(this.settings);
			dialog.response.connect(
				(response_id) => {
					if (response_id == Gtk.ResponseType.ACCEPT) {
						surface.write_to_png(dialog.get_filename());
						this.settings.set_string(
							"last-screenshot-directory",
							dialog.get_current_folder()
						);
					}
					
					dialog.destroy();
					Gtk.main_quit();
				}
			);
			
			dialog.show();
		}
		
		public void Interactive() {
			/**
			 * Displays the "Take a screenshot" window
			*/
			
			ScreenshotTakeDialog dialog = new ScreenshotTakeDialog();
			dialog.response.connect(
				(response_id) => {
					if (response_id == Gtk.ResponseType.ACCEPT) {
						
						Timeout.add(
							200,
							() => {
								switch (dialog.selected_action) {
									
									case ScreenshotAction.FULL_SCREEN:
										this.Full(dialog.selected_delay);
										break;
									
									case ScreenshotAction.CURRENT_WINDOW:
										this.CurrentWindow(dialog.selected_delay);
										break;
									
									case ScreenshotAction.SELECTION:
										this.Selection(dialog.selected_delay);
										break;
										
								}
								
								return false;
							}
						);
					} else {
						Gtk.main_quit();
					}
					
					dialog.destroy();
				}
			);
			
			dialog.show();
		}

		public void Selection(int delay) {
			/**
			 * Takes a screenshot from a selection.
			*/
			
			ScreenshotSelectionWindow win = new ScreenshotSelectionWindow();
			
			win.selection_area.selection_finished.connect(
				() => {
					
					/* Ensure the window is hidden */
					win.hide();
					
					Timeout.add(
						(delay == 0) ? 200 : delay * 1000,
						() => {
							this.take_screenshot(
								Gdk.Screen.get_default().get_root_window(),
								null,
								win.selection_area.selection_source,
								win.selection_area.selection_width,
								win.selection_area.selection_height
							);
							
							win.destroy();
							
							return false;
						}
					);
				}
			);
			
			win.selection_area.selection_aborted.connect(
				() => {
					win.destroy();
					Gtk.main_quit();
				}
			);
			
			win.present();
		}
		
		public void Full(int delay) {
			/**
			 * Takes a screenshot of the entire desktop.
			*/
			
			Timeout.add_seconds(
				delay,
				() => {
					this.take_screenshot(Gdk.Screen.get_default().get_root_window());
					
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
						window = null;
					} else {
						// Destoyed?
						window = window.get_toplevel();
					}
					
					this.take_screenshot(Gdk.Screen.get_default().get_root_window(), window);
					
					return false;
				}
			);
		
		}
		
		public static int main(string[] args) {
			/**
			 * Main entrypoint for vera-screenshot.
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
				optcontext.add_main_entries(options, null);
				
				optcontext.parse(ref args);
			} catch (OptionError e) {
				stdout.printf("error: %s\n", e.message);
				stdout.puts("Use the -h switch to see the full list of available command line arguments.\n");
				return 1;
			}
			
			Screenshot screenshot = new Screenshot();
			
			if (interactive_screenshot)
				screenshot.Interactive();
			else if (full_screenshot)
				screenshot.Full(0);
			else if (window_screenshot)
				screenshot.CurrentWindow(0);
			else if (selection_screenshot)
				screenshot.Selection(0);
			else if (full_screenshot_with_delay > 0)
				screenshot.Full(full_screenshot_with_delay);
			else if (window_screenshot_with_delay > 0)
				screenshot.CurrentWindow(window_screenshot_with_delay);
			else if (selection_screenshot_with_delay > 0)
				screenshot.Selection(selection_screenshot_with_delay);
			
			Gtk.main();
			
			return 0;
		}
		
	}

}
