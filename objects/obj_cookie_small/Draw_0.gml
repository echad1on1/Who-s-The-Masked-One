/// obj_cookie_small : Draw

draw_self();

if (state == ST_ARMED) {
    draw_set_color(c_red);
    draw_circle(x, y, 10, false);
}

if (state == ST_BOOM) {
    draw_set_color(c_orange);
    draw_circle(x, y, 18, false);
}
