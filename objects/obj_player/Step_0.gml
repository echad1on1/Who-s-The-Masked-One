/// obj_player : Step

// --- timers ---
if (dash_cd > 0) dash_cd--;
if (dash_time > 0) dash_time--;

/// Apply stress damage to player through a single gate.
/// Enemies should call: other.player_take_stress(amount, x, y);
function player_take_stress(_amt, _srcx, _srcy)
{
    if (_amt <= 0) return false;

    // Godmode blocks all damage
    if (godmode) return false;

    // I-frames block repeated damage
    if (iframes > 0) return false;

    // Apply stress
    stress = clamp(stress + _amt, 0, stress_max);

    // Start i-frames + feedback
    iframes = iframes_max;
    hit_flash = hit_flash_max;

    // Optional knockback away from source
    // (remove if you don't want knockback yet)
    var ang = point_direction(_srcx, _srcy, x, y);
    var kb = 3.0; // knockback strength (tweak)
    kb_vx += lengthdir_x(kb, ang);
    kb_vy += lengthdir_y(kb, ang);

    return true;
}

// --- INPUT ---
var ix = keyboard_check(ord("D")) - keyboard_check(ord("A"));
var iy = keyboard_check(ord("S")) - keyboard_check(ord("W"));
var dash_pressed = keyboard_check_pressed(vk_shift);
// --- MASK TOGGLE ---
if (keyboard_check_pressed(mask_toggle_key)) {
    mask_on = !mask_on;
}

// --- MASK FATIGUE / MAX STRESS CHIP ---
if (mask_on) {
    mask_wear_t++;

    // Debug: press K to chip max stress instantly
    if (keyboard_check_pressed(mask_chip_debug_key)) {
        stress_max = max(stress_min_max, stress_max - mask_chip_debug_amt);
        stress = min(stress, stress_max);
    }

    // Real fatigue: only after delay
    if (mask_wear_t >= mask_fatigue_delay) {

        // accumulate fractional chipping
        mask_chip_accum += mask_chip_per_sec / room_speed;

        // apply whole points
        var chip = floor(mask_chip_accum);
        if (chip > 0) {
            mask_chip_accum -= chip;

            stress_max = max(stress_min_max, stress_max - chip);
            stress = min(stress, stress_max); // clamp current stress to new max
        }
    }

} else {
    // not wearing mask -> stop building fatigue
    mask_wear_t = 0;
    mask_chip_accum = 0;
}

// --- GODMODE TOGGLE ---
if (keyboard_check_pressed(godmode_key)) {
    godmode = !godmode;
}

// --- DAMAGE TIMERS ---
if (iframes > 0) iframes--;
if (hit_flash > 0) hit_flash--;


// --- STRESS DEBUG INPUT ---
if (keyboard_check_pressed(stress_add_key)) {
    stress = clamp(stress + stress_add_amt, 0, stress_max);
}
if (keyboard_check_pressed(ord("H"))) {
    player_take_stress(12, x - 1, y); // fake source on left
}


// --- MASK BUFF EFFECTIVE STATS ---
var move_spd_eff   = move_spd;
var dash_speed_eff = dash_speed;
var dash_cd_eff    = dash_cd_max;
var melee_mul_eff  = 1;

if (mask_on) {
    move_spd_eff   *= mask_move_mul;
    dash_speed_eff *= mask_dash_mul;
    dash_cd_eff     = ceil(dash_cd_max * mask_cd_mul);
    melee_mul_eff   = mask_melee_mul;
}

// If phone owns focus, suspend player control (but we already processed stress debug)
if (variable_global_exists("phone_focus") && global.phone_focus) {
    vx = 0; vy = 0;
    exit;
}

// --- AIM UPDATE (simple) ---
// Use movement input for aim when available
if (ix != 0 || iy != 0) {
    var nd_aim = scr_norm2(ix, iy);
    aim_dx = nd_aim[0];
    aim_dy = nd_aim[1];
}

// --- Normalize input direction (movement) ---
var nd  = scr_norm2(ix, iy);
var nix = nd[0];
var niy = nd[1];

// Update last known direction when player provides movement input
if (nix != 0 || niy != 0) {
    dash_dx = nix;
    dash_dy = niy;
}

// --- START DASH ---
if (dash_pressed && dash_cd == 0 && dash_time == 0) {

    var dx = dash_dx;
    var dy = dash_dy;

    // Failsafe
    if (dx == 0 && dy == 0) { dx = 1; dy = 0; }

    dash_dx = dx;
    dash_dy = dy;

    dash_time = dash_time_max;
    dash_cd   = dash_cd_eff;


    // Lock aim during dash
    aim_lock = true;
    aim_lx   = dash_dx;
    aim_ly   = dash_dy;
}

