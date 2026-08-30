/// obj_cookie_small : Step

var plr = instance_nearest(x, y, obj_player);
if (!instance_exists(plr)) exit;

var d = point_distance(x, y, plr.x, plr.y);

if (enemy_iframes > 0) enemy_iframes--;
if (hit_flash > 0) hit_flash--;

if (hit_flash > 0) image_blend = c_red;
else image_blend = c_white;

switch (state)
{
    // -------------------------
    case ST_MOVE:
    {
        // Simple homing
        if (d <= aggro_range) {
            var ang = point_direction(x, y, plr.x, plr.y);
            vx = lengthdir_x(move_spd, ang);
            vy = lengthdir_y(move_spd, ang);
        } else {
            vx *= 0.9;
            vy *= 0.9;
        }

        var v = scr_move_and_collide(vx, vy, solid_obj);
        vx = v[0];
        vy = v[1];

        // Close enough → arm explosion
        if (d <= explode_range) {
            state = ST_ARMED;
            timer = explode_delay;
            vx = 0;
            vy = 0;
			boom_did_damage = false;
        }
    } break;

    // -------------------------
    case ST_ARMED:
    {
        // Frozen in place
        vx = 0;
        vy = 0;

        timer--;
        if (timer <= 0) {
            state = ST_BOOM;
            timer = 10; // short boom linger
        }
    } break;

    // -------------------------
	case ST_BOOM:
	{
		// Deal explosion damage once when BOOM starts
		if (!boom_did_damage) {			
			boom_did_damage = true;

			if (point_distance(x, y, plr.x, plr.y) <= boom_radius) {
				if (variable_instance_exists(plr, "player_take_stress")) {
					plr.player_take_stress(boom_damage, x, y);
				}
			}
		}

		timer--;
		if (timer <= 0) {
		  instance_destroy();
		}
	} break;

}