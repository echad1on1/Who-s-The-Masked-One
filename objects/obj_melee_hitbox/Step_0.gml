/// obj_melee_hitbox : Step

if (!instance_exists(owner)) {
    instance_destroy();
    exit;
}

// Follow owner (position the hitbox in front)
x = owner.x + lengthdir_x(range, atk_ang);
y = owner.y + lengthdir_y(range, atk_ang);

// If we've already hit once and we only allow one hit total, just wait out life
if (hit_once) {
    life--;
    if (life <= 0) instance_destroy();
    exit;
}

// Rectangle region for hit testing (more reliable than instance_place at a point)
var x1 = x - w * 0.5;
var y1 = y - h * 0.5;
var x2 = x + w * 0.5;
var y2 = y + h * 0.5;

// Which enemy objects can be hit (add to this list as you add enemies)
var enemy_types = [
    obj_bug,
    obj_chomper_mouse,
    obj_taken_human,
    obj_cookie_small,
    obj_cookie_big,
    obj_nullpointer,
    obj_router
];


// Try to hit (first hit wins)
for (var i = 0; i < array_length(enemy_types); i++) {

    var obj = enemy_types[i];

    var hit = collision_rectangle(x1, y1, x2, y2, obj, false, true);
    if (instance_exists(hit)) {

        // Preferred: enemy has a take_damage gate
        if (variable_instance_exists(hit, "take_damage")) {
            with (hit) take_damage(other.damage, other.x, other.y);
        }
        // Fallback: direct hp
        else if (variable_instance_exists(hit, "hp")) {
            hit.hp -= damage;
            if (hit.hp <= 0) with (hit) instance_destroy();
        }
        // Final fallback: old debug flash
        else {
            with (hit) {
                image_blend = c_red;
                if (alarm[0] != undefined) alarm[0] = 5;
            }
        }

        hit_once = true;

        if (destroy_on_hit) {
            instance_destroy();
            exit;
        }

        break;
    }
}

// Lifetime
life--;
if (life <= 0) instance_destroy();
