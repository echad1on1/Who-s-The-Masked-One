/// obj_cookie_big : Create

/// --- ENEMY HP / DAMAGE GATE ---
hp_max = 8;
hp = hp_max;

enemy_iframes = 0;
enemy_iframes_max = 6;

hit_flash = 0;
hit_flash_max = 5;

// If killed early, split immediately (feels juicy)
split_on_death = true;

take_damage = function(_dmg, _srcx, _srcy)
{
    if (_dmg <= 0) return false;
    if (enemy_iframes > 0) return false;

    hp -= _dmg;
    enemy_iframes = enemy_iframes_max;
    hit_flash = hit_flash_max;

    if (hp <= 0) {
        if (split_on_death) {
            timer = 0; // force split next step
        } else {
            instance_destroy();
        }
    }
    return true;
};


// How many small cookies to spawn
spawn_count = 4;

// Delay before splitting
split_delay = 90; // frames (~1.5 sec)

// Radius to scatter small cookies
spawn_radius = 18;

// Internal
timer = split_delay;

// Debug
debug_draw = false;
