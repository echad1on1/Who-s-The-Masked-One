/// obj_bug : Create

// Movement
move_spd    = 1.9;   // normal chase speed
turn_lerp   = 0.12;  // steering smoothness

// Detection
aggro_range = 260;

// Wiggle (insect feel)
wiggle_amp  = 0.9;   // sideways strength
wiggle_freq = 0.12;  // how fast it wiggles
wiggle_t    = random(1000);

// Flank/orbit behavior
flank_range = 90;     // start flanking when within this distance
flank_time  = 40;     // frames it tries to circle before pounce
flank_dir   = choose(-1, 1); // clockwise / counter

// Pounce attack (no damage yet)
windup_time = 18;     // stop before pounce
pounce_spd  = 6.5;    // lunge speed
pounce_time = 10;     // lunge frames
cooldown_time = 25;   // recovery after pounce

// Runtime
vx = 0; vy = 0;
tx = x; ty = y; // target lock point (for pounce)
timer = 0;

// States
ST_IDLE    = 0;
ST_CHASE   = 1;
ST_FLANK   = 2;
ST_WINDUP  = 3;
ST_POUNCE  = 4;
ST_COOLDOWN= 5;

state = ST_IDLE;

// Collision
solid_obj = obj_solid;

// Debug
debug_draw = false;

alarm[0] = -1;

/// --- ENEMY HP / DAMAGE GATE ---
hp_max = 10;
hp = hp_max;

enemy_iframes = 0;
enemy_iframes_max = 6; // short (so automatic weapons feel good)

// feedback
hit_flash = 0;
hit_flash_max = 5;

// optional knockback channel
kb_vx = 0;
kb_vy = 0;
kb_fric = 0.75;

// A single entry point for all incoming damage
take_damage = function(_dmg, _srcx, _srcy)
{
    if (_dmg <= 0) return false;
    if (enemy_iframes > 0) return false;

    hp -= _dmg;
    enemy_iframes = enemy_iframes_max;
    hit_flash = hit_flash_max;

    // knockback away from source (tiny)
    var ang = point_direction(_srcx, _srcy, x, y);
    var kb = 2.2;
    kb_vx += lengthdir_x(kb, ang);
    kb_vy += lengthdir_y(kb, ang);

    if (hp <= 0) {
        instance_destroy();
    }
    return true;
};

// --- Attack damage (stress) ---
pounce_damage = 12;
pounce_hit_radius = 18;
pounce_did_hit = false;
