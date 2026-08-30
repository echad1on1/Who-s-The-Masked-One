/// obj_router : Draw
draw_self();

/// --- helper: draw an arc using line segments (no draw_primitive_*) ---
function draw_arc_lines(_cx, _cy, _r, _ang0, _ang1, _segs)
{
    if (_segs < 3) _segs = 3;

    var prevx = _cx + lengthdir_x(_r, _ang0);
    var prevy = _cy + lengthdir_y(_r, _ang0);

    for (var i = 1; i <= _segs; i++)
    {
        var t = i / _segs;
        var a = lerp(_ang0, _ang1, t);

        var px = _cx + lengthdir_x(_r, a);
        var py = _cy + lengthdir_y(_r, a);

        draw_line(prevx, prevy, px, py);

        prevx = px;
        prevy = py;
    }
}

/// --- draw wifi burst from one side ---
/// _side = -1 (left) or +1 (right)
function draw_wifi_burst(_side, _r)
{
    var ex = x + _side * emit_side_offset;
    var ey = y;

    // outward direction: right = 0 deg, left = 180 deg
    var outward = (_side == 1) ? 0 : 180;

    var a0 = outward - arc_half_angle;
    var a1 = outward + arc_half_angle;

    draw_arc_lines(ex, ey, _r, a0, a1, arc_segments);

    // emitter marker
    draw_circle(ex, ey, 2, false);
}

if (debug_draw)
{
    // pick radius based on phase
    var r = -1;
    if (phase == PHASE_ARC1) r = arc_r1;
    if (phase == PHASE_ARC2) r = arc_r2;
    if (phase == PHASE_ARC3) r = arc_r3;

    // colors
    if (phase == PHASE_GAP) draw_set_color(c_gray);
    else draw_set_color(c_aqua);

    // draw both sides
    if (r > 0) {
        draw_wifi_burst(-1, r);
        draw_wifi_burst( 1, r);
    }

    // debug text + bbox
    draw_set_color(c_white);
    draw_text(x + 12, y - 28, "router phase=" + string(phase) + " t=" + string(phase_timer));

    draw_set_color(c_yellow);
    draw_rectangle(bbox_left, bbox_top, bbox_right, bbox_bottom, true);
}