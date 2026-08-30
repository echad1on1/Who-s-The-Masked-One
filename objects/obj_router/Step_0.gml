/// obj_router : Step

// --- damage timers / feedback ---
if (enemy_iframes > 0) enemy_iframes--;
if (hit_flash > 0) hit_flash--;
if (wifi_iframes > 0) wifi_iframes--;

if (hit_flash > 0) image_blend = c_red;
else image_blend = c_white;

// (Optional) toggle debug quickly while testing
if (keyboard_check_pressed(ord("F"))) debug_draw = !debug_draw;

// Cycle the wave phases forever
phase_timer--;

if (phase_timer <= 0) {
    switch (phase) {
        case PHASE_ARC1:
            phase = PHASE_ARC2;
            phase_timer = arc_frames;
        break;

        case PHASE_ARC2:
            phase = PHASE_ARC3;
            phase_timer = arc_frames;
        break;

        case PHASE_ARC3:
            phase = PHASE_GAP;
            phase_timer = gap_frames;
        break;

        case PHASE_GAP:
            phase = PHASE_ARC1;
            phase_timer = arc_frames;
        break;
    }
}

// --- WIFI DAMAGE CHECK (outside phone, always) ---
var plr = instance_nearest(x, y, obj_player);
if (instance_exists(plr) && wifi_iframes <= 0) {

    // Only deal damage during arc phases (not during gap)
    if (phase != PHASE_GAP) {

        // Pick current radius based on phase
        var r = arc_r1;
        if (phase == PHASE_ARC2) r = arc_r2;
        if (phase == PHASE_ARC3) r = arc_r3;

        // Two emitters: left and right
        for (var s = -1; s <= 1; s += 2) {

            var ex = x + s * emit_side_offset;
            var ey = y;

            var outward = (s == 1) ? 0 : 180;
            var a0 = outward - arc_half_angle;
            var a1 = outward + arc_half_angle;

            // Check if player is near the arc at this radius:
            // 1) near the circle of radius r around emitter
            // 2) within the arc angle range
            var d = point_distance(ex, ey, plr.x, plr.y);
            if (abs(d - r) <= wifi_hit_radius) {

                var angp = point_direction(ex, ey, plr.x, plr.y);
                if (abs(angle_difference(outward, angp)) <= arc_half_angle) {

                    // apply player stress via gate
                    if (variable_instance_exists(plr, "player_take_stress")) {
                        plr.player_take_stress(wifi_damage, ex, ey);
                        wifi_iframes = wifi_iframes_max; // per-router cooldown
                        break;
                    }
                }
            }
        }
    }
}
