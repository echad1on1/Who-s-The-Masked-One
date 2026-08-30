/// obj_player : Draw GUI

var gw = display_get_gui_width();
var gh = display_get_gui_height();
var pad = 18;

var bar_w = 260;
var bar_h = 18;

// Bottom-left
var x1 = pad;
// Top-left
var x1 = pad;
var y1 = pad;


// Ratios (use base max for bar length)
var base = max(1, stress_base_max);
var cur  = clamp(stress, 0, base);
var eff  = clamp(stress_max, 0, base);

var pct_cur = cur / base;
var pct_eff = eff / base;

// Background bar
draw_set_color(make_color_rgb(40,40,50));
draw_rectangle(x1, y1, x1 + bar_w, y1 + bar_h, false);

// Fill (current stress)
draw_set_color(c_white);
draw_rectangle(x1, y1, x1 + bar_w * pct_cur, y1 + bar_h, false);

// Lost-max overlay (the “greyed out” chunk to the right)
if (eff < base) {
    var capx = x1 + bar_w * pct_eff;

    draw_set_color(make_color_rgb(20,20,22)); // dark chunk
    draw_rectangle(capx, y1, x1 + bar_w, y1 + bar_h, false);

    // Cap marker line
    draw_set_color(make_color_rgb(220,220,220));
    draw_line(capx, y1 - 2, capx, y1 + bar_h + 2);
}

// Outline
draw_set_color(make_color_rgb(120,120,140));
draw_rectangle(x1, y1, x1 + bar_w, y1 + bar_h, true);

// Text under bar (show effective max)
draw_set_color(c_white);
draw_text(x1, y1 + bar_h + 6, "STRESS: " + string(round(stress)) + " / " + string(round(stress_max)));


if (godmode) {
    draw_set_alpha(0.9);
    draw_set_color(c_black);
    draw_rectangle(24 - 6, 54 - 6, 24 + 150, 54 + 22, false);

    draw_set_color(c_yellow);
    draw_rectangle(24 - 4, 54 - 4, 24 + 148, 54 + 20, false);

    draw_set_color(c_black);
    draw_text(24 + 8, 54 + 0, "GODMODE ON");
    draw_set_alpha(1);
}