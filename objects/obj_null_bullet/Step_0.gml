/// obj_null_bullet : Step

x += vx;
y += vy;

life--;
if (life <= 0) instance_destroy();

// Destroy on walls
if (place_meeting(x, y, obj_solid)) {
    instance_destroy();
}

// Enemy bullets can damage player
if (variable_instance_exists(id, "is_enemy") && is_enemy) {

    var plr = instance_place(x, y, obj_player);
    if (instance_exists(plr)) {

        var dd = 8;
        if (variable_instance_exists(id, "dmg")) dd = dmg;

        // call player damage gate
        if (variable_instance_exists(plr, "player_take_stress")) {
            plr.player_take_stress(dd, x, y);
        }

        instance_destroy();
        exit;
    }
}