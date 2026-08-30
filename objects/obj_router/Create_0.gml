/// obj_router : Create

// ----------------- WIFI WAVE CONFIG -----------------
debug_draw = true;

// where arcs originate (from router sides)
emit_side_offset = 18;   // pixels from center to left/right emitter

// arc shape
arc_half_angle = 55;     // degrees up/down from "outward" direction
arc_segments   = 24;     // higher = smoother arcs

// radii for the 3-wave burst (small -> medium -> large)
arc_r1 = 18;
arc_r2 = 34;
arc_r3 = 54;

// timing
arc_frames = 10;         // how long each arc is "active"
gap_frames = 8;          // pause after finishing all 3 arcs

// internal state
PHASE_ARC1 = 0;
PHASE_ARC2 = 1;
PHASE_ARC3 = 2;
PHASE_GAP  = 3;

phase = PHASE_ARC1;
phase_timer = arc_frames;

/// --- ROUTER HP / DAMAGE ---
hp_max = 18;
hp = hp_max;

enemy_iframes = 0;
enemy_iframes_max = 6;

hit_flash = 0;
hit_flash_max = 5;

// Damage tuning (stress)
wifi_damage = 10;          // stress per wave hit
wifi_hit_radius = 10;      // "thickness" of arc for collision checks
wifi_iframes = 0;          // prevents multiple hits per frame/arc
wifi_iframes_max = 12;     // per-router hit cooldown

take_damage = function(_dmg, _srcx, _srcy)
{
    if (_dmg <= 0) return false;
    if (enemy_iframes > 0) return false;

    hp -= _dmg;
    enemy_iframes = enemy_iframes_max;
    hit_flash = hit_flash_max;

    if (hp <= 0) instance_destroy();
    return true;
};
