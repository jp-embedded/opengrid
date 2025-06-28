include<BOSL2/std.scad>;
include<BOSL2/math.scad>;
include <BOSL2/joiners.scad>
include <BOSL2/cubetruss.scad>

grid_size_x = 3;
grid_size_y = 2;

edge_left = false;
edge_right = false;
edge_top = false;
edge_bottom = false;
snaps = "clip"; // [ "none", "clip", "rabbit"]


/* [Hidden] */

e = EPSILON;

tile_size = 28;
tile_height = 6.8;
tile_edge_width = 1.5;
tile_chamfer = 0.4;

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

// Snaps
snap_depth = 0.3;

module pin_double()
{
   if (snaps == "rabbit") {
      rabbit_clip(type="double",length=4, width=5,snap=snap_depth,thickness=0.8, depth=2, compression=0.3,lock=false);
   }
   if (snaps == "clip") {
      snap_pin(size="medium", l=6.5, pointed=false);
   }
}

module socket()
{
   if (snaps == "rabbit") {
      // 2*e - tile already has 1*e oversize
      ymove(-e*2) xrot(90) rabbit_clip(type="socket",length=4, width=5,snap=snap_depth,thickness=0.8, depth=2.4, lock=false,compression=0);
   }
   if (snaps == "clip") {
      xrot(90) snap_pin_socket(size="medium", l=6.5, pointed=false);
   }
}


module grid(x, y)
{
   difference() {
      grid_copies(spacing = tile_size, n = [x, y]) tile();

      // Snap sockets
      if (!edge_bottom) ymove(-y*tile_size/2) xcopies(spacing = tile_size, n = x-1) socket();
      if (!edge_top) zrot(180) ymove(-y*tile_size/2) xcopies(spacing = tile_size, n = x-1) socket();
      if (!edge_right) zrot(90) ymove(-x*tile_size/2) xcopies(spacing = tile_size, n = y-1) socket();
      if (!edge_left) zrot(270) ymove(-x*tile_size/2) xcopies(spacing = tile_size, n = y-1) socket();
   }
}

module snaps(x, y)
{
   // Snaps
   if (snaps) {
      edge_dist = 5;
      zmove(-tile_height/2) {
         if (!edge_bottom) ymove(-y*tile_size/2 + edge_dist) xcopies(spacing = tile_size, n = x) zrot(90) pin_double();
         if (!edge_top) zrot(180) ymove(-y*tile_size/2 + edge_dist) xcopies(spacing = tile_size, n = x) zrot(90) pin_double();
         if (!edge_right) zrot(90) ymove(-x*tile_size/2 + edge_dist) xcopies(spacing = tile_size, n = y) zrot(90) pin_double();
         if (!edge_left) zrot(270) ymove(-x*tile_size/2 + edge_dist) xcopies(spacing = tile_size, n = y) zrot(90) pin_double();
      }
   }
}

module edge(size)
{
   cuboid([size * tile_size, tile_edge_width, tile_height], chamfer = tile_chamfer, edges = FRONT, except = [LEFT, RIGHT], anchor=BACK);
}

module edge_corner(size)
{
   cuboid([tile_height, tile_edge_width, tile_height], chamfer = tile_chamfer, except = BACK, anchor=BACK);
}

module corner()
{
   cuboid([tile_edge_width + e, tile_edge_width + e, tile_height], chamfer = tile_chamfer, edges = [FRONT,LEFT], except = [RIGHT,BACK], anchor=BACK+RIGHT);
}

support_w = 1.4;

module grid_corner_straight(y, support_inside)
{
	corner_chamfer = 0.4;
	xrot(90) yrot_copies([0, 90]) left_half() grid(1, y);
	if (support_inside) {
		fwd(tile_height/2) cuboid([tile_size/2, support_w, tile_size*y], anchor=RIGHT+FRONT);
		left(tile_height/2) cuboid([support_w, tile_size/2, tile_size*y], anchor=LEFT+BACK);
	}
	else {
		back(tile_height/2) cuboid([tile_size/2, support_w, tile_size*y], anchor=RIGHT+BACK);
		right(tile_height/2) cuboid([support_w, tile_size/2, tile_size*y], anchor=RIGHT+BACK);
	}
	intersection() {
		cuboid([tile_height, tile_height, tile_size*y], chamfer = corner_chamfer, except=[TOP,BOTTOM]);
		cuboid([tile_height, tile_height, tile_size*y], chamfer = 3, except=[TOP,BOTTOM,FRONT,LEFT]);
	}
}

module grid_corner(y, bottom_corner, top_edge)
{
	support_inside = false;

	corner_chamfer = 0.4;
	difference() {
		grid_corner_straight(y, support_inside);
		if (!top_edge) up(tile_size*y/2) zrot(-45) xrot(-90) socket();
		if (!bottom_corner) down(tile_size*y/2) zrot(-45) xrot(90) socket();
	}

