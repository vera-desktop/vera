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

	public errordomain LauncherError {
		ARRAY_ERROR
	}

	public class Launcher : Object {
		/**
		 * Useful methods to launch up things.
		 * (With startup notifications, yay!
		*/
		
		public signal void terminated (Pid pid, int status);

		private static string HOME = Environment.get_home_dir();
						
		private bool respawn;
		private string[] application;
		
		public Launcher(string[] application, bool respawn) {
			/**
			 * Constructs the object.
			*/
			
			this.application = application;
			this.respawn = respawn;
						
		}
		
		public void on_process_terminated(Pid pid, int status) {
			/**
			 * Fired when the processh has been terminated.
			*/
			
			debug("Pid %s terminated.", pid.to_string());
			
			Process.close_pid(pid);
			
			/* Respawn? */
			if (respawn && status > 1) {
				try {
					this.launch();
				} catch (Error e) {
					warning("Unable to respawn %s.", this.application[0]);
				}
			}
			
			/* Fire terminated signals to listeners */
			this.terminated(pid, status);
			
		}

		
		public Pid launch() throws Error, LauncherError {
			/**
			 * Launches the given application.
			*/
			
			Pid pid;
			string[] env = Environ.get();
			
			if (this.application.length == 0)
				throw new LauncherError.ARRAY_ERROR("The application array shouldn't be zero!");
			
			Process.spawn_async(
				HOME,
				this.application,
				env,
				SpawnFlags.SEARCH_PATH | SpawnFlags.DO_NOT_REAP_CHILD,
				null,
				out pid
			);
			
			ChildWatch.add(pid, this.on_process_terminated);
			
			return pid;
			
		}
		
	}
					

}
