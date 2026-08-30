/// obj_ui_phone : Step

// Toggle phone active
if (keyboard_check_pressed(vk_tab)) {
    phone_active = !phone_active;
    global.phone_focus = phone_active;

    // Acknowledge flash when opening phone
    if (phone_active) {
        if (!variable_instance_exists(id, "notif_flash")) notif_flash = 0;
        notif_flash = 0;
    }

    // If closing the phone, reset typing buffer/state to avoid stuck text
    if (!phone_active) {
        keyboard_string = "";
        msg_typed = "";
        if (msg_state == MSG_TYPE) msg_state = MSG_THREAD;
    }
}

/// --- STOCK MARKET ALWAYS RUNS ---
price_tick++;
if (price_tick >= price_tick_frames) {
    price_tick = 0;

    // Occasionally shift regime
    if (stock_regime_timer <= 0) {
        stock_regime_timer = irandom_range(90, 220); // ticks
        stock_trend = choose(-0.05, -0.03, 0.0, 0.03, 0.05);
    } else {
        stock_regime_timer--;
    }

    // Ensure velocity exists
    if (!variable_instance_exists(id, "stock_v")) stock_v = 0;

    // Smoothness knobs
    var vol = stock_vol * (1 + stock_vol_mod);

    // soft "normal-ish" random
    var shock = (random(1) + random(1) + random(1) - 1.5) * vol;

    var pull  = (stock_mu - stock_price) * stock_k;
    var drift = stock_trend + stock_drift_mod;

    stock_v = stock_v * stock_mom + pull + drift + shock;
    stock_price += stock_v;

    stock_price = max(stock_price, 0.10);

    // history ring buffer
    price_hist[price_hist_i] = stock_price;
    price_hist_i = (price_hist_i + 1) mod price_hist_len;
}

// frame counter for timeout logic
current_frame++;

// timeouts should run even if phone is closed
chat_tick_timeouts(CONTACT_WIFE);
chat_tick_timeouts(CONTACT_LOVER);

/// --- OUT-OF-PHONE NOTIF TRACKING (runs even when phone is closed) ---

// Safety init in case you forgot to add these in Create
if (!variable_instance_exists(id, "notif_prev_total")) notif_prev_total = 0;
if (!variable_instance_exists(id, "notif_flash"))      notif_flash = 0;
if (!variable_instance_exists(id, "notif_blink_t"))    notif_blink_t = 0;

function get_unread_for(_chat_sel)
{
    // Prefer your existing locals (as seen in Draw GUI)
    if (_chat_sel == 0) {
        if (variable_instance_exists(id, "wife_unread")) return wife_unread;
        if (variable_global_exists("unread_wife")) return global.unread_wife;
    } else {
        if (variable_instance_exists(id, "lover_unread")) return lover_unread;
        if (variable_global_exists("unread_lover")) return global.unread_lover;
    }

    // Optional: if you later store as array
    if (variable_global_exists("chat_unread")) return global.chat_unread[_chat_sel];

    return 0;
}

var unread_w = get_unread_for(0);
var unread_l = get_unread_for(1);
var unread_total = unread_w + unread_l;

// Detect new message arrival (unread increased)
if (unread_total > notif_prev_total) {
    notif_flash = room_speed; // 1 second flash
    // optional sound
    // audio_play_sound(snd_msg, 1, false);
}

// Update previous
notif_prev_total = unread_total;

// tick timers
if (notif_flash > 0) notif_flash--;
notif_blink_t = (notif_blink_t + 1) mod room_speed;

// If phone not active, do nothing (and don't consume input)
if (!phone_active) exit;

// Common keys
var back_pressed = keyboard_check_pressed(ord("Q")) || keyboard_check_pressed(vk_escape);
var open_pressed = keyboard_check_pressed(ord("E"));

// --- HOME SCREEN: WASD moves selection + scrolls by rows ---
if (screen == SCREEN_HOME) {

    var app_count = array_length(apps);
    var total_rows = ceil(app_count / cols);

    // Move selection
    if (keyboard_check_pressed(ord("A"))) sel = max(sel - 1, 0);
    if (keyboard_check_pressed(ord("D"))) sel = min(sel + 1, app_count - 1);

    if (keyboard_check_pressed(ord("W"))) sel = max(sel - cols, 0);
    if (keyboard_check_pressed(ord("S"))) sel = min(sel + cols, app_count - 1);

    // Keep selection inside valid row/col bounds (prevents weird jumps on last row)
    sel = clamp(sel, 0, app_count - 1);

    // Auto-scroll so selected row stays visible
    var sel_row = sel div cols;

    if (sel_row < scroll_row) scroll_row = sel_row;
    if (sel_row >= scroll_row + rows_visible) scroll_row = sel_row - rows_visible + 1;

    scroll_row = clamp(scroll_row, 0, max(0, total_rows - rows_visible));

    // Open app with E (only if it has a real screen)
    if (open_pressed) {
        var target_screen = apps[sel].screen;
        if (target_screen != -1) {
            screen = target_screen;
        }
    }
}

