/// obj_chomper_mouse : Step
image_xscale = 1;
image_yscale = 1;

var plr = instance_nearest(x, y, obj_player);
if (!instance_exists(plr)) exit;

if (enemy_iframes > 0) enemy_iframes--;
if (hit_flash > 0) hit_flash--;

if (hit_flash > 0) image_blend = c_red;
else image_blend = c_white;

// helper: is player inside our semicircle + circle
function player_in_zone(_plr)
{
    var d = point_distance(ax, ay, _plr.x, _plr.y);
    if (d > cord_len) return false;

    var ang = point_direction(ax, ay, _plr.x, _plr.y);
    return abs(angle_difference(face_ang, ang)) <= arc_half;
}

// helper: clamp any world point to our allowed zone
function clamp_point_to_zone(_px, _py)
{
    var ang  = point_direction(ax, ay, _px, _py);
    var dist = point_distance(ax, ay, _px, _py);

    ang  = scr_angle_clamp(ang, face_ang, arc_half);
    dist = min(dist, cord_len);

    tx = ax + lengthdir_x(dist, ang);
    ty = ay + lengthdir_y(dist, ang);
}

// state machine
switch (state)
{
    case ST_IDLE:
    {
        // wait until player enters zone
        if (player_in_zone(plr)) {
            clamp_point_to_zone(plr.x, plr.y); // lock target position now
            state = ST_WAIT;
            timer = wait_frames;
        }
    } break;

    case ST_WAIT:
    {
        // telegraph delay (do NOT update target; it attacks where you were)
        timer--;
        if (timer <= 0) {
            state = ST_LUNGE;
        }

        // if player leaves zone during windup, cancel (optional, feels fair)
        if (!player_in_zone(plr)) {
            state = ST_IDLE;
        }
    } break;

    case ST_LUNGE:
    {
        // move toward locked target
        var ang = point_direction(x, y, tx, ty);
        var mx = lengthdir_x(lunge_speed, ang);
        var my = lengthdir_y(lunge_speed, ang);

        // X move with SAFE collision (no infinite loops)
        x += mx;
        if (place_meeting(x, y, solid_obj)) {
            x -= mx;
        }

        // Y move with SAFE collision
        y += my;
        if (place_meeting(x, y, solid_obj)) {
            y -= my;
        }

        // stop when close enough
        if (point_distance(x, y, tx, ty) <= lunge_speed + 0.5) {
            x = tx;
            y = ty;
            state = ST_REST;
            timer = rest_frames;
        }
		
		// Deal damage once per lunge if player is close
		if (!bite_did_hit) {
			if (point_distance(x, y, plr.x, plr.y) <= bite_hit_radius) {
				if (variable_instance_exists(plr, "player_take_stress")) {
					plr.player_take_stress(bite_damage, x, y);
					bite_did_hit = true;
				}
			}
		}

    } break;

    case ST_REST:
    {
        timer--;
        if (timer <= 0) {
            // lock next target if player still in zone; otherwise go idle
            if (player_in_zone(plr)) {
                clamp_point_to_zone(plr.x, plr.y);
                state = ST_WAIT;
				bite_did_hit = false;
                timer = wait_frames;
            } else {
                state = ST_IDLE;
            }
        }
    } break;
}