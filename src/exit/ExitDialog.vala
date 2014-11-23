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
	
	public class ExitDialog : Gtk.MessageDialog {
		
		/**
		 * This is the ExitDialog, the dialog that appears when
		 * the user invokes a method on the ExitHandler D-Bus interface.
		*/
		
		private void set_details(ExitAction action) {
			/**
			 * Sets the text, secondary text and image of the ExitDialog,
			 * using appropriate values for the specified ExitAction.
			*/
			
			string title = "", text = "", secondary_text = "", icon = "";
			
			switch (action) {
				
				case ExitAction.POWEROFF:
					title = "Power off";
					text = "Do you really want to power off?";
					secondary_text = "This will close every active application.";
					icon = "system-shutdown";
					break;
				case ExitAction.REBOOT:
					title = "Restart";
					text = "Do you really want to restart?";
					secondary_text = "This will close every active application.";
					icon = "system-reboot";
					break;
				case ExitAction.SUSPEND:
					title = "Suspend";
					text = "Do you really want to suspend?";
					secondary_text = "Your active applications will not be closed.";
					icon = "system-suspend";
					break;
				case ExitAction.HIBERNATE:
					title = "Hibernate";
					text = "Do you really want to hibernate?";
					secondary_text = "Your active applications will not be closed.";
					icon = "system-hibernate";
					break;
				case ExitAction.LOGOUT:
					title = "Logout";
					text = "Do you really want to logout?";
					secondary_text = "This will close every active application.";
					icon = "system-log-out";
					break;
				case ExitAction.LOCK:
					title = "Lock";
					text = "Do you really want to lock the screen?";
					secondary_text = "The password for this temporary user is <b>live</b>.";
					icon = "system-lock-screen";
					break;
			}
			
			this.set_title(title);
			this.set_icon_name(icon);
			this.set_markup("<big>%s</big>".printf(text));
			this.format_secondary_markup(secondary_text);
			
		}
		
		public ExitDialog(ExitAction action) {
			/**
			 * Constructs the dialog.
			 * 
			 * The action parameter is the ExitAction of the action to
			 * execute.
			*/
			
			/* Initial things */
			Object(buttons: Gtk.ButtonsType.YES_NO);

			/* Set suggested action */
			this.get_widget_for_response(Gtk.ResponseType.YES).get_style_context().add_class("suggested-action");

			this.modal = true;
			
			/* Set details */
			this.set_details(action);
			
			/* Keep above */
			this.set_keep_above(true);
						
		}
		
	}
}
