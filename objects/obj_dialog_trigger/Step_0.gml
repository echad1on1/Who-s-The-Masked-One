/// obj_dialog_trigger : Step
if (activated) exit;

var plr = instance_find(obj_player, 0);
if (!instance_exists(plr)) exit;

// choose your own trigger condition; here: distance-based
if (point_distance(x, y, plr.x, plr.y) < 24) {
    activated = true;

    var phone = instance_find(obj_ui_phone, 0);
    if (instance_exists(phone)) {
        with (phone) {
            chat_queue_add(other.contact, other.dialog_id);
        }
    }
}
