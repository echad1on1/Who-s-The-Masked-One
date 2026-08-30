/// scr_move_and_collide(vx, vy, solid_parent)
/// Moves the calling instance by (vx, vy) with axis-separated collision and sliding.
/// Returns an array [vx, vy] after collision resolution (so callers can zero velocity).

function scr_move_and_collide(_vx, _vy, _solid)
{
    var out_vx = _vx;
    var out_vy = _vy;

    // --- X axis ---
    if (out_vx != 0) {
        x += out_vx;

        if (place_meeting(x, y, _solid)) {
            var signx = sign(out_vx);

            // step back out
            while (place_meeting(x, y, _solid)) {
                x -= signx;
            }

            // stop X velocity on collision
            out_vx = 0;
        }
    }

    // --- Y axis ---
    if (out_vy != 0) {
        y += out_vy;

        if (place_meeting(x, y, _solid)) {
            var signy = sign(out_vy);

            while (place_meeting(x, y, _solid)) {
                y -= signy;
            }

            out_vy = 0;
        }
    }

    return [out_vx, out_vy];
}