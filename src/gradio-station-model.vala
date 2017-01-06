/* This file is part of Gradio.
 *
 * Gradio is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Gradio is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Gradio.  If not, see <http://www.gnu.org/licenses/>.
 */

namespace Gradio{

	public class StationModel : GLib.Object, GLib.ListModel {
  		private GLib.GenericArray<RadioStation> stations = new GLib.GenericArray<RadioStation> ();
		private int64 min_id = int64.MAX;
		private int64 max_id = int64.MIN;

		public int64 lowest_id {
    			get {
      				return min_id;
    			}
  		}

  		public int64 greatest_id {
    			get {
      				return max_id;
    			}
  		}

  		public GLib.Type get_item_type () {
    			return typeof (RadioStation);
  		}

  		public GLib.Object? get_item (uint index) {
    			assert (index >= 0);
    			assert (index <  stations.length);

    			return stations.get ((int)index);
  		}

 		public uint get_n_items () {
    			return stations.length;
  		}


  		private void remove_at_pos (int pos) {
    			int64 id = this.stations.get (pos).ID;

    			this.stations.remove_index (pos);


    			// Now we just need to update the min_id/max_id fields
    			if (id == this.max_id) {
      				if (this.stations.length > 0) {
        				int p = int.max (pos - 1, 0);
        				this.max_id = this.stations.get (p).ID;
      				} else {
        				this.max_id = int64.MIN;
      				}
    			}

    			if (id == this.min_id) {
      				if (this.stations.length > 0) {
        				int p = int.min (pos + 1, this.stations.length - 1);
        				this.min_id = this.stations.get (p).ID;
      				} else {
        				this.min_id = int64.MAX;
      				}
    			}
  		}

		private void insert(RadioStation station){
			int insert_pos = stations.length;
			stations.insert (insert_pos, station);

			this.items_changed (insert_pos, 0, 1);
		}

	  	private void insert_sorted (RadioStation station) {
		    	/* Determine the end we start at.
		       	Higher IDs are at the beginning of the list */
		    	int insert_pos = -1;
		    	if (station.ID > max_id) {
		      		insert_pos = 0;
		    	} else if (station.ID < min_id) {
		      		insert_pos = stations.length;
		    	} else {
			      	// This case is weird(?), but just estimate the starting point
			      	int64 half = (max_id - min_id) / 2;
			      	if (station.ID > min_id + half) {
					// we start at the beginning
					for (int i = 0, p = stations.length; i < p; i ++) {
				  		if (stations.get (i).ID <= station.ID) {
				    			insert_pos = i;
				    			break;
				  		}
					}
			      	} else {
					// we start at the end
					for (int i = stations.length - 1; i >= 0; i --) {
				  		if (stations.get (i).ID >= station.ID) {
				    			insert_pos = i + 1;
				    			break;
				  		}
					}
			      	}
	    		}

	    		assert (insert_pos != -1);
	    		stations.insert (insert_pos, station);

	    		this.items_changed (insert_pos, 0, 1);
	  	}

	  	public void add (RadioStation station) {
	    		assert (station.ID > 0);


	      		this.insert (station);

	      		if (station.ID > this.max_id)
				this.max_id = station.ID;

	      		if (station.ID < this.min_id)
				this.min_id = station.ID;

	  	}

	  	public void remove_last_n_visible (uint amount) {
	    		assert (amount <= stations.length);

	    		uint n_removed = 0;

	    		int size_before = stations.length;
	    		int index = stations.length - 1;

	    		while (index >= 0 && n_removed < amount) {
	      			this.remove_at_pos (index);
	      			index --;
	      			n_removed ++;
	    		}

	    		int removed = size_before - stations.length;
	    		this.items_changed (size_before - removed, removed, 0);
	  	}

	  	public void clear () {
	    		int s = this.stations.length;
	    		this.stations.remove_range (0, stations.length);
	    		this.min_id = int64.MAX;
	    		this.max_id = int64.MIN;
	    		this.items_changed (0, s, 0);
	  	}

	  	public void remove_station (RadioStation t) {

	      		int pos = 0;
	      		for (int i = 0; i < stations.length; i ++) {
				RadioStation station = stations.get (i);
				if (t == station) {
		  			pos = i;
		  			break;
				}
	      		}
	      		/* We only need to emit items-changes if the station was really in @stations, not @hidden_tweets */
	      		this.remove_at_pos (pos);
	     		this.items_changed (pos, 1, 0);
	  	}


	  	public bool contains_id (int64 station_id) {
	    		for (int i = 0; i < stations.length; i ++) {
	      			RadioStation station = stations.get (i);
	      			if (station.ID == station_id)
					return true;
	    		}

	    		return false;
	  	}

	  	public void remove_stations_above (int64 id) {
	    		while (stations.length > 0 && stations.get (0).ID >= id) {
	      			this.remove_at_pos (0);
	      			this.items_changed (0, 1, 0);
	    		}
	  	}

	  	public RadioStation? get_from_id (int64 id, int diff = -1) {
	    		for (int i = 0; i < stations.length; i ++) {
	      			if (stations.get (i).ID == id) {
					if (i + diff < stations.length && i + diff >= 0)
		  				return stations.get (i + diff);
					return null;
	      			}
	    		}
	    		return null;
	  	}

	  	public bool delete_id (int64 id, out bool seen) {
	    		for (int i = 0; i < stations.length; i ++) {
	      			RadioStation t = stations.get (i);
	      			if (t.ID == id) {
					return true;
	    			}

	    			seen = false;
	    			return false;
	  		}
	  		return false;
	  	}

	}
}
