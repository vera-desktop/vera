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

string[] concatenate(string[] array1, string[] array2) {
	/**
	 * Concatenates the two given string arrays.
	 * 
	 * Hey, THIS IS UGLY!
	*/
	
	string[] result = new string[0];
	
	foreach (string item in array1) {
		message(item);
		result += item;
	}
	
	foreach (string item in array2) {
		message(item);
		result += item;
	}
	
	return result;
}

int main(string[] args) {
	/**
	 * dbus-launch vera.
	*/
	
	string HOME = Environment.get_home_dir();
	int status;
	
	try {
		Process.spawn_sync(
			HOME,
			concatenate({ "dbus-launch", "--exit-with-session", "vera" }, args[1:-1]),
			Environ.get(),
			SpawnFlags.SEARCH_PATH,
			null,
			null,
			null,
			out status
		);
		
	} catch (SpawnError e) {
		error(e.message);
	}
	
	if (status > 1) {
		/* Something wrong... */
		return main(args);
	} else {
		return status;
	}
	

}
