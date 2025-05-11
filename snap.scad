lock = true;
lid = true;
MultiConnect_Thread = false; // for multiconnect thread
part_gap = 0.2;
part_gap_bottom = 0.2;
directional = false;

/* [For debugging] */

tile = false;
cross_view = false;
Draw_Locked = false; // for rotated view

/* [Hidden] */

stemfie = false;
Vertical_Printing = false; // for vertical printing
Human_Pin = false; // for human pin
Human_Pin_Alt = false; // Test for alternative human pin
print_in_place = true;

cell_size = 28;
cell_wall_size = 1.5;
cell_height = 6.8;

cell_chamfer = 0.4;

screw_base = 8;

circle_snap = 0.0;

$fa = 2;
$fs = 0.4;

include <BOSL2/std.scad>
include <BOSL2/screws.scad>
include <BOSL2/joiners.scad>
include <Stemfie_OpenSCAD/stemfie.scad>

e = EPSILON;

tile_size = 28;
tile_height = 6.8;
tile_edge_width = 1.5;
tile_chamfer = 0.4;

snap_l = tile_height/2;
snap_w = 5;
snap_h = 3;
snap_depth = 0.25;
snap_compression = 0.1;

lid_height = 1.4;
lock_height = tile_height/2 - lid_height;
thread_d = 18;

ring_r = 2;

// recess in lid to make thread stronger
ring_h = part_gap;
//ring_h = 0;

pin_width = 3;
pin_arc_d = 20;


module tile(grove = true, chamfer = true)
{
    chamf = chamfer ? tile_chamfer : 0;
    difference() {
        // rect tube
        cuboid([tile_size+e, tile_size+e, tile_height]); 
        cuboid([tile_size-tile_edge_width*2, tile_size-tile_edge_width*2, tile_height+e], chamfer = -chamf);

        // grove
        if (grove) diff() cuboid([tile_size-1.6, tile_size-1.6, 4]) edge_profile() mask2d_chamfer(x = 0.7, y = 1);
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
         up(cell_height/4 - e) tile(chamfer=false);
      }

      // cut chamfer at corners
      diag = sqrt(cell_size^2 + cell_size^2);
      inner_corner = (sqrt(4.2^2 + 4.2^2)/2 + 2.6);
      inner_diag = diag - inner_corner * 2;
      rotate(45) cuboid([inner_diag, inner_diag, 10], except=[TOP,BOTTOM]);
   }
}


// cylinder that fits inside tile grove. Same height and edge profile as tile grove
module grove_cyl(h = 4)
{
	slope = 0.7;
	inside_dia = cell_size - 1.6;
	chamf_h = h/2 - 1;
	chamf_w = chamf_h * slope; 
	diff() cyl(h = h, d = inside_dia + circle_snap) edge_profile() mask2d_chamfer(x = chamf_w, y = chamf_h);
}

module corner_cyl(h = 4)
{
	// sizes here just set to eyeball
	slope = 1.1;
	d = cell_size - 1;
	chamf_h = h/2 - 1;
	chamf_w = chamf_h * slope; 
	diff() cyl(h = h, d = d) edge_profile() mask2d_chamfer(x = chamf_w, y = chamf_h);
}

// cube that fits inside tile grove. Same height and edge profile as tile grove
module grove_cube()
{
	h = tile_height;
	inside_dia = cell_size - 1.6;
	chamf_h = h/2 - 1;
	chamf_w = chamf_h * 0.7; 
	diff() cuboid([inside_dia, inside_dia, h]) edge_profile() mask2d_chamfer(x = chamf_w, y = chamf_h);
	cuboid([tile_size - 3, tile_size - 3, h]);
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
	slope = 1; // same slope as cell grove

