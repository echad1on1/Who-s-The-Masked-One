/// obj_chomper_mouse : Draw

draw_self();

if (debug_draw) {
    draw_set_color(c_yellow);
    draw_line(ax, ay, x, y);

    draw_set_color(c_red);
    draw_circle(ax, ay, 3, false);

    // boundary rays
    draw_set_color(c_blue);
    var a1 = face_ang - arc_half;
    var a2 = face_ang + arc_half;
    draw_line(ax, ay, ax + lengthdir_x(cord_len, a1), ay + lengthdir_y(cord_len, a1));
    draw_line(ax, ay, ax + lengthdir_x(cord_len, a2), ay + lengthdir_y(cord_len, a2));

    // locked target
    draw_set_color(c_aqua);
    draw_circle(tx, ty, 3, false);

    draw_set_color(c_white);
    draw_text(x + 10, y - 20, "state=" + string(state));
}
