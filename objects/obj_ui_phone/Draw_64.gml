/// obj_ui_phone : Draw GUI

var gw = display_get_gui_width();
var gh = display_get_gui_height();

var phone_w = clamp(round(gw * 0.30), 280, 420);
var x0 = gw - phone_w;
var y0 = 0;
var w  = phone_w;
var h  = gh;

// Background
draw_set_color(col_bg);
draw_rectangle(x0, y0, x0 + w, y0 + h, false);

// Status bar
var status_h = 28;
draw_set_color(col_panel);
draw_rectangle(x0, y0, x0 + w, y0 + status_h, false);

draw_set_color(col_text);
draw_text(x0 + pad, y0 + 6, phone_active ? "PHONE" : "PHONE (inactive)");
draw_text(x0 + w - pad - 70, y0 + 6, "LTE  87%");

// Header
var header_h2 = 56;
var hy = y0 + status_h;
draw_set_color(col_panel);
draw_rectangle(x0, hy, x0 + w, hy + header_h2, false);

// Screen title
draw_set_color(col_text);
var title = "Home";
if (screen == SCREEN_CHAT)     title = "Messenger";
if (screen == SCREEN_STOCKS)   title = "Stocks";
if (screen == SCREEN_DOPAMINE) title = "Dopamine";
draw_text(x0 + pad, hy + 18, title);

// Content box area
var cx = x0 + pad;
var cy = hy + header_h2 + pad;
var cw = w - pad*2;
var ch = h - (status_h + header_h2 + pad*2 + 36); // leave footer

draw_set_color(col_line);
draw_rectangle(cx, cy, cx + cw, cy + ch, true);

// Footer hint bar
var fy1 = y0 + h - 36;
draw_set_color(col_panel);
draw_rectangle(x0, fy1, x0 + w, y0 + h, false);

draw_set_color(phone_active ? c_lime : c_red);
draw_text(x0 + pad, fy1 + 10, phone_active ? "ACTIVE  (WASD + E, Q)" : "INACTIVE  (TAB)");

// ----- DRAW PER SCREEN -----
if (screen == SCREEN_HOME) {

    // App grid
    var gap  = 14;
    var icon = floor(min(84, (cw - (cols - 1) * gap) / cols));

    var start_row = scroll_row;
    var end_row   = start_row + rows_visible - 1;

    var idx = start_row * cols;

    for (var r = start_row; r <= end_row; r++) {
        for (var c = 0; c < cols; c++) {
            if (idx >= array_length(apps)) break;

            var app_idx = idx;

            var ix = cx + c * (icon + gap);
            var iy = cy + (r - start_row) * (icon + 30 + gap);

            // icon box
            var is_sel = (app_idx == sel);
            draw_set_color(is_sel ? make_color_rgb(90, 90, 120) : make_color_rgb(55, 55, 66));
            draw_rectangle(ix, iy, ix + icon, iy + icon, false);

            // Notification badge for Chat app (total unread)
            if (apps[app_idx].label == "Chat") {
                var total_unread = wife_unread + lover_unread;
                if (total_unread > 0) {
                    var bx = ix + icon - 16;
                    var by = iy + 10;

                    draw_set_color(c_red);
                    draw_circle(bx, by, 10, false);

                    draw_set_color(c_white);
                    draw_set_halign(fa_center);
                    draw_set_valign(fa_middle);
                    draw_text(bx, by, string(min(total_unread, 99)));
                    draw_set_halign(fa_left);
                    draw_set_valign(fa_top);
                }
            }

            // label
            draw_set_color(col_text);
            draw_set_halign(fa_center);
            draw_text(ix + icon * 0.5, iy + icon + 6, apps[app_idx].label);
            draw_set_halign(fa_left);

            idx++;
        }
    }

    // Scroll indicator
    var total_rows = ceil(array_length(apps) / cols);
    draw_set_color(col_text);
    draw_text(cx + 10, cy + ch - 24,
        "Row " + string(scroll_row + 1) + "/" + string(max(1, total_rows - rows_visible + 1))
    );
}

