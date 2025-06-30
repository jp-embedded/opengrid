include<BOSL2/std.scad>;
include<BOSL2/math.scad>;
include <BOSL2/joiners.scad>
include <BOSL2/cubetruss.scad>

length = 3;
edge_a = "corner"; // [ "none", "corner", "edge"]
edge_b = "none"; // [ "none", "corner", "edge"]
snaps = "clip"; // [ "none", "clip", "rabbit"]

/* [Hidden] */

edge_left = false;
edge_right = false;
edge_top = false;
edge_bottom = false;

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

module edge(size)
{
   cuboid([size * tile_size, tile_edge_width, tile_height], chamfer = tile_chamfer, edges = FRONT, except = [LEFT, RIGHT], anchor=BACK);
}

module edge_corner(size)
{
   cuboid([tile_height, tile_edge_width, tile_height], chamfer = tile_chamfer, except = BACK, anchor=BACK);
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

corner_chamfer = 0.4;
support_inside = false;

module grid_corner_corner(y)
{
   down(y*tile_size/2 + tile_size/2) {
      difference() {
         union() {
            top_half() grid_corner_straight(1, support_inside);
            left(tile_size/2) xrot(45) zrot(-90) socket();

            // bottom
            front_half() left_half() tile();
            intersection() {
               zrot_copies([0, 90]) cuboid([50, tile_height, tile_height], chamfer = corner_chamfer, except=[LEFT]);
               back(tile_height/2) right(tile_height/2) cuboid([tile_size/2+tile_height/2, tile_size/2+tile_height/2, tile_height], chamfer = 3, except=[TOP,FRONT,LEFT], anchor=RIGHT+BACK);
            }
            down(tile_height/2) cuboid([tile_size/2, tile_size/2, support_w], anchor=RIGHT+BACK+BOTTOM);
         }

         left(tile_size/2) xrot(45) zrot(-90) socket();
         zrot(90) left(tile_size/2) xrot(-45) zrot(-90) socket();
      }
   }
}

module grid_corner_edge(y)
{
   zrot_copies([0, 90]) xmove(-tile_size/4) up(y*tile_size/2) xrot(-90) edge(0.5);
   intersection() {
      up(y*tile_size/2) xrot(-90) edge_corner();
      // todo: calculate the fwd correctly
      up(y*tile_size/2) zrot(-45) fwd(3/4 - 0.04) xrot(-90) edge(1);
   }
}

module grid_corner(y, end_a, end_b)
{

	difference() {
		grid_corner_straight(y, support_inside);
		if (end_b == "none") up(tile_size*y/2) zrot(-45) xrot(-90) socket();
		if (end_a == "none") down(tile_size*y/2) zrot(-45) xrot(90) socket();
	}

	if (end_a == "corner") grid_corner_corner(y);
	if (end_b == "corner") zrot(90) xrot(180) grid_corner_corner(y);

   if (end_a == "edge") zrot(90) xrot(180) grid_corner_edge(y);
   if (end_b == "edge") grid_corner_edge(y);
}

module edge_corner_a(size)
{
   fwd(tile_size/2) back_half() grid(size, 1);
}

render() {
	// Corner
	yrot(45+90) xrot(90) grid_corner(length, edge_a, edge_b);
}

