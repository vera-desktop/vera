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
	
	public class TrackableLauncher : Object {
		
		/**
		 * A trackable launcher.
		*/
		
		private const int MAX_WAIT_TIME = 30;
		
		private AppLaunchContext context;
		private AppInfo info;
		
		private bool _launched = false;
		
		public signal void launched();
		
		private void on_application_launched(AppInfo info, Variant platform_data) {
			/**
			 * Application launched!
			*/
			
			message("Application launched!");
			
			this._launched = true;
			
			this.launched();
		}
		
		private void on_application_launch_failed(string startup_notify_id) {
			/**
			 * Fired when the application launch failed.
			*/
			
		}
		
		private void create_context() {
			/**
			 * Creates and connects the AppLaunchContext.
			*/
			
			this.context = new AppLaunchContext();
			this.context.launched.connect(this.on_application_launched);
			this.context.launch_failed.connect(this.on_application_launch_failed);
			
		}
		
		public TrackableLauncher(string command, bool with_startup_notification = false) {
			/**
			 * Initializes the class from a given command line string.
			*/
			
			this.info = AppInfo.create_from_commandline(
				command,
				null,
				with_startup_notification ?
					AppInfoCreateFlags.SUPPORTS_STARTUP_NOTIFICATION :
					AppInfoCreateFlags.NONE
			);
			
			this.create_context();
			
		}
		
		/*
		public TrackableLauncher.from_desktop(string desktop_file) {
			/**
			 * Initializes the class from a given .desktop file.
			*
			
			this.info = new DesktopAppInfo.from_filename(desktop_file);
			
			this.create_context();
			
		}
		*/
		
		public void launch(bool block = false) throws Error {
			/**
			 * Launches the application.
			 * 
			 * If block is true, the method will block everything until
			 * the application has been launched successfully or a 30-second
			 * timeout has elapsed.
			*/
			
			//this.info.launch(null, this.context);
			this.context.get_startup_notify_id(this.info, null);
			this.info.launch(null, this.context);
			
			if (!block)
				return;
			
			/* Block */
			
			int count = 0;
			
			while (!_launched && !(count == MAX_WAIT_TIME)) {
				/* Wait */
				
				message("waiting");
				Thread.usleep(1000000);
				
				count++;
			}
			
		}
		
	}
				

	public class Launcher : Object {
		/**
		 * Useful methods to launch up things.
		 * (With startup notifications, yay!
		*/
		
		public signal void terminated (Pid pid, int status);

		private static string HOME = Environment.get_home_dir();
		
		private bool sync;
		private bool respawn;
		private bool startup_notify;
		private string[] application;
		
		private AppInfo info;
		private Gdk.AppLaunchContext context;

		private void on_application_launched(AppInfo info, Variant platform_data) {
			/**
			 * Application launched!
			*/
			
			message("Application launched!");
		}
		
		private void on_application_launch_failed(string startup_notify_id) {
			/**
			 * Fired when the application launch failed.
			*/
			
		}

		public Launcher(string[] application, bool sync = false, bool respawn = false, bool startup_notify = false) {
			/**
			 * Constructs the object.
			*/
			
			this.application = application;
			this.sync = sync;
			this.respawn = respawn;
			this.startup_notify = startup_notify;
			
			if (startup_notify) {
				Gdk.Display display = Gdk.Display.get_default();
				
				this.context = display.get_app_launch_context();
				this.context.set_screen(display.get_default_screen());
				this.context.set_desktop(1);
				this.context.set_icon_name("gtk-save");
				
				/* When launching, the context requires an AppInfo */
				this.info = AppInfo.create_from_commandline(
					string.joinv(" ", application),
					application[0],
					AppInfoCreateFlags.SUPPORTS_STARTUP_NOTIFICATION
				);

				this.context.launched.connect(this.on_application_launched);
				this.context.launch_failed.connect(this.on_application_launch_failed);

			}
			
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

		
		public Pid? launch() throws Error, LauncherError {
			/**
			 * Launches the given application.
			*/
			
			/*
			 * Useful links:
			 * https://github.com/evolve-os/budgie-desktop/blob/ec375c658a9905c4479f25424a9cb6e6829c4c65/panel/applets/icontasklist/IconTasklistApplet.vala
			 * https://github.com/engla/kupfer/blob/04bbd63c483cbefe8230679aa892452fabb77e14/kupfer/desktop_launch.py
			*/
			
			Pid pid;
			string[] env = Environ.get();
			
			if (this.application.length == 0)
				throw new LauncherError.ARRAY_ERROR("The application array shouldn't be zero!");
			
			/* Handle startup notifications */
			this.context.set_timestamp(Gdk.CURRENT_TIME);
			string val = this.context.get_startup_notify_id(this.info, null);
			message(val);
			if (this.startup_notify && val != null) {
				env = Environ.set_variable(
					env,
					"DESKTOP_STARTUP_ID",
					val
				);
			}
			
			this.info.launch(null, this.context);
			return null;
			
			if (this.sync) {
				Process.spawn_sync(
					HOME,
					this.application,
					env,
					SpawnFlags.SEARCH_PATH,
					null,
					null,
					null,
					null
				);
				
				return null;
			} else {
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
					

}
