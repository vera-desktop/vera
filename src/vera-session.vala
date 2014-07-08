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

const uint MAX_TRIES = 10;

string[] concatenate(string[] array1, string[] array2) {
	/**
	 * Concatenates the two given string arrays.
	 * 
	 * Hey, THIS IS UGLY!
	*/
	
	string[] result = new string[0];
	
	foreach (string item in array1) {
		result += item;
	}
	
	foreach (string item in array2) {
		result += item;
	}
	
	return result;
}

int start(string[] args, uint count) {
	/**
	 * Actually do the startup.
	*/
	
	string HOME = Environment.get_home_dir();
	int status;
	
	try {
		Process.spawn_sync(
			HOME,
			concatenate({ "dbus-launch", "--exit-with-session", "vera" }, args[1:args.length]),
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
		
		/*
		 * We will only restart vera a limited number of times.
		 * This is to avoid infinite loops when e.g. a plugin is buggy
		 * and will crash vera everytime it's loaded.
		*/
		
		if (count == MAX_TRIES) {
			/*
			 * We should probably insert a nice crash dialog like
			 * the one present in linstaller.
			*/
			
			warning("vera has been restarted %u times, which is the maximum. Exiting...", MAX_TRIES);
			return status;
		}
		
		string[] new_args = args;
		
		if (!("--disable-autostart" in args)) {
			
			/* 
			 * We have probably already autostarted the applications,
			 * so we append --disable-autostart now so that they
			 * will not be started another time.
			*/
			
			new_args += "--disable-autostart";
		}
		
		message("vera crashed, restarting...");
		return start(new_args, count+1);
	} else {
		return status;
	}
	
}

int main(string[] args) {
	/**
	 * Hey!
	*/
	
	return start(args, 0);

}