else if (screen == SCREEN_CHAT) {

    // --- MSG_LIST UI ---
    if (msg_state == MSG_LIST) {
        draw_set_color(col_text);
        draw_text(cx + 10, cy + 10, "Chats");

        var item_h  = 46;
        var list_x1 = cx + 10;
        var list_x2 = cx + cw - 10;

        for (var i = 0; i < 2; i++) {
            var iy = cy + 40 + i * (item_h + 10);
            var sel_now = (i == msg_chat_sel);

            draw_set_color(sel_now ? make_color_rgb(90, 90, 120) : make_color_rgb(55, 55, 66));
            draw_rectangle(list_x1, iy, list_x2, iy + item_h, false);

            draw_set_color(col_text);
            var name = (i == 0) ? "Wife" : "Lover";
            draw_text(list_x1 + 12, iy + 14, name);

            // Unread badge per chat
            var unread = (i == 0) ? wife_unread : lover_unread;
            if (unread > 0) {
                var bx = list_x2 - 20;
                var by = iy + item_h * 0.5;

                draw_set_color(c_red);
                draw_circle(bx, by, 10, false);

                draw_set_color(c_white);
                draw_set_halign(fa_center);
                draw_set_valign(fa_middle);
                draw_text(bx, by, string(min(unread, 99)));
                draw_set_halign(fa_left);
                draw_set_valign(fa_top);
            }
        }

        draw_set_color(col_text);
        draw_text(cx + 10, cy + ch - 26, "W/S select   E open   Q back");
    }

    // --- MSG_THREAD UI ---
    else if (msg_state == MSG_THREAD) {

        var who = (msg_chat_sel == 0) ? "Wife" : "Lover";
        draw_set_color(col_text);
        draw_text(cx + 10, cy + 10, who);

        // Messages area
        var msg_y      = cy + 40;
        var msg_bottom = cy + ch - 110;

        var arr = (msg_chat_sel == 0) ? wife_msgs : lover_msgs;

        // Draw last messages that fit (simple)
        var start = max(0, array_length(arr) - 8);
        for (var i = start; i < array_length(arr); i++) {
            draw_text(cx + 10, msg_y, arr[i]);
            msg_y += 22;
            if (msg_y > msg_bottom) break;
        }

        // Reply options area
        var opt_y1 = cy + ch - 92;
        var opt_y2 = cy + ch - 18;

        draw_set_color(col_line);
        draw_rectangle(cx + 10, opt_y1, cx + cw - 10, opt_y2, true);

        var optA = (msg_chat_sel == 0) ? wife_options[0] : lover_options[0];
        var optB = (msg_chat_sel == 0) ? wife_options[1] : lover_options[1];

        var bx1 = cx + 14;
        var bx2 = cx + cw - 14;
        var bh  = 30;

        for (var k = 0; k < 2; k++) {
            var by = opt_y1 + 8 + k * (bh + 8);
            var is_sel = (k == msg_opt_sel);

            draw_set_color(is_sel ? make_color_rgb(90, 90, 120) : make_color_rgb(55, 55, 66));
            draw_rectangle(bx1, by, bx2, by + bh, false);

            draw_set_color(col_text);
            draw_set_halign(fa_center);
            draw_set_valign(fa_middle);
            draw_text((bx1 + bx2) * 0.5, by + bh * 0.5, (k == 0) ? optA : optB);
            draw_set_halign(fa_left);
            draw_set_valign(fa_top);
        }

        draw_set_color(col_text);
        draw_text(cx + 10, cy + ch - 106, "W/S select reply   E choose   Q back");
    }

    // --- MSG_TYPE UI (spell-check typing) ---
    else if (msg_state == MSG_TYPE) {

        draw_set_color(col_text);
        draw_text(cx + 10, cy + 10, "Spell-check (type EXACTLY):");

        // Target phrase box
        draw_set_color(col_line);
        draw_rectangle(cx + 10, cy + 40, cx + cw - 10, cy + 84, true);

        draw_set_color(col_text);
        draw_text(cx + 16, cy + 52, chat_norm(msg_target));

        // Input box
        var in_y1 = cy + ch - 80;
        var in_y2 = cy + ch - 18;

        draw_set_color(col_line);
        draw_rectangle(cx + 10, in_y1, cx + cw - 10, in_y2, true);

        // Correctness coloring (NORMALIZED)
        var tgtN = chat_norm(msg_target);
        var typN = chat_norm(msg_typed);

        var len_t = string_length(typN);

        var prefix_ok = true;
        if (len_t > 0) {
            prefix_ok = (typN == string_copy(tgtN, 1, len_t));
        }
        var fully_ok = (typN == tgtN);

        var tcol = col_neut;
        if (len_t > 0 && !prefix_ok) tcol = col_bad;
        if (fully_ok) tcol = col_ok;

        draw_set_color(tcol);
        draw_text(cx + 16, in_y1 + 10, msg_typed);

        // Hints
        draw_set_color(col_text);
        if (fully_ok) {
            draw_text(cx + 10, cy + ch - 104, "Correct! Press E to send.   Q cancel");
        } else {
            draw_text(cx + 10, cy + ch - 104, "Type it exactly. Red = mismatch.   Q cancel");
        }
    }
}

