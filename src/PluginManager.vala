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

/*
 * TODO:
 * - Handle unloading of plugins on-the-fly
 * - Handle rescanning and loading of plugins on-the-fly
*/

using Peas;

namespace Vera {
	
	public class PluginManager : Object {
		/**
		 * The PluginManager() handles the startup and shutdown of the
		 * plugins and also makes them aware of vera's startup phases.
		 * 
		 * You can disable plugin support via dconf ('enable-plugins')
		 * and there you can also manage the search path and the blacklisted
		 * (or whitelisted) plugins.
		*/
		
		private Engine engine;
		private ExtensionSet extension_set;
		
		/*
		 * Peas stores the loaded plugins using their library names, and
		 * we do not want that.
		*/
		private Gee.ArrayList<string> loaded_plugins = new Gee.ArrayList<string>();
		
		private string[] blacklisted_plugins;
		private bool reverse_blacklist;
		
		private Display display;
		
		private Settings settings;
		
		// FIXME: It seems we can't cleanly pass it on ExtensionSet.foreach()
		private StartupPhase phase;
		
		public PluginManager(Display display, Settings settings, string[] cmdline) {
			
			this.display = display;
			this.settings = settings;
			
			// Create the engine
			this.engine = Engine.get_default();
			this.engine.enable_loader("python");
			this.engine.enable_loader("gjs");
			
			// Add the search path(s)
			foreach (string path in this.settings.get_strv("plugin-search-path")) {
				this.engine.add_search_path(path, null);
			}
			
			/*
			 * By default we load every plugin found in the search directories.
			 * The user has a "blacklist" though where he/she can specify
			 * which plugins to ignore.
			 * 
			 * For special needs it's also available the 'reverse-ignore-plugins'
			 * option that transforms the said blacklist in a whitelist.
			 * 
			 * Finally, the user can also specify the plugins via command line.
			 * If this is the case (cmdline != null), we assume that
			 * reverse-ignore-plugins is true and use the cmdline array as
			 * our whitelist.
			 * 
			 * This of course does not change the settings in dconf.
			*/
			if (cmdline == null) {
				this.blacklisted_plugins = this.settings.get_strv("ignore-plugins");
				this.reverse_blacklist = this.settings.get_boolean("reverse-ignore-plugins");
			} else {
				this.blacklisted_plugins = cmdline;
				this.reverse_blacklist = true;
			}
			
			// Create the extension set
			this.extension_set = new ExtensionSet(this.engine, typeof(VeraPlugin));
			
			// Connect the extension_set events
			this.extension_set.extension_added.connect(this.on_plugin_added);
			this.extension_set.extension_removed.connect(this.on_plugin_removed);
			
		}
		
		private void on_plugin_added(ExtensionSet extension_set, PluginInfo info, GLib.Object object) {
			/**
			 * This callback is fired when a new plugin has been loaded.
			 * This method will handle its first initalization.
			*/
						
			try {
				((VeraPlugin) object).init(this.display);
			} catch (GLib.Error e) {
				warning(e.message);
				// also unload?
			}
		}
		
		private void on_plugin_removed(ExtensionSet extension_set, PluginInfo info, GLib.Object object) {
			/**
			 * This callback is fired when a plugin has been unloaded.
			*/
			
			try {
				((VeraPlugin) object).shutdown();
			} catch (GLib.Error e) {
				warning(e.message);
			}
		}
		
		private void startup_plugin(ExtensionSet extension_set, PluginInfo info, Extension object) {
			/**
			 * This method is called by this.startup_all_plugins()
			 * and will startup the plugin passing in the current StartupPhase.
			*/
			
			((VeraPlugin) object).startup(this.phase);
		}
		
		public void startup_all_plugins(StartupPhase phase) {
			/**
			 * This method calls the startup() method of every plugin,
			 * passing in the current StartupPhase.
			*/
			 
			/*
			 * We need to make startup_plugin() aware of the StartupPhase,
			 * as it seems that we cannot pass it directly via the
			 * foreach() method.
			*/
			
			this.phase = phase;		 
			
			this.extension_set.foreach(this.startup_plugin);
		}
		
		private PluginInfo? get_plugin_info(string name) {
			/**
			 * An alternative to PeasEngine.get_plugin_info(), because
			 * at least here it doesn't work correctly.
			*/
			
			foreach (PluginInfo plugin in this.engine.get_plugin_list()) {
				if (plugin.get_name() == name) {
					return plugin;
				}
			}
			
			return null;
		}
		
		public void load_plugin(string name) {
			/**
			 * Loads a plugin given its name.
			*/
			
			this.load_plugin_from_plugin_info(this.get_plugin_info(name));
			
		}
		
		public void load_plugin_from_plugin_info(PluginInfo plugin) {
			/**
			 * Loads a plugin given its PluginInfo.
			*/
			
			string name = plugin.get_name();
			
			if (plugin == null) {
				/* Not found */
				warning("Plugin %s not found!", name);
				return;
			}
			
			/* Try loading */
			if (this.engine.try_load_plugin(plugin)) {
				this.loaded_plugins.add(name);
				message("Plugin %s loaded.", name);
			} else {
				warning("Unable to load plugin %s.", name);
			}
			
		}
		
		
		public void load_all_plugins() {
			/**
			 * This method loads all available plugins.
			*/
			 
			string name;
									 			
			foreach (PluginInfo plugin in this.engine.get_plugin_list()) {
				
				name = plugin.get_name();
				
				// Not the best readable if out there...
				if (
				
					(!this.reverse_blacklist && name in this.blacklisted_plugins) ||
					(this.reverse_blacklist && !(name in this.blacklisted_plugins))
					
					)
				{
					continue;
				}
					
				this.load_plugin_from_plugin_info(plugin);
			}
		}
		
		public void unload_plugin(string name) {
			/**
			 * Unloads the given plugin.
			*/
			
			if (!(name in this.loaded_plugins)) {
				/* Not loaded */
				warning("Plugin %s has not been loaded.", name);
				return;
			}
			
			/* Try unloading */
			if (this.engine.try_unload_plugin(this.get_plugin_info(name))) {
				this.loaded_plugins.remove(name);
				message("Plugin %s unloaded.", name);
			} else {
				warning("Unable to unload plugin %s", name);
			}
		}
		
		public void unload_all_plugins() {
			/**
			 * Unloads all loaded plugins.
			*/
			
			foreach (string name in this.engine.get_loaded_plugins()) {
				this.unload_plugin(name);
			}
		}
	
	}

}
