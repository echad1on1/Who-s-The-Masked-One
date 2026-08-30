function scr_approach(_cur, _tar, _amt)
{
    if (_cur < _tar) return min(_cur + _amt, _tar);
    if (_cur > _tar) return max(_cur - _amt, _tar);
    return _cur;
}