	if (bottom_corner) {
		down(y*tile_size/2 + tile_size/2) {
			difference() {
				union() {
					front_half() left_half() tile(); // bottom
					xrot(90) yrot_copies([0, 90]) back_half() left_half() tile();
					if (support_inside) {
						left(tile_height/2) cuboid([support_w, tile_size/2, tile_size/2], anchor=LEFT+BOTTOM+BACK);
						fwd(tile_height/2) cuboid([tile_size/2, support_w, tile_size/2], anchor=RIGHT+BOTTOM+FRONT);
					}
					down(tile_height/2) cuboid([tile_height, tile_height, tile_size], chamfer = corner_chamfer, except=[TOP], anchor=BOTTOM);
					zrot_copies([0, 90]) cuboid([tile_size/2, tile_height, tile_height], chamfer = corner_chamfer, except=[LEFT], anchor=RIGHT);
				}
				left(tile_size/2) xrot(45) zrot(-90) socket();
				zrot(90) left(tile_size/2) xrot(-45) zrot(-90) socket();
			}
		}

	}

   if (top_edge) {
      zrot_copies([0, 90]) xmove(-tile_size/4) up(y*tile_size/2) xrot(-90) edge(0.5);
      up(y*tile_size/2) xrot(-90) edge_corner();
   }
}

module grid_t(y, bottom_corner, top_edge)
{
	corner_chamfer = 0.4;
	difference() {
      union() {
         xrot(90) grid(1, y);
         zrot(90) xrot(90) left_half() grid(1, y);
      }
		if (!top_edge) up(tile_size*y/2) zrot(-45) xrot(-90) socket();
		if (!bottom_corner) down(tile_size*y/2) zrot(-45) xrot(90) socket();
	}

	if (bottom_corner) {
		down(y*tile_size/2 + tile_size/2) {
			difference() {
				union() {
					front_half() left_half() tile(); // bottom
					xrot(90) yrot_copies([0, 90]) back_half() left_half() tile();
					left(tile_height/2) cuboid([support_w, tile_size/2, tile_size/2], anchor=LEFT+BOTTOM+BACK);
					fwd(tile_height/2) cuboid([tile_size/2, support_w, tile_size/2], anchor=RIGHT+BOTTOM+FRONT);
					down(tile_height/2) cuboid([tile_height, tile_height, tile_size], chamfer = corner_chamfer, except=[TOP], anchor=BOTTOM);
					zrot_copies([0, 90]) cuboid([tile_size/2, tile_height, tile_height], chamfer = corner_chamfer, except=[LEFT], anchor=RIGHT);
				}
				left(tile_size/2) xrot(45) zrot(-90) socket();
				zrot(90) left(tile_size/2) xrot(-45) zrot(-90) socket();
			}
		}

	}

   if (top_edge) {
      zrot_copies([0, 90, 180]) xmove(-tile_size/4) up(y*tile_size/2) xrot(-90) edge(0.5);
   }
}

module edge_corner_a(size)
{
   fwd(tile_size/2) back_half() grid(size, 1);
}

render() {
	// Grid
	/*
	grid(grid_size_x, grid_size_y);
	snaps(grid_size_x, grid_size_y);

	if (true) translate([0, -grid_size_y * tile_size/2, 0]) edge_corner_a(grid_size_x);

	// Edges
	if (edge_bottom) translate([0, -grid_size_y * tile_size/2, 0]) edge(grid_size_x);
	if (edge_top) rotate(180) translate([0, -grid_size_y * tile_size/2, 0]) edge(grid_size_x);
	if (edge_right) rotate(90) translate([0, -grid_size_x * tile_size/2, 0]) edge(grid_size_y);
	if (edge_left) rotate(270) translate([0, -grid_size_x * tile_size/2, 0]) edge(grid_size_y);

	// Corners
	if (edge_left && edge_bottom) translate([-grid_size_x * tile_size/2, -grid_size_y * tile_size/2, 0]) corner();
	if (edge_top && edge_right) rotate(180) translate([-grid_size_x * tile_size/2, -grid_size_y * tile_size/2, 0]) corner();
	if (edge_right && edge_bottom) rotate(90) translate([-grid_size_y * tile_size/2, -grid_size_x * tile_size/2, 0]) corner();
	if (edge_left && edge_top) rotate(270) translate([-grid_size_y * tile_size/2, -grid_size_x * tile_size/2, 0]) corner();
	*/

	// Corner
	yrot(45+90) xrot(90) grid_corner(grid_size_y, false, false);
	//grid_t(grid_size_y, true, true);
         //zrot_copies([0,90]) xmove(14) xrot(90) grid(1, 2);

//left(3) fwd(10) xrot(90) half_joiner(w = 5, l = tile_height, base=15);
//right(3) fwd(10) xrot(90) half_joiner2(w = 5, l = tile_height, base=15);



}

