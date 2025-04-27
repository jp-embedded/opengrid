lock = true;
key = true;

cell_size = 28;
cell_wall_size = 1.5;
cell_height = 6.8;

cell_chamfer = 0.4;

screw_base = 8;

e = 0.01;
$fa = 1;
$fs = 0.4;

include <BOSL2/std.scad>
include <BOSL2/screws.scad>
include <BOSL2/joiners.scad>

tile_size = 28;
tile_height = 6.8;
tile_edge_width = 1.5;
//tile_chamfer = 0.4;
tile_chamfer = 0;

snap_l = tile_height/2;
snap_w = 5;
snap_h = 3;
snap_depth = 0.25;
snap_compression = 0.1;

module tile()
{
    difference() {
        // rect tube
        cuboid([tile_size+e, tile_size+e, tile_height]); 
        cuboid([tile_size-tile_edge_width*2, tile_size-tile_edge_width*2, tile_height+e], chamfer = -tile_chamfer);

        // grove
        diff() cuboid([tile_size-1.6, tile_size-1.6, 4]) edge_profile() mask2d_chamfer(x = 0.7, y = 1);
    }

    // corners
    intersection() {
        c = adj_opp_to_hyp(4.2, 4.2) / 2 + 2.6;
        cuboid([tile_size+e, tile_size+e, tile_height]); 
        zrot_copies(n = 4) move([tile_size/2, tile_size/2, 0]) zrot(45) cuboid([c*2, 100, tile_height], chamfer = 1.4);
    }
}

module insert_lite()
{
   intersection() {
      difference() {
         cuboid([cell_size, cell_size, cell_height/2]);
         up(cell_height/4 - e) tile();
      }

      // cut chamfer at corners
      diag = sqrt(cell_size^2 + cell_size^2);
      inner_corner = (sqrt(4.2^2 + 4.2^2)/2 + 2.6);
      inner_diag = diag - inner_corner * 2;
      rotate(45) cuboid([inner_diag, inner_diag, 10], except=[TOP,BOTTOM]);
   }
}

circle_snap = 0.1;

// cylinder that fits inside tile grove. Same height and edge profile as tile grove
module grove_cyl()
{
	inside_dia = cell_size - 1.6;
	diff() cyl(h = 4, d = inside_dia + circle_snap) edge_profile() mask2d_chamfer(x = 0.7, y = 1);
}

module mount_round() 
{
      intersection() {
         down(e) insert_lite();

         // cylinder that fits inside tile
	 // move grove cylinder up to align bottom. Better to have che chamfer at bottom. Also makes the top chamfer match nicely 
         up(0.3) union() {
	    grove_cyl();

            // Corners so it can only rotate 45 deg
            diff() cuboid([(tile_size-1.6)/2, (tile_size-1.6)/3, 4], anchor=LEFT+FRONT) edge_profile() mask2d_chamfer(x = 0.7, y = 1);
            rotate(90) diff() cuboid([(tile_size-1.6)/2, (tile_size-1.6)/3, 4], anchor=LEFT+FRONT) edge_profile() mask2d_chamfer(x = 0.7, y = 1);
            rotate(180) diff() cuboid([(tile_size-1.6)/2, (tile_size-1.6)/3, 4], anchor=LEFT+FRONT) edge_profile() mask2d_chamfer(x = 0.7, y = 1);
            rotate(270) diff() cuboid([(tile_size-1.6)/2, (tile_size-1.6)/3, 4], anchor=LEFT+FRONT) edge_profile() mask2d_chamfer(x = 0.7, y = 1);
         }

         // Cut cornes so it can be inserted at 45 degree
         rotate(45) cuboid([cell_size - 3, cell_size - 3, cell_height/2], chamfer =  0.4);
      }
}

module dovetails()
{
	zrot(45) zrot_copies(n=2) left(12) down(cell_height/4  ) {
		rabbit_clip(type="socket",length=snap_l, width=snap_w,snap=snap_depth,thickness=1.0, depth=snap_h + 0.4, lock=false,compression=snap_compression, anchor=TOP);
	}

}

render() {

	if (lock) difference() {
		mount_round();
		down(cell_height/4 + e) {
			// flat head. cell_height/2 - 2 = 1.4
			//screw_hole("M3.5,1.4", head="socket", counterbore = 10, anchor = BOTTOM);

			screw_hole("M4.0,3.1", head="flat", counterbore = 10, anchor = BOTTOM);
			//screw_hole("M3.5,3.1", head="flat", counterbore = 10, anchor = BOTTOM);

			// Troltekt (combine with above)
			//up(cell_height/2 - 2) cyl(d=14, h=10, anchor=BOTTOM);

			// Flat head (combine with above)
			//up(cell_height/2 - 2) cyl(d=8.6, h=10, anchor=BOTTOM);
		}

		dovetails();
	}

	if (key) {
		zrot(45) up(cell_height/4) cuboid([tile_size - 4, 3, tile_size - 4], chamfer=0.4, except = BOTTOM, anchor = BOTTOM) {
			zrot_copies(n=2) {
				attach(BOTTOM) left(12) intersection() {
					rabbit_clip(type="pin",length=snap_l, width=snap_w,snap=snap_depth,thickness=1.0, depth=snap_h, compression=snap_compression,lock=false);
					cuboid([10,3+e,10], chamfer=0.4, except=BOTTOM, anchor = BOTTOM+LEFT);
				}
				attach(BOTTOM) left((tile_size - 4) / 2) cuboid([1, 3, 2.1], chamfer=0.4, except=[BOTTOM,RIGHT], anchor = BOTTOM+LEFT);
			}
		}
	}

}
