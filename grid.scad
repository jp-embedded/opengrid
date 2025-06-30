include<BOSL2/std.scad>;
include<BOSL2/math.scad>;
include <BOSL2/joiners.scad>
include <BOSL2/cubetruss.scad>

grid_size_x = 3;
grid_size_y = 2;

edge_left = false;
edge_right = false;
edge_back = false;
edge_front = false;
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
      if (!edge_front) ymove(-y*tile_size/2) xcopies(spacing = tile_size, n = x-1) socket();
      if (!edge_back) zrot(180) ymove(-y*tile_size/2) xcopies(spacing = tile_size, n = x-1) socket();
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
         if (!edge_front) ymove(-y*tile_size/2 + edge_dist) xcopies(spacing = tile_size, n = x) zrot(90) pin_double();
         if (!edge_back) zrot(180) ymove(-y*tile_size/2 + edge_dist) xcopies(spacing = tile_size, n = x) zrot(90) pin_double();
         if (!edge_right) zrot(90) ymove(-x*tile_size/2 + edge_dist) xcopies(spacing = tile_size, n = y) zrot(90) pin_double();
         if (!edge_left) zrot(270) ymove(-x*tile_size/2 + edge_dist) xcopies(spacing = tile_size, n = y) zrot(90) pin_double();
      }
   }
}

module edge(size)
{
   cuboid([size * tile_size, tile_edge_width, tile_height], chamfer = tile_chamfer, edges = FRONT, except = [LEFT, RIGHT], anchor=BACK);
}

module edge_corner()
{
   cuboid([tile_edge_width*2, tile_edge_width, tile_height], chamfer = tile_chamfer, except = BACK, anchor=BACK);
}

render() {
	// Grid
	grid(grid_size_x, grid_size_y);
	snaps(grid_size_x, grid_size_y);

   // Edges
   if (edge_front) translate([0, -grid_size_y * tile_size/2, 0]) edge(grid_size_x);
   if (edge_back) rotate(180) translate([0, -grid_size_y * tile_size/2, 0]) edge(grid_size_x);
   if (edge_right) rotate(90) translate([0, -grid_size_x * tile_size/2, 0]) edge(grid_size_y);
   if (edge_left) rotate(270) translate([0, -grid_size_x * tile_size/2, 0]) edge(grid_size_y);
   
   // Corners
   if (edge_left && edge_front) translate([-grid_size_x * tile_size/2, -grid_size_y * tile_size/2, 0]) edge_corner();
   if (edge_back && edge_right) rotate(180) translate([-grid_size_x * tile_size/2, -grid_size_y * tile_size/2, 0]) edge_corner();
   if (edge_right && edge_front) rotate(90) translate([-grid_size_y * tile_size/2, -grid_size_x * tile_size/2, 0]) edge_corner();
   if (edge_left && edge_back) rotate(270) translate([-grid_size_y * tile_size/2, -grid_size_x * tile_size/2, 0]) edge_corner();
}

