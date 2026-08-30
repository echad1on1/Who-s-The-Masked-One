/// obj_nullpointer : Create

// ---------------------------
// ORBIT (patrol) BEHAVIOR
// ---------------------------

// Anchor point for orbit (where it spins around).
// Default = where it spawned in the room.
ax = x;
ay = y;

// Orbit radius (pixels). It traces a circle of this size.
orbit_r = 80;

// Current orbit angle (degrees). Random start so multiple enemies desync.
orbit_ang = irandom(359);

// Orbit speed (degrees per frame). Higher = faster spinning.
orbit_spd = 3;


// ---------------------------
// AGGRO / HOMING BEHAVIOR
// ---------------------------

// Player detection radius. If player is within this, enemy homes in.
aggro_range = 220;

// Homing speed in pixels/frame. Sets how fast it moves when chasing.
home_spd = 2.6;

// Homing smoothing factor (0..1). Higher = snappier turns, lower = floaty.
home_lerp = 0.18;


// ---------------------------
// SHOOTING BEHAVIOR
// ---------------------------

// Cooldown between shots (frames). 60 frames ≈ 1 second at 60 FPS.
shoot_cd_max = 60;

// Current cooldown timer. Random start prevents all enemies firing together.
shoot_cd = irandom(shoot_cd_max);

// Bullet speed (pixels/frame). Tune to be dodgeable.
bullet_spd = 7;


// ---------------------------
// INTERNAL STATE / MOVEMENT
// ---------------------------

// States
ST_ORBIT = 0;  // spins around anchor
ST_HOME  = 1;  // homes in and shoots
state = ST_ORBIT;

// Velocity used in home mode (smoothed)
vx = 0;
vy = 0;

// Collision target parent/object for walls/solids
solid_obj = obj_solid;


// ---------------------------
// DEBUG
// ---------------------------

// Toggle debug drawing (ranges etc.)
debug_draw = true;

/// --- ENEMY HP / DAMAGE GATE ---
hp_max = 12;
hp = hp_max;

enemy_iframes = 0;
enemy_iframes_max = 6;

hit_flash = 0;
hit_flash_max = 5;

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

// How much stress its bullets do
bullet_damage = 10;
