/// obj_nullpointer : Step

if (enemy_iframes > 0) enemy_iframes--;
if (hit_flash > 0) hit_flash--;

if (hit_flash > 0) image_blend = c_red;
else image_blend = c_white;

var plr = instance_nearest(x, y, obj_player);
if (!instance_exists(plr)) exit;

// Distance to player (for aggro)
var d = point_distance(x, y, plr.x, plr.y);

// Switch modes
if (d <= aggro_range) state = ST_HOME;
else state = ST_ORBIT;

// Tick shooting cooldown always
if (shoot_cd > 0) shoot_cd--;


// ---------------------------
// ORBIT (patrol)
// ---------------------------
if (state == ST_ORBIT) {

    orbit_ang = (orbit_ang + orbit_spd) mod 360;

    // Desired orbit position
    var tx = ax + lengthdir_x(orbit_r, orbit_ang);
    var ty = ay + lengthdir_y(orbit_r, orbit_ang);

    // Simple orbit snap (no collision yet)
    // (If you want orbit to also respect walls, we can convert it to velocity-based movement.)
    x = tx;
    y = ty;

    // Optional: slowly decay chase velocity so it doesn't carry over
    vx *= 0.8;
    vy *= 0.8;
}


// ---------------------------
// HOME (shoot)
// ---------------------------
else if (state == ST_HOME) {

    // Stay in place (or orbit position)
    vx = 0;
    vy = 0;

    // Shoot if ready
    if (shoot_cd <= 0) {
        shoot_cd = shoot_cd_max;

        var ang = point_direction(x, y, plr.x, plr.y);

        var b = instance_create_layer(x, y, layer, obj_null_bullet);
        b.vx = lengthdir_x(bullet_spd, ang);
        b.vy = lengthdir_y(bullet_spd, ang);
		
		b.is_enemy = true;
		b.dmg = bullet_damage;
		
		// Optional touch damage
		if (!variable_instance_exists(id, "touch_cd")) touch_cd = 0;
		if (touch_cd > 0) touch_cd--;

		if (touch_cd <= 0 && point_distance(x, y, plr.x, plr.y) <= 18) {
			if (variable_instance_exists(plr, "player_take_stress")) {
			plr.player_take_stress(6, x, y);
			touch_cd = 30; // half-second cooldown
    }
}

    }
}