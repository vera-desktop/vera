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

		private string HOME = Environ.get_variable(Environ.get(), "HOME");
		private Application[] applications = new Application[0];
		private HashMap<Pid, Application> pid_associations = new HashMap<Pid, Application>();
		
		private string[] ignored_files;
		
		private void on_process_terminated(Pid pid, int status) {
			/**
			 * Fired when the process pid has been terminated.
			*/
						
			// Remove pid from associations
			this.pid_associations.unset(pid);
		}
		
		private void launch_from_list(StartupPhase phase) {
			/**
			 * Starts the Applications in this.applications, respecting
			 * the StartupPhase.
			*/
						
			Pid? pid;
			Launcher launcher;
			
			bool sync, respawn;
			foreach (Application app in this.applications) {
				
				if (app.phase != phase || "KDE" in app.only_show_in)
					/*
					 * Vera does not have its own key to put in the
					 * OnlyShowIn, so we need to launch applications
					 * that are 'meant' to another environments.
					 * 
					 * As the only (so far) working and in upstream
					 * Qt-based desktop environment is KDE, we check
					 * for it.
					 * 
					 * We should probably implement a whitelist so
					 * that the user could override this setting.
					 * (FIXME)
					*/
					continue;
				
				debug("Loading %s", app.name);
				
				/* sync? */
				if (app.mode == LaunchMode.SYNC)
					sync = true;
				else
					sync = false;
				
				/* Always respawn, if phase != OTHER */
				if (app.phase == StartupPhase.OTHER)
					respawn = false;
				else
					respawn = true;
					
				try {
					launcher = new Launcher(Launcher.command_split(app.executable), sync, respawn);
					pid = launcher.launch();
					
					if (pid != null) {
						// Add pid to pid_associations
						this.pid_associations[pid] = app;
						
						launcher.terminated.connect(this.on_process_terminated);
					}
					
					
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
