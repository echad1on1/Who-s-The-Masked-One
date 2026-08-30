/// obj_player : Create

// --- movement tuning ---
move_spd = 3.25;   // max walk speed
accel    = 0.55;   // how fast we reach target speed
fric     = 0.45;   // how fast we slow down when no input

// --- internal ---
vx = 0;
vy = 0;

// collision target (parent object)
solid_obj = obj_solid;

// optional: small safety cap to avoid crazy speeds later (knockback etc.)
max_spd_cap = 12;

/// --- DASH ---
dash_speed      = 9.0;   // dash velocity
dash_time_max   = 10;    // frames (10 = ~0.16s at 60fps)
dash_cd_max     = 25;    // frames cooldown (~0.4s)

// runtime
dash_time = 0;
dash_cd   = 0;
dash_dx   = 1;  // last / dash direction
dash_dy   = 0;

// aim lock (for shooting during dash)
aim_lock = false;
aim_lx   = 1;
aim_ly   = 0;

/// --- WEAPON SYSTEM ---
current_weapon = WEAPON.STAPLEGUN;

// Staple gun tuning
staple_fire_cd = 0;
staple_fire_delay = 10;   // frames between shots (starter)
staple_bullet_spd = 6;    // slow-ish
staple_spread_deg = 2;    // tiny randomness (optional)

// Ruler tuning
ruler_cd = 0;
ruler_delay = 18;         // frames between swings
ruler_range = 54;         // reach
ruler_hit_w = 30;         // debug box width
ruler_hit_h = 20;         // debug box height

// Interaction tuning
pickup_range = 22;

// Aim direction fallback (use your dash_dx/dash_dy if you have them)
if (!variable_instance_exists(id, "aim_dx")) aim_dx = 1;
if (!variable_instance_exists(id, "aim_dy")) aim_dy = 0;

// Ruler damage (light melee)
ruler_damage = 2;

// Umbrella tuning (heavy ruler)
umbrella_cd = 0;
umbrella_delay = 26;     // slower swing than ruler
umbrella_range = 78;     // longer reach
umbrella_hit_w = 34;     // slightly larger hitbox
umbrella_hit_h = 22;
umbrella_damage = 3;     // placeholder for later (ruler could be 2, staple 1)

// Pistol tuning (upgrade gun)
pistol_fire_cd = 0;
pistol_fire_delay = 6;     // faster than staple (10)
pistol_bullet_spd = 11;    // much faster than staple (6)
pistol_spread_deg = 1;     // more accurate than staple (2)

// Rifle tuning (endgame gun)
rifle_fire_cd = 0;
rifle_fire_delay = 3;     // very fast
rifle_bullet_spd = 15;    // very fast bullets
rifle_spread_deg = 0.4;   // extremely accurate (keep small non-zero)

// Fire extinguisher (cone control)
ext_cd = 0;
ext_tick = 0;              // rate limiter for “ticks”
ext_tick_max = 3;          // apply effect every N frames while held

ext_range = 90;            // cone length
ext_half_angle = 28;       // degrees to each side (cone width)

ext_push = 1.2;            // knockback strength (control feel)
ext_slow = 0.65;           // optional slow factor (if enemy uses vx/vy)

ext_debug = true;          // draw cone overlay while spraying

/// --- STRESS (Health) SYSTEM ---
stress = 0;                 // 0..100
stress_max = 100;

stress_add_key = ord("F");  // press F to add stress (debug)
stress_add_amt = 10;        // how much each press adds

/// --- MASK SYSTEM ---
mask_on = false;
mask_toggle_key = ord("M"); // press Q to toggle mask (change if you want)

// Buff multipliers while masked
mask_move_mul  = 1.22;  // +22% move speed
mask_dash_mul  = 1.25;  // +25% dash speed
mask_cd_mul    = 0.72;  // dash cooldown multiplier (lower = better)
mask_melee_mul = 1.25;  // +25% melee reach

// GUI feedback
mask_gui_x = 24;
mask_gui_y = 24;

/// --- MASK FATIGUE (MAX STRESS CHIP) ---
stress_base_max = stress_max; // keep original max (100)
stress_min_max  = 35;         // cannot reduce below this (tweak)

mask_wear_t = 0;              // frames wearing mask
mask_fatigue_delay = 180 * room_speed; // 3 minutes before it starts chipping

// How fast max stress is reduced once fatigue starts
mask_chip_per_sec = 2.0;      // 2 max-stress per second (tweak)
mask_chip_accum = 0;          // fractional accumulator

// Debug: force chip even without waiting 3 minutes
mask_chip_debug_key = ord("K"); // press K to chip immediately (test)
mask_chip_debug_amt = 3;        // how much to chip per press

/// --- DAMAGE / GODMODE / I-FRAMES ---
godmode = false;
godmode_key = ord("G");


// invulnerability frames after getting hit
iframes = 0;
iframes_max = 18; // ~0.3s @ 60fps (tweak)

// hit feedback
hit_flash = 0;        // frames of red flash
hit_flash_max = 6;

// optional: brief knockback impulse (stored separately so it doesn't break movement)
kb_vx = 0;
kb_vy = 0;
kb_fric = 0.65;       // how fast knockback decays

// Fire extinguisher damage
ext_damage = 1;          // damage per tick (every ext_tick_max frames)
ext_cloud_per_tick = 5;  // how many puffs per tick (visual density)
ext_cloud_spread = 10;   // degrees random spread for puffs
