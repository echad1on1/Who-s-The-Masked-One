var gw = display_get_gui_width();
var gh = display_get_gui_height();

// Reserved phone strip (must match UI)
var phone_w = clamp(round(gw * phone_frac), phone_min, phone_max);

// World view size = screen minus phone
var view_w = gw - phone_w;
var view_h = gh;

// Apply camera view size
camera_set_view_size(cam, view_w, view_h);

// Desired camera position (center on player)
var tx = (target.x + cam_offset_x) - view_w * 0.5;
var ty = (target.y + cam_offset_y) - view_h * 0.5;

// Clamp to room bounds
tx = clamp(tx, 0, room_width  - view_w);
ty = clamp(ty, 0, room_height - view_h);

// Smooth follow
var cx = camera_get_view_x(cam);
var cy = camera_get_view_y(cam);

cx = lerp(cx, tx, follow_lerp);
cy = lerp(cy, ty, follow_lerp);

camera_set_view_pos(cam, cx, cy);
