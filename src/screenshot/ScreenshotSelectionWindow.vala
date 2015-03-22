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

	public class SelectionArea : Gtk.DrawingArea {
		
		/**
		 * This is the main SelectionArea that permits to select the
		 * area to get.
		*/
		
		private signal void selection_changed();
		public signal void selection_finished();
		public signal void selection_aborted();
		
		private Gdk.RGBA vera_color = Gdk.RGBA() { red = 0, green = 0, blue = 0 };
		
		private Gdk.Window root_window;
		private int width;
		private int height;
		
		private Gdk.Pixbuf background;
		
		private Gdk.Point? start = null;
		private Gdk.Point? end = null;

		public Gdk.Point selection_source {
			get {
				/* selection_source is a new Gdk.Point containing the
				 * source of the selection */
				
				if (this.start == null || this.end == null) {
					return Gdk.Point() { x = 0, y = 0 };
				}
								
				/* end may be now lower than start and we should
				 * handle it to avoid catching the wrong area */
				Gdk.Point result = Gdk.Point();
				result.x = (this.start.x < this.end.x) ? this.start.x : this.end.x;
				result.y = (this.start.y < this.end.y) ? this.start.y : this.end.y;
				
				return result;
			}
		}
		public int selection_width { get; private set; }
		public int selection_height { get; private set; }
		
		private bool on_key_press_event(Gdk.EventKey event) {
			/**
			 * Fired when the user presses a key.
			*/
						
			if (event.keyval == Gdk.Key.Escape) {
				/* User pressed Escape, aborting... */
				this.selection_aborted();
			}
			
			return true;
		}
		
		private bool on_button_press_event(Gdk.EventButton event) {
			/**
			 * Fired when the user clicks on the selection area.
			*/
			
			this.start = Gdk.Point() { x = (int)event.x, y = (int)event.y };
			this.end = this.start;
			
			this.selection_changed();
			
			return true;
		}
		
		private bool on_motion_notify_event(Gdk.EventMotion event) {
			/**
			 * Fired when the user moves the mouse.
			*/
			
			this.end = Gdk.Point() { x = (int)event.x, y = (int)event.y };
			
			this.selection_changed();
			
			return true;
		}
		
		private bool on_button_release_event(Gdk.EventButton event) {
			/**
			 * Fired when the user releases the mouse button.
			*/
			
			if (
				this.selection_width == 0 ||
				this.selection_height == 0 ||
				this.start == this.end
			) {
				this.selection_aborted();
			} else {
				this.selection_finished();
			}
			
			return true;
		}
		
		private void on_selection_changed() {
			/**
			 * Fired when the selection changed.
			*/
			
			this.selection_width = this.get_width_from_points().abs();
			this.selection_height = this.get_height_from_points().abs();
						
			this.queue_draw();
		}
		
		private bool on_draw(Cairo.Context cx) {
			/**
			 * Fired when we should (re)draw the widget.
			*/
			
			Gdk.cairo_set_source_pixbuf(cx, this.background, 0, 0);
			cx.paint();
							
			Cairo.Surface mask = new Cairo.Surface.similar(
				cx.get_target(),
				Cairo.Content.COLOR_ALPHA,
				this.width,
				this.height
			);
			
			Cairo.Context mask_cx = new Cairo.Context(mask);
			mask_cx.set_source_rgba(this.vera_color.red, this.vera_color.green, this.vera_color.blue, 0.5);
			mask_cx.paint();
			mask_cx.set_operator(Cairo.Operator.CLEAR);
			mask_cx.rectangle(
				(this.start != null) ? this.start.x : 0,
				(this.start != null) ? this.start.y : 0,
				this.get_width_from_points(),
				this.get_height_from_points()
			);
			mask_cx.fill();
				
			cx.set_source_surface(mask, 0, 0);
			cx.paint();
			
			return true;
		}
		
		private int get_width_from_points() {
			/**
			 * Returns the width from the start and end points.
			 * 
			 * The return value MAY be negative, so ensure you get the
			 * absolute value if you need to use it for cropping.
			*/
			
			if (!(this.start != null || this.end != null))
				return 0;
			
			return (this.end.x - this.start.x);
		}
		
		private int get_height_from_points() {
			/**
			 * Returns the height from the start and end points.
			 * 
			 * The return value MAY be negative, so ensure you get the
			 * absolute value if you need to use it for cropping.
			*/
			
			if (!(this.start != null || this.end != null))
				return 0;
			
			return (this.end.y - this.start.y);
		}
		
		public SelectionArea(Gdk.Window root_window, int width, int height) {
			
			Object();
			
			this.root_window = root_window;
			this.width = width;
			this.height = height;
			
			if ("org.semplicelinux.vera.desktop" in Settings.list_schemas()) {
				this.vera_color.parse(new Settings("org.semplicelinux.vera.desktop").get_string("vera-color"));
			}
			
			/* Obtain background pixbuf */
			this.background = Gdk.pixbuf_get_from_window(
				this.root_window,
				0,
				0,
				this.width,
				this.height
			);
			
			this.add_events(
				Gdk.EventMask.KEY_PRESS_MASK |
				Gdk.EventMask.BUTTON_PRESS_MASK |
				Gdk.EventMask.BUTTON1_MOTION_MASK |
				Gdk.EventMask.BUTTON_RELEASE_MASK
			);
			this.set_can_focus(true);
			
			this.realize.connect(
				() => {
					this.get_window().set_cursor(
						new Gdk.Cursor(Gdk.CursorType.CROSSHAIR)
					);
				}
			);
			
			this.draw.connect(this.on_draw);
			this.selection_changed.connect(this.on_selection_changed);
			this.key_press_event.connect(this.on_key_press_event);
			this.button_press_event.connect(this.on_button_press_event);
			this.motion_notify_event.connect(this.on_motion_notify_event);
			this.button_release_event.connect(this.on_button_release_event);
			
			this.show();
		}
		
	}
					

	public class ScreenshotSelectionWindow : Gtk.Window {
		
		/**
		 * The ScreenshotSelectionWindow is the window that lets the user
		 * do a screenshot from a selection.
		*/
		
		public SelectionArea selection_area { get; private set; }
		
		private Gdk.Window root_window;
		private int width;
		private int height;
		
		public ScreenshotSelectionWindow() {
			/**
			 * Constructor.
			*/
			
			Object(title: _("Selection"));
						
			this.root_window = Gdk.Screen.get_default().get_root_window();
			this.width = this.root_window.get_width();
			this.height = this.root_window.get_height();

			this.selection_area = new SelectionArea(this.root_window, this.width, this.height);
			this.selection_area.grab_focus();
			this.selection_area.selection_finished.connect(() => { this.hide(); });
			this.selection_area.selection_aborted.connect(() => { this.hide(); });
	
			/* Icon */
			this.set_icon_name("applets-screenshooter");
			
			/* Some settings */
			this.fullscreen();
			this.set_keep_above(true);
			this.set_app_paintable(true);
			
			/* Enforce width and height and position */
			this.set_size_request(width, height);
			this.move(0, 0);

			/* Add SelectionArea */
			this.add(this.selection_area);

		}
		
	}

}
