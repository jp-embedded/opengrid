include<BOSL2/std.scad>;
include<BOSL2/math.scad>;
include <BOSL2/joiners.scad>

grid_size_x = 3;
grid_size_y = 2;

edge_left = true;
edge_right = false;
edge_top = true;
edge_bottom = false;
snaps = true;


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

module pin()
{
   rabbit_clip(type="pin",length=4, width=5,snap=snap_depth,thickness=0.8, depth=2, compression=0.3,lock=false);
}

module pin_double()
{
   rabbit_clip(type="double",length=4, width=5,snap=snap_depth,thickness=0.8, depth=2, compression=0.3,lock=false);
}

module socket()
{
   // 2*e - tile already has 1*e oversize
   ymove(-e*2) xrot(90) 
      rabbit_clip(type="socket",length=4, width=5,snap=snap_depth,thickness=0.8, depth=2.4, lock=false,compression=0);
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

   // Snaps
   if (snaps) {
      edge_dist = 7;
      zmove(-tile_height/2) {
         if (!edge_bottom) ymove(-y*tile_size/2 + edge_dist) xcopies(spacing = tile_size, n = x) pin_double();
         if (!edge_top) zrot(180) ymove(-y*tile_size/2 + edge_dist) xcopies(spacing = tile_size, n = x) pin_double();
         if (!edge_right) zrot(90) ymove(-x*tile_size/2 + edge_dist) xcopies(spacing = tile_size, n = y) pin_double();
         if (!edge_left) zrot(270) ymove(-x*tile_size/2 + edge_dist) xcopies(spacing = tile_size, n = y) pin_double();
      }
   }
}

// Grid
grid(grid_size_x, grid_size_y);


module edge(size)
{
   cuboid([size * tile_size, tile_edge_width, tile_height], chamfer = tile_chamfer, edges = FRONT, except = [LEFT, RIGHT], anchor=BACK);
}

module corner()
{
   cuboid([tile_edge_width + e, tile_edge_width + e, tile_height], chamfer = tile_chamfer, edges = [FRONT,LEFT], except = [RIGHT,BACK], anchor=BACK+RIGHT);
}


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

