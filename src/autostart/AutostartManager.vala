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
 *     Eugenio "g7" Paolantonio <me@medesimo.eu>
*/

using Gee;

namespace Vera {

	public class AutostartManager : Object {

		private string HOME = Environ.get_variable(null, "HOME");
		private Application[] applications = new Application[0];
		private HashMap<Pid, Application> pid_associations = new HashMap<Pid, Application>();
		
		private string[] ignored_files;
		
		private void on_process_terminated(Pid pid, int status) {
			/**
			 * Fired when the process pid has been terminated.
			*/
			
			debug("Pid %s terminated.", pid.to_string());
			
			// Remove pid from associations
			this.pid_associations.unset(pid);
			
			Process.close_pid(pid);
		}
		
		private void launch_from_list(StartupPhase phase) {
			/**
			 * Starts the Applications in this.applications, respecting
			 * the StartupPhase.
			*/
						
			Pid pid;
			
			foreach (Application app in this.applications) {
				
				if (app.phase != phase)
					continue;
				
				debug("Loading %s", app.name);
					
				try {
					Process.spawn_async(
						this.HOME,
						app.executable.split(" "),
						Environ.get(),
						SpawnFlags.SEARCH_PATH | SpawnFlags.DO_NOT_REAP_CHILD,
						null,
						out pid
					);
					
					// Add pid to pid_associations
					this.pid_associations[pid] = app;
					
					ChildWatch.add(pid, this.on_process_terminated);
				} catch (SpawnError e) {
					warning(e.message);
				}
			}
		}
				
		
		private void cache_applications(string[] search_dirs) {
			/**
			 * This method will cache all applications, specified in
			 * search_dirs.
			 * Applications are stored in this.applications[].
			*/
			
			File directory;
			FileEnumerator enumerator;
			FileInfo file_info;
			
			foreach (string dir in search_dirs) {
				
				directory = File.new_for_path(dir);
				
				if (!directory.query_exists())
					// Directory not found!
					continue;
				
				try {
					enumerator = directory.enumerate_children(FileAttribute.STANDARD_NAME, 0);
					
					while ((file_info = enumerator.next_file()) != null) {
						
						if (!(file_info.get_name() in this.ignored_files))
							this.applications += new Application(Path.build_filename(dir, file_info.get_name()));
						
					}
				} catch (Error e) {
					warning("Unable to access to directory %s: %s", dir, e.message);
				}
			}
		}

				

		public AutostartManager(Settings settings) {
			/**
			 * Initializes the plugin.
			 */
			
			/*
			 * Welcome to the vera autostart plugin!
			 * This plugin will manage every application to start into
			 * the new user session.
			 * 
			 * If the user wants so, crashed applications (exited with a
			 * non-zero status) can be restarted.
			 * 
			 * This plugin manages ALL of the StartupPhases of vera.
			 * Simply specify in your desktop file the key
			 *    X-Vera-Autostart-Phase
			 * and everything will be fine.
			*/
			
			/* Get application files to ignore */
			this.ignored_files = settings.get_strv("autostart-ignore");
			
			// Cache applications
			this.cache_applications(
				{
					"/usr/share/vera/autostart",
					"/etc/xdg/autostart",
					Path.build_path(this.HOME, ".config/autostart")
				}
			);
			
		}
		
		public void startup(StartupPhase phase) {
			/**
			 * Called by vera when doing the startup.
			 * This plugin handles directly every VeraStartupPhase.
			 * Phases are read from the .desktop file to launch.
			*/
			
			this.launch_from_list(phase);
			
		}
		

	}
}
