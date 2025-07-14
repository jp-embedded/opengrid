include <BOSL2/std.scad>
include <BOSL2/screws.scad>

vertical = true;
directional = true;
MultiConnect_Thread = false; // for multiconnect thread

/* [Hidden] */

part_gap = 0.2;

cell_size = 28;
cell_wall_size = 1.5;
cell_height = 6.8;

cell_chamfer = 0.4;

$fa = 2;
$fs = 0.4;

e = EPSILON;

tile_size = 28;
tile_height = 6.8;
tile_edge_width = 1.5;
tile_chamfer = 0.4;

module tile(grove = true, chamfer = true, gap = 0)
{
    chamf = chamfer ? tile_chamfer : 0;
    difference() {
        // rect tube
        cuboid([tile_size+e, tile_size+e, tile_height]); 
        cuboid([tile_size-tile_edge_width*2 - gap*2, tile_size-tile_edge_width*2 - gap*2, tile_height+e], chamfer = -chamf);

        // grove
        //if (grove) diff() cuboid([tile_size-1.6, tile_size-1.6, 4]) edge_profile() mask2d_chamfer(x = 0.7, y = 1);
	// grove
	grove_h = 2;
	chamf_y = (tile_height - grove_h) / 2;
	chamf_x = chamf_y * 0.7;
        if(grove) diff() cuboid([tile_size-1.6, tile_size-1.6, tile_height]) edge_profile() mask2d_chamfer(x = chamf_x, y = chamf_y);
    }

    // corners
    intersection() {
        c = adj_opp_to_hyp(4.2, 4.2) / 2 + 2.6 + gap;
        cuboid([tile_size+e, tile_size+e, tile_height]); 
        zrot_copies(n = 4) move([tile_size/2, tile_size/2, 0]) zrot(45) cuboid([c*2, 100, tile_height], chamfer = 1.4);
    }
}

module multiconnect_thread()
{
	profile = [
		[-1.5/3, -1/3],
		[-1.25/3, -1/3],
		[-0.25/3,  0],
		[ 0.25/3,  0],
		[ 1.25/3, -1/3],
		[ 1.5/3, -1/3]
	];

	down(0.1) generic_threaded_rod(d=16.5, l=tile_height, pitch=3, profile=profile, blunt_start=false, $fn=50, anchor=BOTTOM);
}


module top_snap()
{
   difference() {

      // insert
      left(tile_size/2) cuboid([3, tile_size, tile_height/2+e], anchor=BOTTOM+LEFT);
      tile(grove = true, chamfer=false, gap = part_gap);
   }

}

module side_snap()
{
   snap_l = 8;
   flatten = 0.4;
   difference() {
	   // grove
	   grove_h = 2;
	   chamf_y = (tile_height - grove_h) / 2;
	   chamf_x = chamf_y * 0.7;
	   intersection() {
		   diff() cuboid([tile_size-1.6, snap_l, tile_height]) edge_profile(except=[FRONT+TOP,FRONT+BOTTOM,BACK+TOP,BACK+BOTTOM]) mask2d_chamfer(x = chamf_x, y = chamf_y);

		   // less steep on press-in
		   b_grove_h = 0;
		   b_chamf_y = (tile_height - b_grove_h) / 2;
		   b_chamf_x = chamf_y * 0.7;
		   up(1.85) diff() cuboid([tile_size-1.6, snap_l + 1, tile_height]) edge_profile(except=[FRONT+TOP,FRONT+BOTTOM,BACK+TOP,BACK+BOTTOM]) mask2d_chamfer(x = b_chamf_x, y = b_chamf_y);
	   }

	   // keep only grove
	   left(tile_size/2 - 1.5 - part_gap - e) cuboid([50, 10, 10], anchor=LEFT);

	   // flatten
	   left(tile_size/2 - 0.8 - flatten) cuboid([10, 10, 10], anchor=RIGHT);
   }

}

module snap(vertial = false, directional = true) 
{
	difference() {

		// insert
		cuboid([tile_size, tile_size, tile_height/2+e], anchor=BOTTOM);
		tile(grove = false, chamfer = false, gap = part_gap);

		if (vertial) {
			// cut bottom to make it printable/insertable
			chamf = tile_height/2;
			x = tile_size/2 - cell_wall_size + cell_chamfer - chamf;
			right(x) cuboid([tile_size, tile_size, tile_height+e], chamfer = chamf, anchor=LEFT);

			if (!directional) {
				// cut top to make it symetrical
				zrot(180) right(x) cuboid([tile_size, tile_size, tile_height+e], chamfer = chamf, anchor=LEFT);
			}

		}

		// cut for snap
		cut_recess = 0.8;
		cut_indent = 3.5;
		down(cut_recess) {
			//slice back
			zrot(-90) right(tile_size/2 - cut_indent) cuboid([0.5, 14, tile_height+e], anchor=LEFT);
			zrot(90) right(tile_size/2 - cut_indent) cuboid([0.5, 14, tile_height+e], anchor=LEFT);

			// slice side
			zrot(-90) up(tile_height/2) right(tile_size/2 - 3) cuboid([10, 14, 0.2], anchor=LEFT+TOP);
			zrot(90) up(tile_height/2) right(tile_size/2 - 3) cuboid([10, 14, 0.2], anchor=LEFT+TOP);
		}

		if (directional) {
			// cut corners a bit for angled insert
			c = adj_opp_to_hyp(4.2, 4.2) / 2 + 2.6;
			cut_h = 1.3;
			cut_a = 10;
			up(cut_h) move([tile_size/2, tile_size/2, 0]) zrot(45) yrot(cut_a) cuboid([c*2, 100, tile_height], anchor=TOP);
			zrot(-90) up(cut_h) move([tile_size/2, tile_size/2, 0]) zrot(45) yrot(cut_a) cuboid([c*2, 100, tile_height], anchor=TOP);
		}

		if (MultiConnect_Thread) multiconnect_thread();
	}
	zrot(-90) side_snap();
	zrot(90) side_snap();
	if (directional) {
		top_snap();
	}
}

render() {
	if (vertical) {
		up(tile_size/2 - tile_edge_width - part_gap) yrot(90) snap(vertial=true, directional = directional);
	}
	else {
		snap(vertial=false, directional=directional);
	}
}



