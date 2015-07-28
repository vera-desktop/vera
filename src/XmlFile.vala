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

/* Helpful: https://wiki.gnome.org/Projects/Vala/MarkupSample */

namespace Vera {
	
	public abstract class XmlObject : Object {
		
		public string? content {get; set;}
		
		protected string get_padding(int padding) {
			/**
			 * Returns appropriate padding.
			*/
			
			string result = "";
			for (int i = 0; i < padding; i++) {
				result += "  ";
			}
			
			return result;
			
		}
		
		public abstract string to_string(int padding);
		
	}
		
	public class XmlNode : XmlObject {
	
		/**
		 * Represents an Xml Node.
		*/
		
		private int current = -1;
		
		public XmlNode? parent;
		
		public Array<XmlObject?> childs = new Array<XmlObject?>();
		
		public string name;
						
		public HashTable<string, string> attributes = new HashTable<string, string>(str_hash, str_equal);
				
		public XmlNode(XmlNode? parent, string name) {
			/**
			 * Constructor.
			*/
			
			this.parent = parent;
			this.name = name;
			
		}

		public XmlNode? get_child(string name) {
			/**
			 * Returns the first child node with the given name.
			 * 
			 * If no node has been found, returns null.
			*/

			/* Reset current */
			this.current = -1;
			
			XmlObject obj;
			XmlNode node;
			while ((obj = this.next()) != null) {
				if (obj.get_type().is_a(typeof(XmlNode))) {
					node = obj as XmlNode;
					
					if (node.name == name)
						return node;
				}
			}
			
			return null;
		}
		
		public XmlNode[] get_childs(string name) {
			/**
			 * Returns every child node with the given name.
			*/
			
			/* Reset current */
			this.current = -1;
			
			XmlNode[] result = new XmlNode[0];
			
			XmlObject obj;
			XmlNode node;
			while ((obj = this.next()) != null) {
				if (obj.get_type().is_a(typeof(XmlNode))) {
					node = obj as XmlNode;
					
					if (node.name == name)
						result += node;
				}
			}
			
			return result;
			
		}
		public XmlObject? next() {
			/**
			 * Returns the next child node
			*/
			
			if (current + 1 == childs.length)
				return null;
			
			current++;
			
			return childs.index(current);
		}
		
		public override string to_string(int padding) {
			/**
			 * Returns the current node (with childs!) as a string.
			*/
			
			/* Reset current */
			this.current = -1;
			
			string result = "";
			
			XmlObject? obj;
			XmlNode node;
			string attrs;
			while ((obj = this.next()) != null) {
				
				if (obj.get_type().is_a(typeof(XmlNode))) {
					/* This is an XmlNode */
					node = (XmlNode)obj;
					
					/* Build attribute list */
					attrs = "";
					node.attributes.foreach(
						(k, v) => {
							attrs += " %s=\"%s\"".printf(k, v);
						}
					);
					
					result += "%s<%s%s".printf(
						this.get_padding(padding),
						node.name,
						attrs
					);
					
					if (node.childs.length > 0) {
						result += ">\n" + node.to_string(padding+1);
					} else if (node.content != null) {
						result += ">" + node.content;
					}
					
					/* Print closure */
					if (node.childs.length == 0 && node.content == null) {
						result += " />\n";
					} else {
						result += "%s</%s>\n".printf(
							(node.content != null) ? "" : this.get_padding(padding),
							node.name
						);
					}
				} else {
					result += obj.to_string(padding);
				}
			}
			
			return result;
		}
	
	}
	
	public class XmlComment : XmlObject {

		public override string to_string(int padding) {
			
			if (this.content == null)
				return "";
			
			return "%s%s\n".printf(this.get_padding(padding), this.content);
			
		}
	}

	public class XmlFile : Object {
		
		/**
		 * The OpenboxConfiguration class parses and handles the openbox
		 * configuration.
		*/

		public string file_path { get; private set; }

		private const MarkupParser parser = {
			start,
			end,
			text,
			comment,
			error
		};
		
		private MarkupParseContext context;
		
		public XmlNode root_node;
		private XmlNode current_node;
		
		public XmlFile(string file_path) {
			/**
			 * Constructor.
			*/
			
			this.file_path = file_path;
			
			this.context = new MarkupParseContext(
				parser,
				0,
				this,
				this.destroy
			);
			
			this.root_node = new XmlNode(null, "__root");
			this.current_node = this.root_node;

			/* Read configuration */
			string content;
			size_t length;
			FileUtils.get_contents(file_path, out content, out length);
			
			this.context.parse(content, (ssize_t)length);
			
			//this.write();
		}
		
		public void write(string? target = null) {
			/**
			 * Writes the xml file.
			 * 
			 * If target == null, the original file will be overwritten.
			*/
			
			File file = File.new_for_path((target == null) ? this.file_path : target);
			
			if (file.query_exists()) {
				file.delete();
			}
			
			lock (this.root_node) {
			
				try {
					DataOutputStream stream = new DataOutputStream(file.create(FileCreateFlags.REPLACE_DESTINATION));
					
					stream.put_string(this.root_node.to_string(0) + "\n");
					
					stream.close();
				} catch (Error e) {
					warning("Unable to write openbox configuration: %s", e.message);
				}
				
			}
			
		}
		
		private void destroy() {
		}
		
		private void start(
			MarkupParseContext context,
			string name,
			string[] attr_names,
			string[] attr_values
		) throws MarkupError {
			/**
			 * Handles the start of a node.
			*/
			
			/* Create new node */
			XmlNode node = new XmlNode(this.current_node, name);
			
			/* Add to current_node */
			this.current_node.childs.append_val(node as XmlObject);
			
			/* Replace the current_node with the newly created one */
			this.current_node = node;
			
			/* Set attributes */
			for (int i = 0; i < attr_names.length; i++) {
				this.current_node.attributes.set(attr_names[i], attr_values[i]);
			}
			
		}
		
		private void end(MarkupParseContext context, string name) throws MarkupError {
			/**
			 * Handles the end of a node.
			*/
			
			if (this.current_node.parent == null)
				return;
			
			this.current_node = this.current_node.parent;
		}
		
		private void text(MarkupParseContext context, string text, size_t text_len) throws MarkupError {
			/**
			 * Handles the node content.
			*/
			
			if (text.replace(" ","").replace("\t","").replace("\n","") == "")
				return;
			
			this.current_node.content = text;
			
		}
		
		private void comment(MarkupParseContext context, string comment, size_t text_len) throws MarkupError {
			/**
			 * Handles a comment.
			*/
			
			this.current_node.childs.append_val((new XmlComment() { content = comment }) as XmlObject);
			
		}
		private void error() { }
		
	}

}
