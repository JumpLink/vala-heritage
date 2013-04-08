using Json;

namespace Heritage {

	public class API : GLib.Object {

		Heritage.Config config;

		public API(Heritage.Config config) {
			this.config = config;
		}

		~API() {
			
		}

		/**
		 */
		private Json.Object call (string url) {

			var session = new Soup.SessionAsync ();
			var message = new Soup.Message ("GET", url);

			session.send_message (message);

			string data = (string) message.response_body.flatten().data;
			debug (data);

			Json.Parser parser = new Json.Parser ();
			parser.load_from_data (data, -1);

			Json.Object root_object = parser.get_root ().get_object ();
			return root_object;
		}

		/**
		 */
		public GLib.HashTable<string,Value?> catalog_product_info (string sku) {
			Json.Object root_object = this.catalog_product_infos ({sku});
			Json.Array columns = 	root_object.get_array_member ("COLUMNS");
			Json.Object data = 		root_object.get_object_member ("DATA");

			GLib.HashTable<string,Value?> result = new GLib.HashTable<string,Value?>(str_hash, str_equal);

			for (var i = 0;i<columns.get_length ();i++) {

				string element_name = columns.get_string_element (i);
				Json.Array current_element_array = data.get_array_member ( element_name );
				string element_type = current_element_array.get_element (0).type_name ();
				GLib.Value? element_value = null;
				switch (element_type) {
					case "Integer":
						element_value = (int) current_element_array.get_int_element (0);
						break;
					case "String":
						element_value = (string) current_element_array.get_string_element (0);
						break;
					case "Floating Point":
						element_value = (double) current_element_array.get_double_element (0);
						break;
				}
				result.insert(element_name, element_value);
				debug ( element_name );
				debug ( element_type );
			}

			return result;
		}

		/**
		 */
		public Json.Object catalog_product_infos (string[] skus) {
			string url = "http://"+config.host+config.path+"/parts?l_sPartCode="+skus[0]+"&sToken="+config.key;
			return this.call(url);
		}

		/**
		 */
		public Json.Object catalog_product_list () {
			string url = "http://"+config.host+config.path+"/partnums?sToken="+config.key;
			return this.call(url);
		}
	}
}