// --- CHAT SCREEN ---
else if (screen == SCREEN_CHAT) {

    // ---- MSG_LIST: choose Wife/Lover ----
    if (msg_state == MSG_LIST) {

        if (keyboard_check_pressed(ord("W"))) msg_chat_sel = max(0, msg_chat_sel - 1);
        if (keyboard_check_pressed(ord("S"))) msg_chat_sel = min(1, msg_chat_sel + 1);

        if (open_pressed) {
            msg_state = MSG_THREAD;
            msg_opt_sel = 0;

            // Clear unread for the opened chat
            chat_clear_unread(msg_chat_sel);
        }

        // Q exits messenger back to Home
        if (back_pressed) {
            screen = SCREEN_HOME;
            msg_state = MSG_LIST;
        }
    }

    // ---- MSG_THREAD: view chat + choose reply option ----
    else if (msg_state == MSG_THREAD) {

        if (keyboard_check_pressed(ord("W"))) msg_opt_sel = max(0, msg_opt_sel - 1);
        if (keyboard_check_pressed(ord("S"))) msg_opt_sel = min(1, msg_opt_sel + 1);

        if (open_pressed) {

            var contact = (msg_chat_sel == 0) ? CONTACT_WIFE : CONTACT_LOVER;

            // Only allow reply if director is actually waiting for it
            if (chat_can_reply(contact)) {

                if (msg_chat_sel == 0) msg_target = wife_options[msg_opt_sel];
                else                   msg_target = lover_options[msg_opt_sel];

                msg_typed = "";
                keyboard_string = ""; // clear buffer
                msg_state = MSG_TYPE;

            } else {
                // Not awaiting a reply — ignore (or you can play a sound here)
                // audio_play_sound(snd_denied, 1, false);
            }
        }

        // Q returns to chat list
        if (back_pressed) {
            msg_state = MSG_LIST;
        }
    }

    // ---- MSG_TYPE: spell-check typing ----
    else if (msg_state == MSG_TYPE) {

        // Clamp using NORMALIZED target length (fixes curly apostrophes mismatch)
        var tgtN = chat_norm(msg_target);
        var maxlen = string_length(tgtN);

        var typed_raw = keyboard_string;

        // Strip newlines just in case (enter key)
        typed_raw = string_replace_all(typed_raw, "\n", "");
        typed_raw = string_replace_all(typed_raw, "\r", "");

        // Clamp length
        if (string_length(typed_raw) > maxlen) {
            typed_raw = string_copy(typed_raw, 1, maxlen);
            keyboard_string = typed_raw;
        }

        msg_typed = typed_raw;

        // Normalize typed
        var typN = chat_norm(msg_typed);

        // Use normalized length for prefix test
        var lenN = string_length(typN);

        var prefix_ok = true;
        if (lenN > 0) {
            var target_prefix = string_copy(tgtN, 1, lenN);
            prefix_ok = (typN == target_prefix);
        }

        var fully_ok = (typN == tgtN);

        // If fully correct, E sends
        if (fully_ok && open_pressed) {

            // Append player's message to correct history
            if (msg_chat_sel == 0) {
                var n0 = array_length(wife_msgs);
                wife_msgs[n0] = "You: " + msg_target;
                chat_on_player_reply(CONTACT_WIFE, msg_opt_sel);
            } else {
                var m0 = array_length(lover_msgs);
                lover_msgs[m0] = "You: " + msg_target;
                chat_on_player_reply(CONTACT_LOVER, msg_opt_sel);
            }

            // Back to thread options
            keyboard_string = "";
            msg_typed = "";
            msg_state = MSG_THREAD;
        }

        // Q cancels typing (back to thread)
        if (back_pressed) {
            keyboard_string = "";
            msg_typed = "";
            msg_state = MSG_THREAD;
        }
    }
}

// --- STOCKS SCREEN ---
else if (screen == SCREEN_STOCKS) {

    // Back to Home
    if (back_pressed) {
        screen = SCREEN_HOME;
        exit;
    }

    // Button selection (A/D)
    if (keyboard_check_pressed(ord("A"))) stock_btn_sel = max(0, stock_btn_sel - 1);
    if (keyboard_check_pressed(ord("D"))) stock_btn_sel = min(1, stock_btn_sel + 1);

    // --- BUY / SELL ---
    if (open_pressed) {

        if (stock_btn_sel == 0) {
            // BUY 1 share
            if (global.usd_cash >= stock_price) {
                global.usd_cash -= stock_price;
                global.stock_shares += 1;
            }
        } else {
            // SELL 1 share
            if (global.stock_shares > 0) {
                global.stock_shares -= 1;
                global.usd_cash += stock_price;
            }
        }
    }
}

// --- DOPAMINE SCREEN ---
else if (screen == SCREEN_DOPAMINE) {

    // Back to Home
    if (back_pressed) {
        screen = SCREEN_HOME;
        exit;
    }

    // Heal stress ONLY while actively viewing dopamine app
    // (phone_active is already true here because we exit earlier if not active)
    var plr = instance_find(obj_player, 0);
    if (instance_exists(plr)) {
        var heal = dopamine_heal_per_sec / room_speed;
        plr.stress = clamp(plr.stress - heal, 0, plr.stress_max);
    }
}