// --- MOVE (dash or normal) ---
if (dash_time > 0) {

    vx = dash_dx * dash_speed_eff;
	vy = dash_dy * dash_speed_eff;


    var vdash = scr_move_and_collide(vx, vy, solid_obj);
    vx = vdash[0];
    vy = vdash[1];

    aim_lock = true;
    aim_lx   = dash_dx;
    aim_ly   = dash_dy;

} else {

    aim_lock = false;

    var tvx = nix * move_spd_eff;
	var tvy = niy * move_spd_eff;


    if (nix != 0 || niy != 0) {
        vx = scr_approach(vx, tvx, accel);
        vy = scr_approach(vy, tvy, accel);
    } else {
        vx = scr_approach(vx, 0, fric);
        vy = scr_approach(vy, 0, fric);
    }

    // Speed cap
    var spd = sqrt(vx*vx + vy*vy);
    if (spd > max_spd_cap) {
        var s = max_spd_cap / spd;
        vx *= s;
        vy *= s;
    }

    var vmove = scr_move_and_collide(vx, vy, solid_obj);
    vx = vmove[0];
    vy = vmove[1];
}

// --- APPLY KNOCKBACK CHANNEL ---
vx += kb_vx;
vy += kb_vy;

// decay knockback
kb_vx *= kb_fric;
kb_vy *= kb_fric;

// --- PICKUP / DROP (E) ---
if (keyboard_check_pressed(ord("E"))) {

    var pick = instance_nearest(x, y, obj_weapon_pickup);

    if (instance_exists(pick) && point_distance(x, y, pick.x, pick.y) <= pickup_range) {

        // Drop current weapon as a pickup
        if (current_weapon == WEAPON.STAPLEGUN) {
            instance_create_layer(x, y, layer, obj_pickup_staplegun);
        } else if (current_weapon == WEAPON.RULER) {
            instance_create_layer(x, y, layer, obj_pickup_ruler);
        } else if (current_weapon == WEAPON.UMBRELLA) {
            instance_create_layer(x, y, layer, obj_pickup_umbrella);
        } else if (current_weapon == WEAPON.PISTOL) {
            instance_create_layer(x, y, layer, obj_pickup_pistol);
        } else if (current_weapon == WEAPON.RIFLE) {
            instance_create_layer(x, y, layer, obj_pickup_rifle);
        } else if (current_weapon == WEAPON.EXTINGUISHER) {
            instance_create_layer(x, y, layer, obj_pickup_extinguisher);
        }

        // Equip new weapon
        current_weapon = pick.weapon_type;

        // Reset cooldowns/ticks
        staple_fire_cd = 0;
        pistol_fire_cd = 0;
        rifle_fire_cd  = 0;
        ruler_cd       = 0;
        umbrella_cd    = 0;
        ext_tick       = 0;

        with (pick) instance_destroy();
    }
}

// --- WEAPON INPUT ---
var attack_pressed = mouse_check_button_pressed(mb_left) || keyboard_check_pressed(vk_space);
var attack_held    = mouse_check_button(mb_left) || keyboard_check(vk_space);

// --- COOLDOWNS ---
if (staple_fire_cd > 0) staple_fire_cd--;
if (pistol_fire_cd > 0) pistol_fire_cd--;
if (rifle_fire_cd > 0)  rifle_fire_cd--;
if (ruler_cd > 0)       ruler_cd--;
if (umbrella_cd > 0)    umbrella_cd--;

