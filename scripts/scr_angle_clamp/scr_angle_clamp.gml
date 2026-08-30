/// scr_angle_clamp(a, center, half_range)
/// clamps angle a into [center-half_range, center+half_range] properly (wrap-safe)

function scr_angle_clamp(_a, _c, _half)
{
    // signed shortest difference from center to angle a
    // IMPORTANT: order is (_a, _c), not (_c, _a)
    var d = angle_difference(_a, _c); // -180..180, equals (a - c) wrapped

    d = clamp(d, -_half, _half);

    return _c + d;
}