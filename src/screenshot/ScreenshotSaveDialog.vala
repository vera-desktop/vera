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

	public class ScreenshotSaveDialog : Gtk.FileChooserDialog {
		
		/**
		 * The ScreenshotSaveDialog is the dialog that prompts the user
		 * to save the newly taken screenshot.
		*/
		
		public ScreenshotSaveDialog(Settings settings) {
			/**
			 * Constructor.
			*/
			
			Object(title: _("Save screenshot..."), parent: null, action: Gtk.FileChooserAction.SAVE);
						
			/* Icon */
			this.set_icon_name("applets-screenshooter");
			
			/* Defaults */
			DateTime dt = new DateTime.now_local();
			this.set_current_name("screenshot_%s.png".printf(dt.format("%F-%T")));
			this.set_do_overwrite_confirmation(true);
			this.set_keep_above(true);
			
			/* Default folder */
			string current_folder = settings.get_string("last-screenshot-directory");
			if (current_folder != "")
				this.set_current_folder(current_folder);
			
			/* Add filters */
			Gtk.FileFilter png = new Gtk.FileFilter();
			png.set_filter_name(_("PNG image"));
			png.add_pattern("*.png");
			this.add_filter(png);
			
			Gtk.FileFilter all = new Gtk.FileFilter();
			all.set_filter_name(_("All files"));
			all.add_pattern("*");
			this.add_filter(all);
			
			/* Add buttons */
			this.add_buttons(
				_("_Cancel"),
				Gtk.ResponseType.REJECT,
				_("_Save"),
				Gtk.ResponseType.ACCEPT,
				null
			);

			/* Set suggested action */
			this.get_widget_for_response(Gtk.ResponseType.ACCEPT).get_style_context().add_class("suggested-action");


		}
		
	}

}
