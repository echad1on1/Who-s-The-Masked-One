/// obj_cookie_small : Create

// Homing
move_spd = 2.2;
aggro_range = 220;

// Explosion behavior
explode_range = 22; // distance to player
explode_delay = 20; // frames frozen before despawn

// State
ST_MOVE   = 0;
ST_ARMED  = 1;
ST_BOOM   = 2;

state = ST_MOVE;
timer = 0;

// Movement
vx = 0;
vy = 0;

// Collision
solid_obj = obj_solid;

// Debug
debug_draw = false;

/// --- ENEMY HP / DAMAGE GATE ---
hp_max = 4;
hp = hp_max;

enemy_iframes = 0;
enemy_iframes_max = 6;

hit_flash = 0;
hit_flash_max = 5;

// Explosion damage (stress)
boom_damage = 18;     // stress added if caught
boom_radius = 34;     // radius of explosion effect
boom_did_damage = false;

take_damage = function(_dmg, _srcx, _srcy)
{
    if (_dmg <= 0) return false;
    if (enemy_iframes > 0) return false;

    hp -= _dmg;
    enemy_iframes = enemy_iframes_max;
    hit_flash = hit_flash_max;

    if (hp <= 0) {
        instance_destroy();
    }
    return true;
};
