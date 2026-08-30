/// scr_norm2(x, y)
/// Returns normalized direction as an array [nx, ny]. If zero, returns [0, 0].

function scr_norm2(_x, _y)
{
    var len = sqrt(_x*_x + _y*_y);
    if (len <= 0) return [0, 0];
    return [_x / len, _y / len];
}