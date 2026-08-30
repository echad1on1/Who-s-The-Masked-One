/// obj_cookie_big : Step
if (enemy_iframes > 0) enemy_iframes--;
if (hit_flash > 0) hit_flash--;

if (hit_flash > 0) image_blend = c_red;
else image_blend = c_white;

timer--;

if (timer <= 0) {

    for (var i = 0; i < spawn_count; i++) {

        var ang = i * (360 / spawn_count);
        var sx = x + lengthdir_x(spawn_radius, ang);
        var sy = y + lengthdir_y(spawn_radius, ang);

        instance_create_layer(sx, sy, layer, obj_cookie_small);
    }

    // Big cookie disappears after splitting
    instance_destroy();
}