	w = 1.0 + (int ? part_gap : -part_gap);
	h = 2;
	pitch_a = 1.5;
	pitch_b = 0.1;
	cut_gap = 0.02; // cut out oversize in percent
	starts = print_in_place ? 1 : 2;
	turns = print_in_place ? 0.999 : 0.25; // will fail for 1 turn since the begin and end collide

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
         if (print_in_place) {
            zrot(247.5) thread_helix(d=thread_d, pitch=pitch_a, turns=turns, starts=starts, profile=prof_a, lead_in=lead, left_handed=1, internal = int, $fn=128);

            // fix the tiny gap becasue turns is just uder 1
            zrot(247) thread_helix(d=thread_d, pitch=pitch_a, turns=turns, starts=starts, profile=prof_a, lead_in=lead, left_handed=1, internal = int, $fn=128);
         }
         else {
            thread_helix(d=thread_d, pitch=pitch_a, turns=turns, starts=starts, profile=prof_a, lead_in=lead, left_handed=1, internal = int, $fn=128);
         }

			// add thread at top. Only cut off in bottom needed
         if (!print_in_place) {
            thread_helix(d=thread_d, pitch=pitch_a, turns=turns, starts=starts, profile=prof_a, lead_in=lead, left_handed=0, internal = int, $fn=128);
         }
		}
		cyl(h = 50, d = 50, anchor=TOP); // cut off bottom part
	} 
 
	// insert cut off
	if (!print_in_place && int) {
		zrot(360/(starts*2) + 360/(starts*2) * cut_gap/2) thread_helix(d=thread_d, pitch=pitch_b, turns=turns * (1+cut_gap), starts=starts, profile=prof_b, left_handed=1, internal = int, $fn=128);
	}
	if (print_in_place && int) {
      t = 1/8 + cut_gap;
		zrot(247.5 + (360 * cut_gap / 2)) thread_helix(d=thread_d, pitch=pitch_b, turns=t * (1+cut_gap), starts=starts, profile=prof_b, left_handed=1, internal = int, $fn=128);
	}
}

module thread2(int = false)
{
	slope = 1.0;

	w = 1.0 + (int ? part_gap : -part_gap);
	h = 2;
	pitch_a = 1;
	pitch_b = 0.1;
	cut_gap = 0.02; // cut out oversize in percent
	starts = 1;
	turns = 1 / starts - 0.001;

	// profile is scaled by pitch, so devide by pitch to get specefied size
	add_w = part_gap + e;
	prof_a0 = [
		[ -1/pitch_a, -add_w/pitch_a ],	// the -1 is cut off below, part_gap subtracted to match cylinder
		[ -1/pitch_a, w/pitch_a ],		// ""
		[ (h - (w+add_w)/slope)/pitch_a, w/pitch_a ],
		[ h/pitch_a, -add_w/pitch_a],	// part_gap subtracted to match cylinder
	];
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

				dia = thread_id + (int ? part_gap : -part_gap);
				cyl(d = dia, height = tile_height/2, anchor=BOTTOM);

				// thead
				difference() {
					//lead = int ? 0 : 1;
					lead = 0;
					union() {
						up(0.5) zrot(247.5) thread_helix(d=thread_id, pitch=pitch_a, turns=turns, starts=starts, profile=prof_a, lead_in=lead, left_handed=1, internal = int, $fn=128);

						// fix the tiny gap becasue turns is just uder 1
						//up(1) zrot(247) thread_helix(d=thread_id, pitch=pitch_a, turns=turns, starts=starts, profile=prof_a, lead_in=lead, left_handed=1, internal = int, $fn=128);
					}
					// cut off top & bottom part
					up(tile_height/2) cyl(h = 50, d = 50, anchor=BOTTOM); 
					cyl(h = 50, d = 50, anchor=TOP); 
				} 

				// insert cut off
				if (int) {
					t = 1/8 + cut_gap;
					down(7.5) zrot(247.5 + (360 * cut_gap / 2)) thread_helix(d=thread_id, pitch=pitch_b, turns=t * (1+cut_gap), starts=starts, profile=prof_b, left_handed=1, internal = int, $fn=128);
				}
}