// --- WEAPON USE (single clean chain) ---
if (current_weapon == WEAPON.STAPLEGUN) {

    if (attack_held && staple_fire_cd <= 0) {
        staple_fire_cd = staple_fire_delay;

        var ang = point_direction(x, y, mouse_x, mouse_y);
        ang += random_range(-staple_spread_deg, staple_spread_deg);

        var b = instance_create_layer(x, y, layer, obj_bullet_staple);
        b.vx = lengthdir_x(staple_bullet_spd, ang);
        b.vy = lengthdir_y(staple_bullet_spd, ang);
    }

}
else if (current_weapon == WEAPON.PISTOL) {

    if (attack_held && pistol_fire_cd <= 0) {
        pistol_fire_cd = pistol_fire_delay;

        var ang = point_direction(x, y, mouse_x, mouse_y);
        ang += random_range(-pistol_spread_deg, pistol_spread_deg);

        var b = instance_create_layer(x, y, layer, obj_bullet_pistol);
        b.vx = lengthdir_x(pistol_bullet_spd, ang);
        b.vy = lengthdir_y(pistol_bullet_spd, ang);
    }

}
else if (current_weapon == WEAPON.RIFLE) {

    if (attack_held && rifle_fire_cd <= 0) {
        rifle_fire_cd = rifle_fire_delay;

        var ang = point_direction(x, y, mouse_x, mouse_y);
        ang += random_range(-rifle_spread_deg, rifle_spread_deg);

        var b = instance_create_layer(x, y, layer, obj_bullet_rifle);
        b.vx = lengthdir_x(rifle_bullet_spd, ang);
        b.vy = lengthdir_y(rifle_bullet_spd, ang);
    }

}
else if (current_weapon == WEAPON.RULER) {

    if (attack_pressed && ruler_cd <= 0) {
        ruler_cd = ruler_delay;

        var ang = point_direction(x, y, mouse_x, mouse_y);

        var hbox = instance_create_layer(x, y, layer, obj_melee_hitbox);
        hbox.owner = id;
        hbox.atk_ang = ang;
        hbox.range = ruler_range * melee_mul_eff;
        hbox.w = ruler_hit_w;
        hbox.h = ruler_hit_h;

        // ✅ NEW: actual damage value
        hbox.damage = ruler_damage;
    }

}
else if (current_weapon == WEAPON.UMBRELLA) {

    if (attack_pressed && umbrella_cd <= 0) {
        umbrella_cd = umbrella_delay;

        var ang = point_direction(x, y, mouse_x, mouse_y);

        var hbox = instance_create_layer(x, y, layer, obj_melee_hitbox);
        hbox.owner = id;
        hbox.atk_ang = ang;
        hbox.range = umbrella_range * melee_mul_eff;
        hbox.w = umbrella_hit_w;
        hbox.h = umbrella_hit_h;

        // already existed, keep it
        hbox.damage = umbrella_damage;
    }

}

else if (current_weapon == WEAPON.EXTINGUISHER) {

    if (attack_held) {

        // Aim direction for spray
        spray_ang = point_direction(x, y, mouse_x, mouse_y);

        // Visual cloud: spawn a few puffs every frame (lightweight)
        // (If too many instances, move this into the tick block only.)
        for (var k = 0; k < 2; k++) {
            var a = spray_ang + random_range(-ext_cloud_spread, ext_cloud_spread);
            var p = instance_create_layer(x, y, layer, obj_ext_cloud);
            p.vx = lengthdir_x(3.5, a);
            p.vy = lengthdir_y(3.5, a);
        }

        // Damage/force happens on ticks (rate-limited)
        ext_tick++;
        if (ext_tick >= ext_tick_max) {
            ext_tick = 0;

            // Helper: apply extinguisher cone effect to one enemy object type
            function ext_apply_to(_obj)
            {
                with (_obj) {

                    // distance check
                    var d = point_distance(other.x, other.y, x, y);
                    if (d > other.ext_range) exit;

                    // cone angle check (player -> enemy)
                    var a_to = point_direction(other.x, other.y, x, y);
                    var da = abs(angle_difference(other.spray_ang, a_to));
                    if (da > other.ext_half_angle) exit;

                    // Push away (still works for any enemy)
                    var px = lengthdir_x(other.ext_push, a_to);
                    var py = lengthdir_y(other.ext_push, a_to);
                    scr_move_and_collide(px, py, obj_solid);

                    // OPTIONAL slow if enemy uses vx/vy
                    if (variable_instance_exists(id, "vx")) vx *= other.ext_slow;
                    if (variable_instance_exists(id, "vy")) vy *= other.ext_slow;

                    // ✅ DAMAGE
                    if (variable_instance_exists(id, "take_damage")) {
                        take_damage(other.ext_damage, other.x, other.y);
                    } else if (variable_instance_exists(id, "hp")) {
                        hp -= other.ext_damage;
                        if (hp <= 0) instance_destroy();
                    }

                    // feedback tint
                    image_blend = c_aqua;
                    if (alarm[0] != undefined) alarm[0] = 5;
                }
            }

            // Apply to all enemies you want affected
            ext_apply_to(obj_bug);
            ext_apply_to(obj_chomper_mouse);
            ext_apply_to(obj_taken_human);
            ext_apply_to(obj_cookie_small);
            ext_apply_to(obj_nullpointer);

            // Extra puff burst on tick (feels juicy)
            for (var i = 0; i < ext_cloud_per_tick; i++) {
                var a2 = spray_ang + random_range(-ext_cloud_spread, ext_cloud_spread);
                var p2 = instance_create_layer(x, y, layer, obj_ext_cloud);
                p2.vx = lengthdir_x(4.5, a2);
                p2.vy = lengthdir_y(4.5, a2);
            }
        }

    } else {
        ext_tick = 0;
    }
}
