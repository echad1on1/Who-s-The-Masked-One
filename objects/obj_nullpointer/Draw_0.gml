/// obj_nullpointer : Draw

draw_self();

if (debug_draw) {
    // Orbit circle
    draw_set_color(make_color_rgb(80,80,80));
    draw_circle(ax, ay, orbit_r, true);

    // Aggro range
    draw_set_color(c_red);
    draw_circle(x, y, aggro_range, true);

    // State + cooldown
    draw_set_color(c_white);
    draw_text(x + 10, y - 20, "state=" + string(state) + " cd=" + string(shoot_cd));
}