else if (screen == SCREEN_STOCKS) {

    // Big USD cash
    draw_set_color(col_text);
    draw_text(cx + 10, cy + 10, "CASH (USD)");

    draw_set_color(c_white);
    draw_set_halign(fa_left);
    draw_text(cx + 10, cy + 36, "$" + string_format(global.usd_cash, 0, 2));

    // Smaller stats
    draw_set_color(col_text);
    draw_text(cx + 10, cy + 62, "Ticker: " + stock_symbol);
    draw_text(cx + 10, cy + 82, "Price: $" + string_format(stock_price, 0, 2));
    draw_text(cx + 10, cy + 102, "Shares: " + string(global.stock_shares));

    // Graph box
    var gx1 = cx + 10;
    var gy1 = cy + 130;
    var gx2 = cx + cw - 10;
    var gy2 = cy + 270;

    draw_set_color(col_line);
    draw_rectangle(gx1, gy1, gx2, gy2, true);

    // Find min/max in history
    var pmin =  1000000000;
    var pmax = -1000000000;

    for (var i = 0; i < price_hist_len; i++) {
        var p = price_hist[i];
        if (p < pmin) pmin = p;
        if (p > pmax) pmax = p;
    }

    if (pmax - pmin < 0.001) { pmax = pmin + 0.001; }

    draw_set_color(c_white);

    var plot_w = gx2 - gx1;
    var plot_h = gy2 - gy1;

    var idx0 = price_hist_i;

    var prev_x = gx1;
    var p0 = price_hist[idx0];
    var prev_y = gy2 - ((p0 - pmin) / (pmax - pmin)) * plot_h;

    for (var k = 1; k < price_hist_len; k++) {
        var idx2 = (idx0 + k) mod price_hist_len;
        var px = gx1 + (k / (price_hist_len - 1)) * plot_w;

        var pp = price_hist[idx2];
        var py = gy2 - ((pp - pmin) / (pmax - pmin)) * plot_h;

        draw_line(prev_x, prev_y, px, py);

        prev_x = px;
        prev_y = py;
    }

    // Buttons under graph
    var by = gy2 + 14;
    var bw = (cw - 30) * 0.5;
    var bh = 40;

    var buy_x1  = cx + 10;
    var buy_x2  = buy_x1 + bw;

    var sell_x2 = cx + cw - 10;
    var sell_x1 = sell_x2 - bw;

    draw_set_color(stock_btn_sel == 0 ? make_color_rgb(90, 90, 120) : make_color_rgb(55, 55, 66));
    draw_rectangle(buy_x1, by, buy_x2, by + bh, false);

    draw_set_color(stock_btn_sel == 1 ? make_color_rgb(90, 90, 120) : make_color_rgb(55, 55, 66));
    draw_rectangle(sell_x1, by, sell_x2, by + bh, false);

    draw_set_color(col_text);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text((buy_x1 + buy_x2) * 0.5,  by + bh * 0.5, "BUY");
    draw_text((sell_x1 + sell_x2) * 0.5, by + bh * 0.5, "SELL");
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);

    draw_set_color(col_text);
    draw_text(cx + 10, by + bh + 10, "W/S select   E confirm   Q back");
}

else if (screen == SCREEN_DOPAMINE) {

    // Simple placeholder brainrot panel
    draw_set_color(col_text);
    draw_text(cx + 10, cy + 10, "Dopamine Feed");

    draw_set_color(col_line);
    draw_rectangle(cx + 10, cy + 40, cx + cw - 10, cy + ch - 10, true);

    draw_set_color(col_text);
    draw_text(cx + 18, cy + 58, "[brainrot gameplay goes here]");
    draw_text(cx + 18, cy + 80, "Viewing this reduces stress.");
    draw_text(cx + 18, cy + 102, "Press Q to return.");
}


// ============================================================================
// OUT-OF-PHONE MESSAGE NOTIFICATION (FIXED)
// ============================================================================
if (!phone_active) {

    // Always restore sane draw state before HUD bits
    draw_set_alpha(1);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);

    var total_unread2 = wife_unread + lover_unread;

    // blink every half-second
    var blink_on = true;
    blink_on = (notif_blink_t < room_speed * 0.5);

    // Use YOUR configured HUD position
    var bx = notif_x;
    var by = notif_y;

    // 1) Persistent unread badge
    if (total_unread2 > 0) {

        draw_set_alpha(0.95);

        // background (filled black)
        draw_set_color(c_black);
        draw_rectangle(bx - 6, by - 6, bx + 190, by + 30, false);

        // fill (FILLED color — this was the bug)
        draw_set_color(blink_on ? c_aqua : c_white);
        draw_rectangle(bx - 4, by - 4, bx + 188, by + 28, false);

        // optional outline
        draw_set_color(c_black);
        draw_rectangle(bx - 4, by - 4, bx + 188, by + 28, true);

        // text (black on bright fill is fine)
        draw_set_color(c_black);
        draw_text(bx + 8,  by + 4, "MESSAGES: " + string(min(total_unread2, 99)));
        draw_text(bx + 120, by + 4, "W:" + string(min(wife_unread, 99)) + " L:" + string(min(lover_unread, 99)));

        draw_set_alpha(1);
    }

    // 2) Flash banner when new message arrives
    if (notif_flash > 0) {

        var fy = by + 38;

        draw_set_alpha(0.95);

        // background (filled black)
        draw_set_color(c_black);
        draw_rectangle(bx - 6, fy - 6, bx + 190, fy + 24, false);

        // fill (FILLED lime — this was the bug)
        draw_set_color(c_lime);
        draw_rectangle(bx - 4, fy - 4, bx + 188, fy + 22, false);

        // outline
        draw_set_color(c_black);
        draw_rectangle(bx - 4, fy - 4, bx + 188, fy + 22, true);

        // text
        draw_set_color(c_black);
        draw_text(bx + 8, fy + 1, "NEW MESSAGE");

        draw_set_alpha(1);
    }
}