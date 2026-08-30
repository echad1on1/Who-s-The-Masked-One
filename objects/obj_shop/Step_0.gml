/// obj_shop : Step

var plr = instance_nearest(x, y, obj_player);
show_prompt = false;

if (!instance_exists(plr)) exit;

var d = point_distance(x, y, plr.x, plr.y);
if (d <= shop_range) {
    show_prompt = true;

    if (keyboard_check_pressed(ord("E"))) {

        // Ensure money exists
        if (!variable_global_exists("usd_cash")) global.usd_cash = 0;

        if (global.usd_cash >= shop_price) {

            // Deduct
            global.usd_cash -= shop_price;

            // Drop player's current weapon as pickup (same logic as your pickup swap)
            with (plr) {

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

                // Equip purchased weapon
                current_weapon = other.shop_weapon;

                // Reset cooldowns/ticks
                staple_fire_cd = 0;
                pistol_fire_cd = 0;
                rifle_fire_cd  = 0;
                ruler_cd       = 0;
                umbrella_cd    = 0;
                ext_tick       = 0;
            }

        } else {
            // Not enough money - optional: you can flash red later
            // For now do nothing.
        }
    }
}