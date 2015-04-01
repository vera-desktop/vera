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
	
	public enum ScreenshotAction {
		NONE,
		FULL_SCREEN,
		CURRENT_WINDOW,
		SELECTION
	}

	public class ScreenshotTakeDialog : Gtk.Dialog {
		
		/**
		 * The ScreenshotTakeDialog is the frontend for the Screenshot
		 * DBus interface.
		*/
		
		public ScreenshotAction selected_action {
			get {
				if (this.full.get_active())
					return ScreenshotAction.FULL_SCREEN;
				else if (this.active_window.get_active())
					return ScreenshotAction.CURRENT_WINDOW;
				else if (this.selection.get_active())
					return ScreenshotAction.SELECTION;
				else
					return ScreenshotAction.NONE;
			}
		}
		
		public int selected_delay {
			get {
				return (int)this.delay.get_adjustment().get_value();
			}
		}
		
		private Gtk.RadioButton full;
		private Gtk.RadioButton active_window;
		private Gtk.RadioButton selection;
		private Gtk.SpinButton delay;
		
		public ScreenshotTakeDialog() {
			/**
			 * Constructor.
			*/
			
			Object(title: _("Take a screenshot"));
						
			/* Icon */
			this.set_icon_name("applets-screenshooter");
			
			/* Settings */
			this.set_resizable(false);
			this.set_size_request(400, 250);
			this.set_keep_above(true);
			
			/* Main container */
			Gtk.Box main_container = new Gtk.Box(Gtk.Orientation.VERTICAL, 5);
			main_container.set_valign(Gtk.Align.CENTER);
			main_container.set_margin_left(5);
			main_container.set_margin_right(5);
			this.get_content_area().pack_start(main_container, true, true, 0);
			
			/* Radio buttons */
			this.full = new Gtk.RadioButton.with_label_from_widget(null, _("Full screen"));
			this.active_window = new Gtk.RadioButton.with_label_from_widget(full, _("Active window"));
			this.selection = new Gtk.RadioButton.with_label_from_widget(full, _("Selection"));
			
			/* Delay box */
			Gtk.Box delay_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
			delay_box.set_margin_left(5);
			delay_box.set_margin_right(5);
			Gtk.Label delay_label = new Gtk.Label(_("Delay"));
			delay_label.set_alignment(0, 0.50f);
			this.delay = new Gtk.SpinButton.with_range(0, 120, 1);
			delay_box.pack_start(delay_label, true, true, 0);
			delay_box.pack_start(this.delay, false, false, 0);
			
			main_container.pack_start(this.full, false, false, 0);
			main_container.pack_start(this.active_window, false, false, 0);
			main_container.pack_start(this.selection, false, false, 0);
			main_container.pack_start(delay_box, false, false, 0);
			
			/* Add buttons */
			this.add_buttons(
				_("_Cancel"),
				Gtk.ResponseType.REJECT,
				_("_Take a screenshot"),
				Gtk.ResponseType.ACCEPT,
				null
			);
			
			/* Set suggested action */
			this.get_widget_for_response(Gtk.ResponseType.ACCEPT).get_style_context().add_class("suggested-action");
			
			main_container.show_all();
		}
		
	}

}