module thread3(int = false)
{
   difference() {
      union() {
         h = tile_height/2; // 3.4
         slope = 0.7;
         chamf_h = 1;
         chamf_w = chamf_h * slope; 
         gap = int ? part_gap : -part_gap;
         dia = thread_id + gap;

         // center cylinder
         cyl(d = dia, height = tile_height/2, anchor=BOTTOM);

         // thread
         up(0.5 - gap/2 / slope /*no gap on horontal part*/) diff() cyl(h = h, d = dia + chamf_w*2) edge_profile() mask2d_chamfer(x = chamf_w, y = chamf_h);
      }

      // cut off top & bottom part
      up(tile_height/2) cyl(h = 50, d = 50, anchor=BOTTOM); 
      cyl(h = 50, d = 50, anchor=TOP); 

   }
}

module lid(multiconnect=false, printing=false) 
{
	difference() {
		union() {
			difference() {
				up(tile_height/2) cuboid([tile_size, tile_size, lid_height], anchor=TOP);
				tile(chamfer=false);

				// Add gap between lid and lock
				if (ring_h > 0) {
					chamf = 1;
					up(tile_height/2 - lid_height + part_gap) cyl(h = 2, d = thread_d + ring_r*2 + chamf*2 + part_gap, chamfer = chamf, anchor=TOP); // thread cylinder


				}

				// arc cut out
				if (Human_Pin_Alt) {
					arc_w = pin_width + 0.5;
					extra_angle = 5;
					up(lock_height-e) linear_extrude(height = 10) stroke(arc(d=pin_arc_d, angle=45 + extra_angle, start = 45 + 22.5 - extra_angle/2), width=arc_w, $fn=75);
					// cut the sharp top 
					a = 45 * 0.9;
					//up(lock_height-e) linear_extrude(height = 5) stroke(arc(d=pin_arc_d+arc_w, angle=a, start = 90 - a/2), width=arc_w/2, endcaps = "square", $fn=75);
				}
				else {
					arc_w = 2.5;
					arc_d = 22;
					extra_angle = 5;
					up(lock_height-e) linear_extrude(height = 10) stroke(arc(d=arc_d, angle=45 + extra_angle, start = 22.5 - extra_angle/2), width=arc_w, $fn=75);
				}


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
			if (ring_h > 0) {
				chamf = 1;
				up(tile_height/2 - lid_height - part_gap + ring_h) cyl(h = 2, d = thread_d + ring_r*2 + chamf*2 - part_gap, chamfer = chamf, anchor=TOP); // thread cylinder
			}
		

		}
		tile(chamfer=false);
		up(-e) zrot(45) thread(true);

      if (!Human_Pin_Alt) {
         // arc cut out
         arc_w = 1.5;
         arc_d = 22;
         angle = 5;
         linear_extrude(height = 10) stroke(arc(d=arc_d, angle=angle, start = 22.5 - angle/2), width=arc_w, $fn=75);
      }
		
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
			if (Human_Pin_Alt) {
				// pin to manually rotate the lock
				angle = 5;
				angle2 = 2;
				recess = 0.5;
				difference() {
					up(lock_height - part_gap - recess/2 - e) linear_extrude(height = lid_height + part_gap - recess) stroke(arc(d=pin_arc_d, angle=angle, start = 45 + 22.5 - angle/2), width=pin_width, $fn=75);
					up(tile_height/2 - 0.5 - recess) linear_extrude(height = 0.5) stroke(arc(d=pin_arc_d, angle=angle2, start = 45 + 22.5 - angle2/2), width=pin_width, endcap_length = 0, $fn=75);
				}
			}
			else {
				// pin to manually rotate the lock
				arc_w = 1;
				arc_d = 22;
				angle = 5;
				linear_extrude(height = tile_height/2+1) stroke(arc(d=arc_d, angle=angle, start = 22.5 - angle/2), width=arc_w, $fn=75);
				linear_extrude(height = lock_height+e) stroke(arc(d=arc_d, angle=angle, start = 22.5 + angle/2), width=arc_w/2, $fn=75);
			}
		}
	}
}

module supports()
{
	support_h = 0.2;
	support_w = 0.5;

