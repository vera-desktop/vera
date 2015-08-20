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

namespace Vera.Logout {
	
	public class ExitDialog : Gtk.MessageDialog {
		
		/**
		 * This is the ExitDialog, the dialog that appears when
		 * the user invokes a method on the ExitHandler D-Bus interface.
		*/
		
		private const string YES_BUTTON_STRING = _("_Yes (in %ds)");
		
		private int countdown { get; set; }
		
		private void set_details(ExitAction action) {
			/**
			 * Sets the text, secondary text and image of the ExitDialog,
			 * using appropriate values for the specified ExitAction.
			*/
			
			string title = "", text = "", secondary_text = "", icon = "";
			
			switch (action) {
				
				case ExitAction.POWEROFF:
					title = _("Power off");
					text = _("Do you really want to power off?");
					secondary_text = _("This will close every active application.");
					icon = "system-shutdown";
					break;
				case ExitAction.REBOOT:
					title = _("Restart");
					text = _("Do you really want to restart?");
					secondary_text = _("This will close every active application.");
					icon = "system-reboot";
					break;
				case ExitAction.SUSPEND:
					title = _("Suspend");
					text = _("Do you really want to suspend?");
					secondary_text = _("Your active applications will not be closed.");
					icon = "system-suspend";
					break;
				case ExitAction.HIBERNATE:
					title = _("Hibernate");
					text = _("Do you really want to hibernate?");
					secondary_text = _("Your active applications will not be closed.");
					icon = "system-hibernate";
					break;
				case ExitAction.LOGOUT:
					title = _("Logout");
					text = _("Do you really want to logout?");
					secondary_text = _("This will close every active application.");
					icon = "system-log-out";
					break;
				case ExitAction.LOCK:
					title = _("Lock");
					text = _("Do you really want to lock the screen?");
					secondary_text = _("The password for this temporary user is <b>live</b>.");
					icon = "system-lock-screen";
					break;
			}
			
			this.set_title(title);
			this.set_icon_name(icon);
			this.set_markup("<big>%s</big>".printf(text));
			this.format_secondary_markup(secondary_text);
			
		}
		
		public ExitDialog(ExitAction action, int countdown) {
			/**
			 * Constructs the dialog.
			 * 
			 * The action parameter is the ExitAction of the action to
			 * execute.
			*/
			
			/* Initial things */
			Object();
			this.countdown = countdown;

			/* Add buttons */
			this.add_buttons(
				_("_No"),
				Gtk.ResponseType.NO,
				
				(this.countdown > 0) ?
					YES_BUTTON_STRING.printf(countdown) :
					_("_Yes"),
				Gtk.ResponseType.YES
			);
			Gtk.Button yes_button = (Gtk.Button)this.get_widget_for_response(Gtk.ResponseType.YES);

			/* Set suggested action */
			this.set_default_response(Gtk.ResponseType.YES);

			//this.modal = true;
			
			/* Set details */
			this.set_details(action);
			
			/* Add countdown */
			if (this.countdown > 0) {
				Timeout.add_seconds(
					1,
					() => {
						this.countdown -= 1;
						
						if (this.countdown == 0) {
							/* Trigger a yes response */
							this.response(Gtk.ResponseType.YES);
							
							return false;
						} else {
							/* Continue with the countdown */
							yes_button.set_label(YES_BUTTON_STRING.printf(this.countdown));
							
							return true;
						}
					}
				);
			}
			
			/* Keep above */
			this.set_keep_above(true);
			
			/* Stick */
			this.stick();
			
			/* Grab focus on the Yes button */
			yes_button.grab_focus();
		}
		
	}
}
