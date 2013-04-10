using Json;

namespace Heritage {

	public delegate void callback_string_array(string[] array);

	public class API : GLib.Object {

		Heritage.Config config;

		public API(Heritage.Config config) {
			this.config = config;
		}

		~API() {
			
		}

		private string transform_array_to_comma_seperated_string (string[] array) {
			string new_string = "";
			for (int i = 0; i < array.length; i++) {
				new_string += array[i];
				if (i != array.length-1)
					new_string += ",";
			}
			return new_string;
		}

		public static void each_sum (string[] array, uint length, callback_string_array cb) {
			int count_of_callbacks = (int) GLib.Math.round( (array.length / length) + 0.5 ); // Round up

			for (int i = 0; i < count_of_callbacks; i++) {
				string[] part_array = {};
				for (int a = 0; a < length && i*length+a < array.length ; a++) {
					part_array += array[i*length+a];
				}
				cb (part_array);
			}
		}

		/**
		 */
		private Json.Object call (string url) {

			var session = new Soup.SessionAsync ();
			var message = new Soup.Message ("GET", url);

			session.send_message (message);

			string data = (string) message.response_body.flatten().data;

			Json.Parser parser = new Json.Parser ();
			parser.load_from_data (data, -1);

			Json.Object root_object = parser.get_root ().get_object ();

			debug (data);

			return root_object;
		}

		/**
		 */
		public GLib.HashTable<string,Value?> catalog_product_info (string sku) {
			Json.Object root_object = this.catalog_product_infos ({sku});
			Json.Array columns 		= root_object.get_array_member 	("COLUMNS");
			Json.Object data 		= root_object.get_object_member ("DATA");

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
		public Json.Object catalog_product_infos (string[] skus)
		requires (skus.length <= 200)
		{
			string skus_string = transform_array_to_comma_seperated_string (skus);
			//debug ("skus_string "+skus_string);
			string url = "http://"+config.host+config.path+"/parts?l_sPartCode="+skus_string+"&sToken="+config.key;
			debug (url);
			return this.call(url);
		}

		public GLib.HashTable<string, int64?> catalog_product_infos_qty (string[] skus) {
			Json.Object product_infos_root_object	= this.catalog_product_infos (skus);
			int64 		product_infos_rowcount		= product_infos_root_object.get_int_member 		("ROWCOUNT");
			Json.Object product_infos_data			= product_infos_root_object.get_object_member 	("DATA");

			GLib.HashTable<string, int64?> result = new GLib.HashTable<string, int64?> (str_hash, str_equal);

			for (int i=0;i<product_infos_rowcount;i++) {
				string sku = product_infos_data.get_array_member ("ITEMNUMBER").get_string_element (i);
				int64 qty = product_infos_data.get_array_member ("FREESTOCKQUANTITY").get_int_element (i);
				//debug (sku+" : "+qty.to_string()+"\n");
				result.insert(sku, qty);
			}

			return result;
		}

		/**
		 */
		public Json.Object catalog_product_list () {
			string url = "http://"+config.host+config.path+"/partnums?sToken="+config.key;
			debug (url);
			return this.call(url);
		}

		public string[] catalog_product_list_skus () {
			Json.Object product_list_root_object	= this.catalog_product_list ();
			int64 		product_list_rowcount		= product_list_root_object.get_int_member 		("ROWCOUNT");
			Json.Object product_list_data			= product_list_root_object.get_object_member 	("DATA");
			string[] result = new string[product_list_rowcount];

			for (int i=0;i<product_list_rowcount;i++) {
				result[i] = product_list_data.get_array_member ("CODE").get_string_element (i);
				//debug (result[i]);
			}

			return result;
		}
	}
}