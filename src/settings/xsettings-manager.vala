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

/* This file is not Wayland-friendly */

namespace Vera {

    public class XsettingsManager : Object {
	
	private Settings settings;
	
	private XSettings.Manager manager;
	private XlibDisplay xlibdisplay;
	
	public XsettingsManager(XlibDisplay xlibdisplay) {
	    /**
	     * This is the XSETTINGS manager. It uses the vera-xsettings
	     * library to talk with X.
	     * 
	     * You can disable it by setting 'enable-xsettings' to 'false'
	     * in dconf.
	    */
	    
	    this.xlibdisplay = xlibdisplay;
	    
	    // FIXME: The vala bindings do not destroy automatically the manager
	    this.manager = new XSettings.Manager(this.xlibdisplay.display, 0, () => {});
	    
	    // Create Settings object
	    this.settings = new Settings("org.semplicelinux.vera.settings");
	    this.settings.changed.connect(this.on_setting_changed);
	    
	    this.reload_settings();
	    	    
	}
	
	private void on_setting_changed(string key) {
	    /**
	     * Fired when a setting in the dconf database has been
	     * changed.
	     * 
	     * This method will update its XSETTING and notify listeners
	     * about the changes.
	    */
	    
	    this.store_setting(key);
	    this.manager.notify();
	}
	
	private string get_xsettings_name(string name) {
	    /**
	     * Returns an XSETTINGS-compilant name.
	    */
	    
	    string prefix;
	    string rest = name;
	    switch (name) {
		
		case "double-click-time":
		case "double-click-distance":
		case "dnd-drag-threshold":
		case "cursor-blink":
		case "cursor-blink-time":
		case "theme-name":
		case "icon-theme-name":
		    // Settings shared among all toolkits
		    
		    prefix = "Net/";
		    break;
		
		case "xft-antialias":
		case "xft-hinting":
		case "xft-hintstyle":
		    // xft settings
		    
		    prefix = "Xft/";
		    rest = rest.replace("xft-", "");
		    break;
		
		case "xft-rgba":
		case "xft-dpi":
		    // like above, but ALL CAPS
		    
		    prefix = "Xft/";
		    rest = rest.replace("xft-", "");
		    rest = rest.up();
		    break;
		
		default:
		    // Gtk+ settings
		    
		    prefix = "Gtk/";
		    break;
	    
	    }
	    
	    string[] splt = rest.split("-");
	    for (int i=0; i < splt.length; i++) {
		splt[i] = splt[i].up(1) + splt[i].substring(1);
	    }
	    
	    return prefix + string.joinv("", splt);
	
	}
	
	public void store_setting(string key) {
	    /**
	     * Stores the setting 'key' in the XSETTINGS manager.
	    */
	    
	    string name = this.get_xsettings_name(key);
	    Variant val;
	    
	    val = this.settings.get_value(key);
	    
	    message("%s is %s", name, val.get_type_string());
	    
	    switch (val.get_type_string()) {
		
		case "s":
		    // string
		    
		    this.manager.set_string(name, val.get_string());
		    break;
		case "b":
		    // bool
		    
		    this.manager.set_int(name, (uint16)val.get_boolean());
		    break;
		case "i":
		    // int
		    
		    this.manager.set_int(name, val.get_int32());
		    break;
		    
	    }
		    
	    
	}
	
	public void reload_settings() {
	    /**
	     * Reloads the settings from the gsettings schema.
	     * 
	     * See /org/semplicelinux/vera/settings for all available
	     * settings.
	    */
	    
	    foreach (string key in this.settings.list_keys()) {
		this.store_setting(key);
	    }
	    
	    this.manager.notify();
	}
		
		
	
	~XsettingsManager() {
	    /**
	     * Manually destroy things.
	    */
	    
	    this.manager.destroy();
	}
    }
}
