/// obj_player : Draw
// --- Pickup prompt ---
var pick = instance_nearest(x, y, obj_weapon_pickup);
if (instance_exists(pick) && point_distance(x, y, pick.x, pick.y) <= pickup_range) {
    draw_set_color(c_white);
    draw_text(x - 30, y - 50, "E: Pick up " + pick.weapon_name);
}

// flash red when hit
if (hit_flash > 0 && !godmode) image_blend = c_red;
else image_blend = c_white;

draw_self();

// --- Ruler debug reach (only when holding ruler or umbrella) ---
if (current_weapon == WEAPON.RULER || current_weapon == WEAPON.UMBRELLA) {

    var ang = point_direction(x, y, mouse_x, mouse_y);

    var r = (current_weapon == WEAPON.RULER) ? ruler_range : umbrella_range;
    var bw = (current_weapon == WEAPON.RULER) ? ruler_hit_w : umbrella_hit_w;
    var bh = (current_weapon == WEAPON.RULER) ? ruler_hit_h : umbrella_hit_h;

    var rx = x + lengthdir_x(r, ang);
    var ry = y + lengthdir_y(r, ang);

    draw_set_color(c_lime);
    draw_line(x, y, rx, ry);
    draw_rectangle(rx - bw*0.5, ry - bh*0.5, rx + bw*0.5, ry + bh*0.5, true);
}

if (current_weapon == WEAPON.EXTINGUISHER && ext_debug) {
    var ang = point_direction(x, y, mouse_x, mouse_y);

    draw_set_color(c_aqua);

    // draw cone edges
    var a1 = ang - ext_half_angle;
    var a2 = ang + ext_half_angle;

    var x1 = x + lengthdir_x(ext_range, a1);
    var y1 = y + lengthdir_y(ext_range, a1);
    var x2 = x + lengthdir_x(ext_range, a2);
    var y2 = y + lengthdir_y(ext_range, a2);

    draw_line(x, y, x1, y1);
    draw_line(x, y, x2, y2);

    // draw arc approximation (optional)
    draw_circle(x, y, ext_range, true);
}
