/// obj_shop : Create

// --- configurable per-instance ---
if (!variable_instance_exists(id, "shop_weapon")) shop_weapon = WEAPON.PISTOL;
if (!variable_instance_exists(id, "shop_price"))  shop_price  = 120.00;

// interaction
if (!variable_instance_exists(id, "shop_range"))  shop_range = 28;

// display name (optional override)
shop_weapon_name = "Weapon";
switch (shop_weapon) {
    case WEAPON.STAPLEGUN:     shop_weapon_name = "Staple Gun"; break;
    case WEAPON.PISTOL:        shop_weapon_name = "Pistol"; break;
    case WEAPON.RIFLE:         shop_weapon_name = "Rifle"; break;
    case WEAPON.RULER:         shop_weapon_name = "Ruler"; break;
    case WEAPON.UMBRELLA:      shop_weapon_name = "Umbrella"; break;
    case WEAPON.EXTINGUISHER:  shop_weapon_name = "Extinguisher"; break;
}

// debug
show_prompt = false;