	/*
	zrot_copies(n = 4) {
		r0 = cell_size/2 - 3.2;
		a0 = 2/20 * 360;
		up(lock_height - part_gap) arc_copies(r=r0, n=3, sa=-a0/2, ea=a0/2) cube(size=[6,support_w,support_h],center=true);
		up(lock_height - part_gap + support_h) arc_copies(r=r0+3-support_w/2, n=3, sa=-a0/2, ea=a0/2) cube(size=[support_w,support_w,support_h],center=true);

		a1 = 1/20 * 360;
		r1 = cell_size/2 - 4.5;
		zrot(45) up(lock_height - part_gap) arc_copies(r=r1, n=2, sa=-a1/2, ea=a1/2) cube(size=[6,support_w,support_h],center=true);
		zrot(45) up(lock_height - part_gap + support_h) arc_copies(r=r1+3-support_w/2, n=2, sa=-a1/2, ea=a1/2) cube(size=[support_w,support_w,support_h],center=true);
	}
	*/
	zrot_copies(n = 4) {
		r0 = cell_size/2 - 4.4;
		a0 = 2/20 * 360;
		up(lock_height - part_gap + support_h/2) arc_copies(r=r0+3-support_w/2, n=3, sa=-a0/2, ea=a0/2) cube(size=[support_w,support_w,support_h],center=true);

		a1 = 1/20 * 360;
		r1 = cell_size/2 - 5;
		zrot(45) up(lock_height - part_gap + support_h/2) arc_copies(r=r1+3-support_w/2, n=2, sa=-a1/2, ea=a1/2) cube(size=[support_w,support_w,support_h],center=true);
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

edge_side = 0.5;
edge_bottom = 0.6;
thread_id = 18;
thread_od = tile_size - 3 - edge_side;

// insert that can rotate
module round_insert()
{
	grove_cyl(tile_height);
	cyl(d = tile_size - 3, height = cell_height);
}

module lid_cut(lock = true)
{
	gap = lock ? -part_gap_bottom : part_gap_bottom;
	up(gap) corner_cyl(tile_height);
	cyl(d = thread_od + gap, height = cell_height);
}

module case()
{
     difference() {

		// insert
		cuboid([tile_size, tile_size, tile_height/2+e], anchor=BOTTOM);
		tile(grove = false);

		difference() {
			lid_cut(false);
			//up(edge_bottom - part_gap_bottom/2) cuboid([tile_size, tile_size, tile_height], anchor=TOP);
			zrot(45) up(edge_bottom - part_gap_bottom/2) cuboid([10, tile_size, tile_height], anchor=TOP);
			zrot(90+45) up(edge_bottom - part_gap_bottom/2) cuboid([10, tile_size, tile_height], anchor=TOP);
		}

      up(edge_bottom + e) cuboid([50, part_gap, 10], anchor = BOTTOM);
      zrot(90) up(edge_bottom + e) cuboid([50, part_gap, 10], anchor = BOTTOM);

	}

	// thread
	zrot(45) thread3(false);
}


module lock2()
{
	h = cell_height/2 - edge_bottom - part_gap_bottom/2;

	lift = 0;	

	up(lift) difference() {

		union() {
			intersection() {
				// Make insert that can rotate 45 degrees
				zrot_copies(n = 4) {
					right_half() zrot(-45) front_half() round_insert();
					zrot(-45) right_half() zrot(-45) front_half() grove_cube();
				}
				// Cut cornes so it can be inserted at 45 degree
				rotate(45) cuboid([cell_size - 3, cell_size - 3, tile_height], anchor=BOTTOM);

				lid_cut();
			}
		}
		up(edge_bottom + part_gap_bottom/2) cuboid([50, 50, 10], anchor=TOP); // cut bottom
		
		up(tile_height/2 - lift) cuboid([50, 50, 10], anchor=BOTTOM); // cut lifted top

		// thread
		zrot(45) thread3(true);

		angle2 = 20;
		recess = 1;
		up(tile_height/2 - recess) linear_extrude(height = 2) stroke(arc(d=(thread_id+thread_od)/2, angle=angle2, start = 45 + 22.5 - angle2/2), width=(thread_od-thread_id)/2, endcap_length = 0);
	}

}

module pip()
{
	difference() {
		union() {
			RotAngle = Draw_Locked ? 0 : 45;
			//RotAngle = Draw_Locked ? 0 : -65;
			if(lid) case();
			if(lock) zrot(RotAngle) lock2();
			if(tile) tile();
		}

		if (MultiConnect_Thread) multiconnect_thread();
	}

}

module lock3() 
{
   difference() {

      // insert
      cuboid([tile_size, tile_size, tile_height/2+e], anchor=BOTTOM);
      tile(grove = true);

      intersection() {
         cuboid([thread_d, thread_d, tile_height/2+e], anchor=BOTTOM);
         zrot(45) cuboid([thread_d, thread_d, tile_height/2+e], anchor=BOTTOM);
      }

   }
      //cuboid([tile_size, tile_size, tile_height/2+e], anchor=LEFT+BOTTOM);
}

module top_snap()
{
   difference() {

      // insert
      left(tile_size/2) cuboid([2, tile_size, tile_height/2+e], anchor=BOTTOM+LEFT);
      tile(grove = true);
   }

}

module side_snap()
{
   snap_l = 5;
   flatten = 0.4;
   difference() {
      left(tile_size/2 - 1.5) diff() cuboid([1.4, snap_l, 2], anchor=BOTTOM) edge_profile(except=[FRONT+TOP,FRONT+BOTTOM,BACK+TOP,BACK+BOTTOM]) mask2d_chamfer(x = 0.7, y = 1);
      left(tile_size/2 - 1.5 + 1.4 - flatten) cuboid([1.4, snap_l, 2], anchor=BOTTOM);
   }

}

module lock4() 
{
	difference() {

		// insert
		cuboid([tile_size, tile_size, tile_height/2+e], anchor=BOTTOM);
		tile(grove = false);

		// cut bottom to make it printable
		chamf = tile_height/2;
		x = tile_size/2 - cell_wall_size + cell_chamfer - chamf;
		right(x) cuboid([tile_size, tile_size, tile_height+e], chamfer = chamf, anchor=LEFT);

		if (!directional) {
			// cut top to make it symetrical
			zrot(180) right(x) cuboid([tile_size, tile_size, tile_height+e], chamfer = chamf, anchor=LEFT);
		}

		// cut for snap
		down(0.5) {
			zrot(-90) right(tile_size/2 - 2.7) cuboid([0.5, 14, tile_height+e], anchor=LEFT);
			zrot(90) right(tile_size/2 - 2.7) cuboid([0.5, 14, tile_height+e], anchor=LEFT);
		}

		//top_snap();
		zrot(-90) side_snap();
		zrot(90) side_snap();

		if (directional) {
			// cut corners a bit for angled insert
			c = adj_opp_to_hyp(4.2, 4.2) / 2 + 2.6;
			cut_h = 0.5;
			cut_a = 10;
			up(cut_h) move([tile_size/2, tile_size/2, 0]) zrot(45) yrot(cut_a) cuboid([c*2, 100, tile_height], anchor=TOP);
			zrot(-90) up(cut_h) move([tile_size/2, tile_size/2, 0]) zrot(45) yrot(cut_a) cuboid([c*2, 100, tile_height], anchor=TOP);
		}
	}
	if (directional) {
		top_snap();
	}
}

module slide_lock()
{
   lock3();
}

module snap()
{
   lock4();
}

module corner(h)
{
   //corner_chamfer = 0.4;
   corner_chamfer = 1;

   cuboid([tile_size/2, tile_height, tile_size*h], anchor=LEFT); // wall
   zrot(90) cuboid([tile_size/2, tile_height, tile_size*h], anchor=LEFT); // wall
   cuboid([tile_height, tile_height, tile_size*h], chamfer = corner_chamfer, except=[TOP,BOTTOM]); // corner
   back(tile_size) yrot(90) snap();

}

module stemfie()
{
	beam_holes = 5;
	yrot(90) snap();
	down(tile_size/2 - tile_edge_width - BU/2 + 0.4) right(BU * beam_holes/2 + tile_height/2 - 0.3) beam_block(beam_holes, holes=[true, false, true]);
}

render() {
   //corner(3);
   stemfie();
}



