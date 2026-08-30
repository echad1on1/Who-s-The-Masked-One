x += vx;
y += vy;

life--;
if (life <= 0) instance_destroy();

if (place_meeting(x, y, obj_solid)) instance_destroy();

// --- HIT DETECTION (ENEMIES) ---
if (!variable_instance_exists(id, "dmg")) dmg = 3;

var hit = noone;

hit = instance_place(x, y, obj_bug);
if (!instance_exists(hit)) hit = instance_place(x, y, obj_chomper_mouse);
if (!instance_exists(hit)) hit = instance_place(x, y, obj_taken_human);
if (!instance_exists(hit)) hit = instance_place(x, y, obj_cookie_small);
if (!instance_exists(hit)) hit = instance_place(x, y, obj_cookie_big);
if (!instance_exists(hit)) hit = instance_place(x, y, obj_nullpointer);
if (!instance_exists(hit)) hit = instance_place(x, y, obj_router);

if (instance_exists(hit)) {

    if (variable_instance_exists(hit, "take_damage")) {
        with (hit) take_damage(other.dmg, other.x, other.y);
    }
    else if (variable_instance_exists(hit, "hp")) {
        hit.hp -= dmg;
        if (hit.hp <= 0) with (hit) instance_destroy();
    }
    else {
        with (hit) { image_blend = c_red; alarm[0] = 5; }
    }

    instance_destroy();
    exit;
}