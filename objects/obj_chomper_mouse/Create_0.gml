/// obj_chomper_mouse : Create

// --- anchor (plug point) ---
ax = x;
ay = y;

// --- DEFAULTS (overridable per instance) ---
/// face_ang:
/// 0   = attacks RIGHT
/// 90  = attacks DOWN
/// 180 = attacks LEFT
/// 270 = attacks UP

if (!variable_instance_exists(id, "cord_len"))   cord_len = 120;
if (!variable_instance_exists(id, "face_ang"))   face_ang = 180;

// Optional: widen/narrow arc (keep 90 for semicircle)
arc_half = 90;

// --- collision target ---
solid_obj = obj_solid;

// --- attack cycle states ---
ST_IDLE  = 0; // waiting for player to enter zone
ST_WAIT  = 1; // delay before lunge (telegraph)
ST_LUNGE = 2; // moving toward locked target
ST_REST  = 3; // pause after lunge before re-locking

state = ST_IDLE;
timer = 0;

// --- pacing (frames @ 60fps) ---
if (!variable_instance_exists(id, "wait_frames")) wait_frames = 60; // ~1 second
if (!variable_instance_exists(id, "rest_frames")) rest_frames = 60; // ~1 second

// --- lunge speed ---
if (!variable_instance_exists(id, "lunge_speed")) lunge_speed = 10; // moderate

// --- locked target point ---
tx = x;
ty = y;

// --- debug ---
if (!variable_instance_exists(id, "debug_draw")) debug_draw = true;

// Safety: stop any weird sprite flipping while debugging
image_xscale = 1;
image_yscale = 1;

/// --- ENEMY HP / DAMAGE GATE ---
hp_max = 14;
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

/// --- ATTACK DAMAGE (stress) ---
bite_damage = 16;
bite_hit_radius = 18;   // how close player must be during lunge
bite_did_hit = false;   // reset each lunge
