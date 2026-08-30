/// obj_shop : Draw

draw_self();

if (show_prompt) {
    draw_set_color(c_white);
    var msg = "Press 'E' to purchase " + shop_weapon_name + " for $" + string_format(shop_price, 0, 2);
    draw_text(x - 140, y - 40, msg);
}
