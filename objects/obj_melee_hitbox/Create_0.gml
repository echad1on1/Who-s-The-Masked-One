/// obj_melee_hitbox : Create
owner = noone;

life = 8;              // frames active
hit_once = false;      // if true: do only one hit total, then stop

// Locked attack direction
atk_ang = 0;

// Shape
range = 54;
w = 30;
h = 20;

// Damage (player should set this when spawning; fallback here)
if (!variable_instance_exists(id, "damage")) damage = 2;

// Optional: if true, destroy hitbox on first successful hit (snappier)
if (!variable_instance_exists(id, "destroy_on_hit")) destroy_on_hit = true;

// Optional debug drawing toggle
if (!variable_instance_exists(id, "debug_draw")) debug_draw = false;
