/// obj_bug : Step

var plr = instance_nearest(x, y, obj_player);
if (!instance_exists(plr)) exit;

var d = point_distance(x, y, plr.x, plr.y);

// Acquire target
if (state == ST_IDLE) {
    if (d <= aggro_range) state = ST_CHASE;
}

// --- damage timers / feedback ---
if (enemy_iframes > 0) enemy_iframes--;
if (hit_flash > 0) hit_flash--;

// flash
if (hit_flash > 0) image_blend = c_red;
else image_blend = c_white;

// State machine
switch (state)
{
    case ST_IDLE:
    {
        vx *= 0.8;
        vy *= 0.8;
		// apply knockback channel
		vx += kb_vx;
		vy += kb_vy;
		kb_vx *= kb_fric;
		kb_vy *= kb_fric;

        var v0 = scr_move_and_collide(vx, vy, solid_obj);
        vx = v0[0]; vy = v0[1];
    } break;

    case ST_CHASE:
    {
        // If close enough, begin flank phase (more interesting than straight-line)
        if (d <= flank_range) {
            state = ST_FLANK;
            timer = flank_time;
            flank_dir = choose(-1, 1);
            break;
        }

        // Direction to player
        var ang = point_direction(x, y, plr.x, plr.y);

        // Wiggle sideways: add 90 degrees and oscillate
        wiggle_t += wiggle_freq;
        var wig = sin(wiggle_t) * wiggle_amp;

        var ax = lengthdir_x(move_spd, ang);
        var ay = lengthdir_y(move_spd, ang);

        var sx = lengthdir_x(wig, ang + 90);
        var sy = lengthdir_y(wig, ang + 90);

        var tvx = ax + sx;
        var tvy = ay + sy;

        // Smooth steering
        vx = lerp(vx, tvx, turn_lerp);
        vy = lerp(vy, tvy, turn_lerp);
		// apply knockback channel
		vx += kb_vx;
		vy += kb_vy;
		kb_vx *= kb_fric;
		kb_vy *= kb_fric;

        var v1 = scr_move_and_collide(vx, vy, solid_obj);
        vx = v1[0]; vy = v1[1];

        // If player escaped far, stay chasing
        if (d > aggro_range * 1.2) state = ST_IDLE;
    } break;

    case ST_FLANK:
    {
        // Circle player: move roughly tangentially instead of directly at them
        // Tangent angle = angle to player +/- 90
        var ang_to = point_direction(x, y, plr.x, plr.y);
        var tang = ang_to + flank_dir * 90;

        // Slight inward pull so it doesn't spiral out
        var pull = 0.6;
        var tvx = lengthdir_x(move_spd, tang) + lengthdir_x(pull, ang_to);
        var tvy = lengthdir_y(move_spd, tang) + lengthdir_y(pull, ang_to);

        vx = lerp(vx, tvx, turn_lerp);
        vy = lerp(vy, tvy, turn_lerp);
		// apply knockback channel
		vx += kb_vx;
		vy += kb_vy;
		kb_vx *= kb_fric;
		kb_vy *= kb_fric;

        var v2 = scr_move_and_collide(vx, vy, solid_obj);
        vx = v2[0]; vy = v2[1];

        timer--;
        if (timer <= 0) {
            // Lock target and wind up for pounce
            tx = plr.x;
            ty = plr.y;
            state = ST_WINDUP;
            timer = windup_time;
            vx = 0; vy = 0;
        }
    } break;

    case ST_WINDUP:
    {
        // Stands still (telegraph)
        vx = 0; vy = 0;

        // Optional: refresh target slightly during windup (harder)
        // tx = plr.x; ty = plr.y;

        timer--;
        if (timer <= 0) {
            state = ST_POUNCE;
            timer = pounce_time;
			pounce_did_hit = false;
        }
    } break;

    case ST_POUNCE:
    {
        // Lunge toward locked point (last known position)
        var ang = point_direction(x, y, tx, ty);
        vx = lengthdir_x(pounce_spd, ang);
        vy = lengthdir_y(pounce_spd, ang);
		// apply knockback channel
		vx += kb_vx;
		vy += kb_vy;
		kb_vx *= kb_fric;
		kb_vy *= kb_fric;

        var v3 = scr_move_and_collide(vx, vy, solid_obj);
        vx = v3[0]; vy = v3[1];

		// Damage player once per pounce if close enough
		if (!pounce_did_hit) {
			if (point_distance(x, y, plr.x, plr.y) <= pounce_hit_radius) {
				if (variable_instance_exists(plr, "player_take_stress")) {
					plr.player_take_stress(pounce_damage, x, y);
					pounce_did_hit = true;
				}
			}
		}

        timer--;
        if (timer <= 0) {
            state = ST_COOLDOWN;
            timer = cooldown_time;
            vx = 0; vy = 0;
        }
    } break;

    case ST_COOLDOWN:
    {
        // Brief pause after attack
        vx = 0; vy = 0;
        timer--;
        if (timer <= 0) {
            // Go back to chase if player still close
            if (d <= aggro_range) state = ST_CHASE;
            else state = ST_IDLE;
        }
    } break;
}
