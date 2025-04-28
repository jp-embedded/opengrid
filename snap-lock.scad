lock = true;
lid = true;
stemfie = false;
MultiConnect_Thread = true; // for multiconnect thread
Vertical_Printing = false; // for vertical printing
Human_Pin = true; // for human pin
Draw_Rotated = false; // for rotated view
print_in_place = true;

cell_size = 28;
cell_wall_size = 1.5;
cell_height = 6.8;

cell_chamfer = 0.4;

screw_base = 8;

circle_snap = 0.0;

$fa = 1;
$fs = 0.4;

include <BOSL2/std.scad>
include <BOSL2/screws.scad>
include <BOSL2/joiners.scad>
include <Stemfie_OpenSCAD/stemfie.scad>

e = EPSILON;

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

//lid_height = 1;
lid_height = 1.4;
lock_height = tile_height/2 - lid_height;
thread_d = 18;

part_gap = 0.1;

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
	    grove_cyl ();

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
	
module thread(int = false)
{
	slope = 0.7; // same slope as cell grove

	w = 1.0 + (int ? part_gap : -part_gap);
	h = 2;
	pitch_a = 0.2;
	pitch_b = 0.1;
	cut_gap = 0.02; // cut out oversize in percent
	starts = print_in_place ? 4 : 2;
	turns = 0.25;
   echo(starts);
   echo(turns);

	// profile is scaled by pitch, so devide by pitch to get specefied size
	add_w = part_gap + e;
	prof_a = [
	    [ -1/pitch_a, -add_w/pitch_a ],	// the -1 is cut off below, part_gap subtracted to match cylinder
	    [ -1/pitch_a, w/pitch_a ],		// ""
	    [ (h - (w+add_w)/slope)/pitch_a, w/pitch_a ],
	    [ h/pitch_a, -add_w/pitch_a],	// part_gap subtracted to match cylinder
	];

	// for cut out
	prof_b = [
	    [ -1/pitch_b, -add_w/pitch_b ],	// the -1 is cut off below, part_gap subtracted to match cylinder
	    [ -1/pitch_b, w/pitch_b ],		// ""
	    [ 10/pitch_b, w/pitch_b ],
	    [ 10/pitch_b, -add_w/pitch_b],	// part_gap subtracted to match cylinder
	];

	dia = thread_d + (int ? part_gap : -part_gap);
	cyl(h = tile_height/2, d = dia, anchor=BOTTOM); // thread cylinder

	// thead
	difference() {
		//lead = int ? 0 : 1;
		lead = 0;
		union() {
			thread_helix(d=thread_d, pitch=pitch_a, turns=turns, starts=starts, profile=prof_a, lead_in=lead, left_handed=1, internal = int);

			// add thread at top. Only cut off in bottom needed
         if (!print_in_place) {
            thread_helix(d=thread_d, pitch=pitch_a, turns=turns, starts=starts, profile=prof_a, lead_in=lead, left_handed=0, internal = int);
         }
		}
		cyl(h = 50, d = 50, anchor=TOP); // cut off bottom part
	} 
 
	// insert cut off
	if (!print_in_place && int) {
		zrot(360/(starts*2) + 360/(starts*2) * cut_gap/2) thread_helix(d=thread_d, pitch=pitch_b, turns=turns * (1+cut_gap), starts=starts, profile=prof_b, left_handed=1, internal = int);

	}
}

module lid(multiconnect=false, printing=false) 
{
	difference() {
	union() {
	difference() {
		up(tile_height/2) cuboid([tile_size, tile_size, lid_height], anchor=TOP);
		tile();
	
		// Add gap between lid and lock
		chamf = 1;
		ring_r = 1.5;
		up(tile_height/2 - lid_height + part_gap) cyl(h = 2, d = thread_d + ring_r*2 + chamf*2 + part_gap, chamfer = chamf, anchor=TOP); // thread cylinder

		// arc cut out
		arc_w = 2.5;
		arc_d = 22;
		extra_angle = 5;
		up(lock_height-e) linear_extrude(height = 10) stroke(arc(d=arc_d, angle=45 + extra_angle, start = 22.5 - extra_angle/2), width=arc_w, $fn=75);


	}

	difference() { 
		zrot(45) thread();
		if (printing || !print_in_place) {
			// cut bottom of thread to make it printable standing
			fwd(thread_d/2 - 3) up(lock_height) cuboid([50, 50, lock_height*2+e], chamfer=lock_height, anchor=TOP+BACK); 
		}
	}

	}
	if (multiconnect) {
		multiconnect_thread();
	}
	}

}

module insert() 
{
	
	difference() {
		union() {
			// make lock smaller by part_gap except for ring below
			up(tile_height/2 - lid_height - part_gap) cuboid([tile_size, tile_size, lock_height - part_gap], anchor=TOP);

			// ring matching lid ring
			chamf = 1;
			ring_r = 1.5;
			up(tile_height/2 - lid_height) cyl(h = 2, d = thread_d + ring_r*2 + chamf*2 - part_gap, chamfer = chamf, anchor=TOP); // thread cylinder
		

		}
		tile();
		up(-e) zrot(45) thread(true);
		// arc cut out
		arc_w = 1.5;
		arc_d = 22;
		angle = 5;
		linear_extrude(height = 10) stroke(arc(d=arc_d, angle=angle, start = 22.5 - angle/2), width=arc_w, $fn=75);
		
	}



}

module lock(manual_pin=false) 
{
	union() {
		intersection() {
			down(e) insert();

		up(0.3) union() {
			// cylinder that fits inside tile
			grove_cyl();

			// Corners so it can only rotate 45 deg
			diff() cuboid([(tile_size-1.6)/2, (tile_size-1.6)/3, 4], anchor=LEFT+FRONT);
			rotate(90) diff() cuboid([(tile_size-1.6)/2, (tile_size-1.6)/3, 4], anchor=LEFT+FRONT);
			rotate(180) diff() cuboid([(tile_size-1.6)/2, (tile_size-1.6)/3, 4], anchor=LEFT+FRONT);
			rotate(270) diff() cuboid([(tile_size-1.6)/2, (tile_size-1.6)/3, 4], anchor=LEFT+FRONT);
		}

         union() {
            // Cut cornes so it can be inserted at 45 degree
            rotate(45) cuboid([cell_size - 3, cell_size - 3, lock_height - part_gap], chamfer =  0.4, anchor=BOTTOM);

            // Don't cut ring
            cyl(h = 10, d = tile_size - 4);
         }
		}

		if (manual_pin) {
	  		// pin to manually rotate the lock
			arc_w = 1;
			arc_d = 22;
			angle = 5;
			linear_extrude(height = tile_height/2+1) stroke(arc(d=arc_d, angle=angle, start = 22.5 - angle/2), width=arc_w, $fn=75);
			linear_extrude(height = lock_height+e) stroke(arc(d=arc_d, angle=angle, start = 22.5 + angle/2), width=arc_w/2, $fn=75);
		}
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

	down(2*e) generic_threaded_rod(d=16.5, l=tile_height, pitch=3, profile=profile, blunt_start=false, $fn=50, anchor=BOTTOM);
}

render() {
	RotAngle = Draw_Rotated ? -45 : 0;
	if(lid) zrot(RotAngle) up(0) lid(multiconnect=MultiConnect_Thread, printing=Vertical_Printing);
	if(lock) lock(manual_pin=Human_Pin);
	if(stemfie) {
		back(cell_height/2 - e) xrot(90) lid();
		down(tile_size/2 - tile_edge_width - BU/2) fwd(BU * 3) zrot(90) beam_block(6);
	}
}



