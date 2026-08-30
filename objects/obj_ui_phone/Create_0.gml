/// obj_ui_phone : Create

// ============================================================
// UI / APPS SETUP (define UI variables FIRST)
// ============================================================

// Layout
pad      = 18;
header_h = 44;
tab_h    = 36;

// Colors (temporary placeholder style)
col_dim    = c_black;
col_bg     = make_color_rgb(18, 18, 22);
col_panel  = make_color_rgb(28, 28, 34);
col_line   = make_color_rgb(80, 80, 95);
col_text   = c_white;

// Optional: turn this off later
show_debug = true;

// Phone focus toggle
phone_active = false;          // TAB toggles this
global.phone_focus = false;    // gameplay reads this

// --- UI screens ---
SCREEN_HOME     = 0;
SCREEN_CHAT     = 1;
SCREEN_STOCKS   = 2;
SCREEN_DOPAMINE = 3;

screen = SCREEN_HOME;

// --- app grid config ---
cols = 3;
rows_visible = 4;
sel = 0;
scroll_row = 0;

// App list
apps = [
    { label: "Chat",     screen: SCREEN_CHAT   },
    { label: "Stocks",   screen: SCREEN_STOCKS },
    { label: "Dopamine", screen: SCREEN_DOPAMINE },
    { label: "Notes",    screen: -1 },
    { label: "Mail",     screen: -1 },
    { label: "Maps",     screen: -1 },
    { label: "Camera",   screen: -1 },
    { label: "Music",    screen: -1 },
    { label: "Gallery",  screen: -1 },
    { label: "Files",    screen: -1 },
    { label: "???",      screen: -1 },
    { label: "???",      screen: -1 }
];

// --- Messenger sub-states ---
MSG_LIST   = 0;
MSG_THREAD = 1;
MSG_TYPE   = 2;

msg_state = MSG_LIST;
msg_chat_sel = 0;       // 0 = Wife, 1 = Lover
msg_opt_sel  = 0;       // 0/1
msg_target   = "";
msg_typed    = "";

// Separate chat histories (must exist before director uses them!)
wife_msgs  = ["Wife: Are you serious right now?"];
lover_msgs = ["Lover: Hello??"];

// Options get overwritten by director when awaiting reply
wife_options  = ["-", "-"];
lover_options = ["-", "-"];

// Typing feedback colors
col_ok    = c_lime;
col_bad   = c_red;
col_neut  = col_text;

// --- Notifications (unread counts) ---
wife_unread  = 0;
lover_unread = 0;

// ============================================================
// STOCKS APP SETUP
// ============================================================
// --- GLOBAL STOCK MONEY (single source of truth) ---
if (!variable_global_exists("usd_cash")) global.usd_cash = 500.00;
if (!variable_global_exists("stock_shares")) global.stock_shares = 0;

// price can stay local (stock_price) since it's just market state

stock_symbol = "JANUS D.0.0";

// Price sim state
stock_price = 25.00;

// history graph
price_hist_len = 120;
price_hist = array_create(price_hist_len, stock_price);
price_hist_i = 0;

// input selection for Buy/Sell
stock_btn_sel = 0; // 0=BUY, 1=SELL

// pacing
price_tick_frames = 10;
price_tick = 0;

// algorithm parameters
stock_mu    = 25.0;
stock_k     = 0.020;
stock_vol   = 0.35;
stock_mom   = 0.85;
stock_trend = 0.00;
stock_regime_timer = 0;

stock_drift_mod = 0.0;
stock_vol_mod   = 0.0;

// ============================================================
// DOPAMINE APP SETUP
// ============================================================
dopamine_heal_per_sec = 18;

/// --- OUT-OF-PHONE NOTIFICATIONS ---
notif_prev_total = 0;   // last known total unread
notif_flash = 0;        // frames to flash "NEW MESSAGE"
notif_blink_t = 0;      // for blinking icon

// HUD position (GUI coords)
notif_x = 24;
notif_y = display_get_gui_height() - 24; // temporary; we'll do proper bottom-left in Draw GUI

// optional sound (only if you have it)
// snd_msg = snd_message; // set to your asset, or leave commented

// ============================================================
// GLOBAL ONE-TIME SETUP (code + relationship vars + fired flags)
// ============================================================
if (!variable_global_exists("core_code")) {
    global.core_code = irandom_range(1000, 9999);

    // 0 = wife has it, 1 = lover has it
    global.code_holder = irandom(1);
    global.wife_has_code  = (global.code_holder == 0);
    global.lover_has_code = (global.code_holder == 1);

    if (!variable_global_exists("WIFE_APPROVAL"))  global.WIFE_APPROVAL  = 0;
    if (!variable_global_exists("LOVER_APPROVAL")) global.LOVER_APPROVAL = 0;

    global.wife_fired  = array_create(64, false);
    global.lover_fired = array_create(64, false);
}

// ============================================================
// CONVERSATION DIRECTOR
// ============================================================
CONTACT_WIFE  = 0;
CONTACT_LOVER = 1;

// tuning (frames @ 60fps)
chat_delay_fast_min = 8;
chat_delay_fast_max = 22;
chat_delay_norm_min = 18;
chat_delay_norm_max = 55;

chat_reply_deadline_min = 180;
chat_reply_deadline_max = 360;

wife_code_threshold  = 1;
lover_code_threshold = 1;

// angry pools
chat_angry_pool_wife = [
    "Wife: Wow. Okay.",
    "Wife: Seriously?",
    "Wife: You love doing this to me."
];

chat_angry_pool_lover = [
    "Lover: Hello??",
    "Lover: Are you ignoring me?",
    "Lover: Wow. Okay."
];

// frame counter
if (!variable_instance_exists(id, "current_frame")) current_frame = 0;

// state structs
wife_state = {
    busy: false,
    active_id: -1,
    pending: [],
    pending_i: 0,
    awaiting_reply: false,
    reply_deadline: 0,
    reply_idle: 0,
    angry_used: false,
    cur_optA: "",
    cur_optB: "",
    cur_afterA: [],
    cur_afterB: [],
    cur_deltaA: 0,
    cur_deltaB: 0
};


lover_state = {
    busy: false,
    active_id: -1,
    pending: [],
    pending_i: 0,
    awaiting_reply: false,
    reply_deadline: 0,
	reply_idle: 0,
    angry_used: false,
    cur_optA: "",
    cur_optB: "",
    cur_afterA: [],
    cur_afterB: [],
    cur_deltaA: 0,
    cur_deltaB: 0
};

// queues
wife_queue = [];
wife_qi = 0;

lover_queue = [];
lover_qi = 0;

// --- helpers ---

chat_state_get = function(contact) {
    return (contact == CONTACT_WIFE) ? wife_state : lover_state;
};

chat_msgs_get = function(contact) {
    return (contact == CONTACT_WIFE) ? wife_msgs : lover_msgs;
};

chat_msgs_set = function(contact, arr) {
    if (contact == CONTACT_WIFE) wife_msgs = arr; else lover_msgs = arr;
};

chat_options_set = function(contact, optA, optB) {
    if (contact == CONTACT_WIFE) wife_options = [optA, optB]; else lover_options = [optA, optB];
};

chat_rel_add = function(contact, delta) {
    if (contact == CONTACT_WIFE) global.WIFE_APPROVAL += delta; else global.LOVER_APPROVAL += delta;
};

chat_norm = function(s) {
    s = string_replace_all(s, "’", "'");
    s = string_replace_all(s, "‘", "'");
    s = string_replace_all(s, "“", "\"");
    s = string_replace_all(s, "”", "\"");
    s = string_replace_all(s, "…", "...");
    return s;
};

chat_can_reply = function(contact) {
    var st = chat_state_get(contact);
    return (st.busy && st.awaiting_reply);
};

// Treat "Messenger open" as seen for unread counting
chat_is_viewing_contact = function(contact) {
    if (!phone_active) return false;
    if (screen != SCREEN_CHAT) return false;

    if (msg_state == MSG_LIST) return true;

    if (msg_state == MSG_THREAD || msg_state == MSG_TYPE) {
        return (msg_chat_sel == contact);
    }
    return false;
};

chat_add_unread = function(contact, amount) {
    if (contact == CONTACT_WIFE) wife_unread = max(0, wife_unread + amount);
    else lover_unread = max(0, lover_unread + amount);
};

chat_clear_unread = function(contact) {
    if (contact == CONTACT_WIFE) wife_unread = 0; else lover_unread = 0;
};

chat_push_pending = function(contact, lines_array) {
    var st = chat_state_get(contact);

    var old_len = array_length(st.pending);
    var add_len = array_length(lines_array);

    var new_arr = array_create(old_len + add_len, "");
    for (var i = 0; i < old_len; i++) new_arr[i] = st.pending[i];
    for (var j = 0; j < add_len; j++) new_arr[old_len + j] = lines_array[j];

    st.pending = new_arr;
};

chat_schedule_next = function(contact) {
    var st = chat_state_get(contact);
    if (st.pending_i >= array_length(st.pending)) return;

    var first = (st.pending_i == 0);
    var dmin = first ? chat_delay_fast_min : chat_delay_norm_min;
    var dmax = first ? chat_delay_fast_max : chat_delay_norm_max;

    var delay = irandom_range(dmin, dmax);

    if (contact == CONTACT_WIFE) alarm[0] = delay; else alarm[1] = delay;
};

chat_try_start_next = function(contact) {
    var st = chat_state_get(contact);
    if (st.busy) return;

    var q  = (contact == CONTACT_WIFE) ? wife_queue : lover_queue;
    var qi = (contact == CONTACT_WIFE) ? wife_qi    : lover_qi;

    if (qi >= array_length(q)) return;

    var next_id = q[qi];
    if (contact == CONTACT_WIFE) wife_qi++; else lover_qi++;

    chat_start_node(contact, next_id);
};

chat_queue_add = function(contact, id) {
    if (contact == CONTACT_WIFE) {
        if (id >= 0 && id < array_length(global.wife_fired) && global.wife_fired[id]) return;
        if (id >= 0 && id < array_length(global.wife_fired)) global.wife_fired[id] = true;

        var n = array_length(wife_queue);
        wife_queue[n] = id;
        chat_try_start_next(CONTACT_WIFE);

    } else {
        if (id >= 0 && id < array_length(global.lover_fired) && global.lover_fired[id]) return;
        if (id >= 0 && id < array_length(global.lover_fired)) global.lover_fired[id] = true;

        var m = array_length(lover_queue);
        lover_queue[m] = id;
        chat_try_start_next(CONTACT_LOVER);
    }
};

chat_send_next_pending = function(contact) {
    var st = chat_state_get(contact);
    if (st.pending_i >= array_length(st.pending)) return;

    var msg = st.pending[st.pending_i];
    st.pending_i++;

    // append to history
    var arr = chat_msgs_get(contact);
    var n = array_length(arr);
    arr[n] = msg;
    chat_msgs_set(contact, arr);

    // unread if not viewing messenger/contact
    if (!chat_is_viewing_contact(contact)) {
        chat_add_unread(contact, 1);
    }

    if (st.pending_i < array_length(st.pending)) {
        chat_schedule_next(contact);
    } else {
        st.pending = [];
        st.pending_i = 0;

        if (st.awaiting_reply) {
            // old system used reply_deadline; we no longer need it
			st.reply_idle = 0;
			st.angry_used = false;

            chat_options_set(contact, st.cur_optA, st.cur_optB);
        } else {
            st.busy = false;
            st.active_id = -1;
            chat_try_start_next(contact);
        }
    }
};

chat_tick_timeouts = function(contact) {
    var st = chat_state_get(contact);
    if (!st.busy) return;
    if (!st.awaiting_reply) return;

    // Only count time while:
    // - phone is open
    // - on Messenger screen
    // - on THREAD screen (choosing options)
    // - and currently viewing THIS contact thread
    var on_choice_screen =
        phone_active
        && (screen == SCREEN_CHAT)
        && (msg_state == MSG_THREAD)
        && (msg_chat_sel == contact);

    if (!on_choice_screen) return;

    // 3 minutes threshold
    var angry_after = 180 * room_speed;

    st.reply_idle++;

    if (!st.angry_used && st.reply_idle >= angry_after) {
        st.angry_used = true;

        var angry = (contact == CONTACT_WIFE)
            ? choose(chat_angry_pool_wife[0], chat_angry_pool_wife[1], chat_angry_pool_wife[2])
            : choose(chat_angry_pool_lover[0], chat_angry_pool_lover[1], chat_angry_pool_lover[2]);

        var arr = chat_msgs_get(contact);
        var n = array_length(arr);
        arr[n] = angry;
        chat_msgs_set(contact, arr);

        // unread if not currently viewing (in practice, you ARE viewing, but keep it consistent)
        if (!chat_is_viewing_contact(contact)) {
            chat_add_unread(contact, 1);
        }

        chat_rel_add(contact, -1);
    }
};


// ------------------------------
// DIALOGUE DATABASE (YOUR FULL WIFE + LOVER)
// ------------------------------
chat_get_node = function(contact, id) {
    var node = { opener:[], optA:"", optB:"", afterA:[], afterB:[], deltaA:0, deltaB:0 };

    // ========== WIFE ==========
    if (contact == CONTACT_WIFE) {

        if (id == 1) {
            node.opener = ["Wife: You were supposed to be home two hours ago. Where the hell are you?"];
            node.optA = "Something came up at work. I’ll be extra late.";
            node.optB = "Damn, already? I think I lost track of time…";
            node.afterA = [
                "Wife: Something always comes up Heck.",
                "Wife: I wish you told me this before you married me.",
                "Wife: I don’t like spending nights alone, y’know.",
                "Wife: Especially not tonight."
            ];
            node.afterB = [
                "Wife: Don’t pull that bullshit on me.",
                "Wife: I’ve known you long enough to know that you’re a bad liar.",
                "Wife: What have you learned in that period?",
                "Wife: Leaving me alone like this, especially tonight."
            ];
            node.deltaA = +1;
            node.deltaB = 0;
            return node;
        }

        if (id == 2) {
            node.opener = ["Wife: You do know what tonight is, right?"];
            node.optA = "Why, what’s tonight?";
            node.optB = "Listen, I’m sorry, but I need to ask you something.";
            node.afterA = [
                "Wife: Of course you don’t know, why the hell would you?",
                "Wife: I bet you have all of the important dates listed down in your notes.",
                "Wife: ALL of the important dates."
            ];
            node.afterB = [
                "Wife: What you need to do is grow up.",
                "Wife: This isn’t a game, I’m not a number on a screen.",
                "Wife: I’m a real person damn it."
            ];
            node.deltaA = 0;
            node.deltaB = -1;
            return node;
        }

        if (id == 3) {
            node.opener = ["Wife: Are you actually working right now?"];
            node.optA = "Yes. And I hate that I am.";
            node.optB = "Listen, this is very important, I don’t want to fight tonight.";
            node.afterA = [
                "Wife: Sure Heck, and I’ll swallow that like I did every night.",
                "Wife: Or maybe I won’t.",
                "Wife: I don’t like your bullshit, but I REALLY don’t like being stood up."
            ];
            node.afterB = [
                "Wife: Oh I’m sorry, I’ll just shut up and totally disappear.",
                "Wife: You ungrateful bastard, it’s all about what you want.",
                "Wife: I don’t wanna be stood up, yet here we are."
            ];
            node.deltaA = +1;
            node.deltaB = -1;
            return node;
        }

        if (id == 4) {
            node.opener = [
                "Wife: I sat at the table for an hour, Heck.",
                "Wife: Like an idiot.",
                "Wife: Because I am."
            ];
            node.optA = "You’re not an idiot. I should’ve called.";
            node.optB = "I didn’t ask you to wait";
            node.afterA = [
                "Wife: That’s the least I expect on our anniversary.",
                "Wife: That’s alright, I had a nice drink and left.",
                "Wife: If you were there we probably would have just argued.",
                "Wife: I’m sick of that."
            ];
            node.afterB = [
                "Wife: Wow, you’re getting really good at this.",
                "Wife: You know, you’re right, I won’t wait for you next time.",
                "Wife: God knows when you’ll see me next time."
            ];
            node.deltaA = -2;
            node.deltaB = -1;
            return node;
        }

        if (id == 5) {
            node.opener = ["Wife: When was the last time you wanted to be home?"];
            node.optA = "Tonight. I just ruined it.";
            node.optB = "I don’t know anymore.";
            node.afterA = [
                "Wife: I would’ve even believed you if I was any younger.",
                "Wife: God, what a fool I am."
            ];
            node.afterB = [
                "Wife: I know, I can see that, I’m not blind.",
                "Wife: For God’s sake, talk to me sometimes you moron."
            ];
            node.deltaA = -1;
            node.deltaB = +2;
            return node;
        }

        if (id == 6) {
            node.opener = ["Wife: I don’t feel like your wife lately."];
            node.optA = "What do you feel like then?";
            node.optB = "That’s not fair.";
            node.afterA = [
                "Wife: An obligation.",
                "Wife: A checkbox you forgot to tick.",
                "Wife: Someone who waits while you live."
            ];
            node.afterB = [
                "Wife: Neither is sitting alone on our anniversary.",
                "Wife: I don’t care whether you feel something is fair or not."
            ];
            node.deltaA = +1;
            node.deltaB = -2;
            return node;
        }

        if (id == 9) {
            node.opener = ["Wife: Tell me something, and don’t be clever about it."];
            node.optA = "Okay.";
            node.optB = "I will, but I’ve got to ask you for something important first.";
            node.afterA = ["Wife: At least something."];
            node.afterB = ["Wife: Shut up damnit, not everything is about you."];
            node.deltaA = +1;
            node.deltaB = -2;
            return node;
        }

        if (id == 10) {
            node.opener = ["Wife: Is there somebody else?"];
            node.optA = "What? Of course not.";
            node.optB = "Listen, we really need to talk about something important…";
            node.afterA = [
                "Wife: That’s what they always say.",
                "Wife: Or at least that’s what I heard.",
                "Wife: I don’t know anymore."
            ];
            node.afterB = [
                "Wife: I can’t believe it.",
                "Wife: What the hell?",
                "Wife: Who are you?",
                "Wife: Who the hell are you?",
                "Wife: This isn’t the man I married.",
                "Wife: This is a husk."
            ];
            node.deltaA = +1;
            node.deltaB = -5; // "CHAT OVER" without blocking: crush approval
            return node;
        }

        if (id == 11) {
            node.opener = ["Wife: Are you happy when you’re not with me?"];
            node.optA = "Sometimes… And it’s scary.";
            node.optB = "I’m just tired, that’s all.";
            node.afterA = [
                "Wife: I know. I’ve been feeling the same.",
                "Wife: I don’t want us running from each other.",
                "Wife: What kind of a marriage is that?"
            ];
            node.afterB = [
                "Wife: You’re always tired.",
                "Wife: And I’m tired of excuses.",
                "Wife: You can tell it to somebody else."
            ];
            node.deltaA = +1;
            node.deltaB = -2;
            return node;
        }

        if (id == 12) {
            node.opener = ["Wife: Do you know what hurts the most?"];
            node.optA = "Tell me.";
            node.optB = "I have a feeling.";
            node.afterA = [
                "Wife: That some part of me still believes that you’re my entire world.",
                "Wife: I wait the entire day to see you when you come home.",
                "Wife: Some part of me wants to still be a teenager with you.",
                "Wife: Love and cuddle and kiss and other stupid and silly things."
            ];
            node.afterB = [
                "Wife: No, you don’t.",
                "Wife: You’re an emotional vacuum.",
                "Wife: It’s bad enough that you’re destroying yourself, but you’ll suck the rest and drown us."
            ];
            node.deltaA = +1;
            node.deltaB = -3;
            return node;
        }

        if (id == 13) {
            node.opener = ["Wife: This wasn’t about dinner, you know."];
            node.optA = "I know.";
            node.optB = "I messed up. I get it.";
            node.afterA = [
                "Wife: Stop acting like you know what I’m going to say.",
                "Wife: Try listening for once in your life."
            ];
            node.afterB = [
                "Wife: And that there’s the problem.",
                "Wife: You understand, you get it…",
                "Wife: But only after its gone to hell first."
            ];
            node.deltaA = -1;
            node.deltaB = +1;
            return node;
        }

        if (id == 14) {
            node.opener = [
                "Wife: The light in the hallway is still on.",
                "Wife: Like it matters."
            ];
            node.optA = "Why?";
            node.optB = "You didn’t have to.";
            node.afterA = [
                "Wife: Goes back to me being an idiot.",
                "Wife: I still half-expect you to walk in.",
                "Wife: God, I’m such a pathetic, crying mess."
            ];
            node.afterB = [
                "Wife: No one has to do anything.",
                "Wife: Least of all listen or talk."
            ];
            node.deltaA = 0;
            node.deltaB = -1;
            return node;
        }

        if (id == 15) {
            node.opener = ["Wife: Do you know how humiliating that is?"];
            node.optA = "I’m sorry.";
            node.optB = "You’re not humiliating yourself.";
            node.afterA = [
                "Wife: Yeah.",
                "Wife: I am too."
            ];
            node.afterB = [
                "Wife: Don’t tell me what I’m doing.",
                "Wife: How would you know?",
                "Wife: You’re “working”."
            ];
            node.deltaA = +1;
            node.deltaB = -1;
            return node;
        }

        if (id == 16) {
            node.opener = ["Wife: Do you remember our first apartment?"];
            node.optA = "The radiator never worked.";
            node.optB = "We didn’t even have curtains.";
            node.afterA = [
                "Wife: So we slept with sweaters on and nothing else.",
                "Wife: Under blankets and mountains of cloth.",
                "Wife: It was so warm."
            ];
            node.afterB = [
                "Wife: And the street and car lights would just stream in.",
                "Wife: It was so sweet to watch you work in the half-darkness",
                "Wife: We didn’t care who saw us."
            ];
            node.deltaA = 0;
            node.deltaB = +1;
            return node;
        }

        if (id == 17) {
            node.opener = ["Wife: We didn’t need much back then."];
            node.optA = "We had each other.";
            node.optB = "We were stupid.";
            node.afterA = ["Wife: Yeah.", "Wife: We did."];
            node.afterB = ["Wife: Maybe.", "Wife: But we were happy."];
            node.deltaA = +1;
            node.deltaB = -1;
            return node;
        }

        if (id == 18) {
            node.opener = ["Wife: It’s late."];
            node.optA = "Listen, I need you to do something.";
            node.optB = "Okay. Goodnight.";

            var good = (global.WIFE_APPROVAL >= wife_code_threshold);

            if (good) {
                if (global.wife_has_code) {
                    node.afterA = [
                        "Wife: Okay.",
                        "Wife: ...There’s a paper note here.",
                        "Wife: The number is " + string(global.core_code) + "."
                    ];
                } else {
                    node.afterA = [
                        "Wife: Okay.",
                        "Wife: I’m looking.",
                        "Wife: It’s not here."
                    ];
                }
            } else {
                node.afterA = [
                    "Wife: I can’t, I’m sorry.",
                    "Wife: I’ve got to go to sleep.",
                    "Wife: I’ll see you tomorrow."
                ];
            }

            node.afterB = ["Wife: Yeah.", "Wife: Goodnight."];

            node.deltaA = good ? +1 : -1;
            node.deltaB = -1;
            return node;
        }
    }

        // ========== LOVER ==========
    if (contact == CONTACT_LOVER) {

        // ID 001
        if (id == 1) {
            node.opener = ["Lover: Hey, are you busy."];
            node.optA = "Yes, but I can talk.";
            node.optB = "I just wanted to call you and ask you something.";

            node.afterA = [
                "Lover: Yeah, you’ve been that for a while."
            ];
            node.afterB = [
                "Lover: Really?",
                "Lover: I want to talk too, there’s been something on my mind."
            ];

            node.deltaA = 0;
            node.deltaB = +1;
            return node;
        }

        // ID 002
        if (id == 2) {
            node.opener = ["Lover: I want to talk about us."];
            node.optA = "What’s wrong?";
            node.optB = "We can talk plenty when I come over.";

            node.afterA = [
                "Lover: I saw you yesterday with you wife on a walk in the park.",
                "Lover: And, I don’t know.",
                "Lover: You looked happy to me.",
                "Lover: And you’ve been coming around less and less."
            ];
            node.afterB = [
                "Lover: That’s not what I mean.",
                "Lover: I saw you yesterday with you wife on a walk in the park.",
                "Lover: And, I don’t know.",
                "Lover: You looked happy to me.",
                "Lover: And you’ve been coming around less and less."
            ];

            node.deltaA = +1;
            node.deltaB = -1;
            return node;
        }

        // ID 003
        if (id == 3) {
            node.opener = [
                "Lover: Look, I’m not just here for you to have fun with. When you told me those things, I took you seriously.",
                "Lover: So, my question is, where is it?"
            ];

            node.optA = "Where’s what?";
            node.optB = "We’ll find it when I come over 😊";

            node.afterA = [
                "Lover: What you promised.",
                "Lover: That you’ll leave her, that we’ll build a life together.",
                "Lover: Is it always that easy for you to lie?"
            ];
            node.afterB = [
                "Lover: Don’t be such a tool, I’m serious.",
                "Lover: You promised me a life together.",
                "Lover: It’s been months, I’m damn sick and tired of waiting.",
                "Lover: I don’t want to be lied to anymore."
            ];

            node.deltaA = -1;
            node.deltaB = -1;
            return node;
        }

        // ID 004
        if (id == 4) {
            node.opener = ["Lover: Do you know how stupid I feel now?"];

            node.optA = "I never meant to make you feel that way.";
            node.optB = "You’re not stupid.";

            node.afterA = [
                "Lover: Stop talking empty.",
                "Lover: I don’t care for it one bit."
            ];
            node.afterB = [
                "Lover: Then stop treating me like I am",
                "Lover: Stop acting like I’m too dumb to see that you’ve been leading me on."
            ];

            node.deltaA = -1;
            node.deltaB = +1;
            return node;
        }

        // ID 005
        if (id == 5) {
            node.opener = [
                "Lover: When you’re with her…",
                "Lover: do you think about me at all?"
            ];

            node.optA = "Yes.";
            node.optB = "That’s not fair.";

            node.afterA = [
                "Lover: Good.",
                "Lover: I was hoping you’d say that."
            ];
            node.afterB = [
                "Lover: What the hell does that mean?",
                "Lover: Don’t act like you’re any kind of moral authority here."
            ];

            node.deltaA = +2;
            node.deltaB = -2;
            return node;
        }

        // ID 006
        if (id == 6) {
            node.opener = ["Lover: She doesn’t see you like I do."];

            node.optA = "She knows me better than anyone.";
            node.optB = "You see parts of me she doesn’t.";

            node.afterA = [
                "Lover: Then why are you with me?",
                "Lover: Answer that."
            ];
            node.afterB = [
                "Lover: Exactly.",
                "Lover: So why the hell are you so cold with me?"
            ];

            node.deltaA = -2;
            node.deltaB = +2;
            return node;
        }

        // ID 007
        if (id == 7) {
            node.opener = ["Lover: Better yet, tell me what am I doing here? Waiting?"];

            node.optA = "Not for long, I’m working on it.";
            node.optB = "You want me to just drop everything?";

            node.afterA = [
                "Lover: There we go again, just repeating the same old thing.",
                "Lover: If you don’t want to be serious, I don’t want to talk to you."
            ];
            node.afterB = [
                "Lover: Well, no, I understand that its not easy.",
                "Lover: But I have wishes too."
            ];

            node.deltaA = -1;
            node.deltaB = +1;
            return node;
        }

        // ID 008
        if (id == 8) {
            node.opener = [
                "Lover: I just need to understand one thing.",
                "Lover: How could you have been telling me that you love me when you still care about her like that?"
            ];

            node.optA = "No.";
            node.optB = "You’re putting words in my mouth.";

            node.afterA = [
                "Lover: Then stop acting like it.",
                "Lover: Because from here it really looks like you do."
            ];
            node.afterB = [
                "Lover: I don’t know.",
                "Lover: I’m scared, okay?"
            ];

            node.deltaA = -1;
            node.deltaB = +1;
            return node;
        }

        // ID 009
        if (id == 9) {
            node.opener = ["Lover: So what exactly are we doing then?"];

            node.optA = "We’re seeing each other.";
            node.optB = "We’re not doing ultimatums.";

            node.afterA = [
                "Lover: That’s it?",
                "Lover: After everything you said?"
            ];
            node.afterB = [
                "Lover: It’s not an ultimatum",
                "Lover: I feel like trash too."
            ];

            node.deltaA = -1;
            node.deltaB = +2;
            return node;
        }

        // ID 010
        if (id == 10) {
            node.opener = ["Lover: Do you even miss me when I’m not around?"];

            node.optA = "Sometimes.";
            node.optB = "That’s not the point.";

            node.afterA = [
                "Lover: See?",
                "Lover: That’s all I needed to hear."
            ];
            node.afterB = [
                "Lover: I know, but I can’t help myself."
            ];

            node.deltaA = -1;
            node.deltaB = +1;
            return node;
        }

        // ID 011
        if (id == 11) {
            node.opener = [
                "Lover: I’m repeating myself.",
                "Lover: I’m a mess"
            ];

            node.optA = "Calm down, it’s all okay.";
            node.optB = "I don’t appreciate being treated like I’m your enemy.";

            node.afterA = [
                "Lover: I don’t know if it is, but you’re sweet to comfort me"
            ];
            node.afterB = [
                "Lover: Gee, I’m sorry, you’re the one sending conflicting signals all the time."
            ];

            node.deltaA = +1;
            node.deltaB = -1;
            return node;
        }

        // ID 012
        if (id == 12) {
            node.opener = ["Lover: You said earlier you needed something."];

            node.optA = "Yes.";
            node.optB = "It can wait.";

            node.afterA = [
                "Lover: What is it?"
            ];
            node.afterB = [
                "Lover: No.",
                "Lover: Just tell me."
            ];

            node.deltaA = 0;
            node.deltaB = +1;
            return node;
        }

        // ID 013 (SPECIAL: search for note, relationship gate + code-holder gate)
        if (id == 13) {

            // This represents "[last message]" -> they already asked "What is it?"
            node.opener = ["Lover: So. What is it?"];

            node.optA = "I might have left a really important note at your place. A list of numbers. Can you please look for it?";
            node.optB = "Never mind. I’ll figure it out.";

            var good = (global.LOVER_APPROVAL >= lover_code_threshold);

            if (good) {
                // Add a tiny “search pacing” feeling without needing room transitions
                if (global.lover_has_code) {
                    node.afterA = [
                        "Lover: Of course. Is it important for work?",
                        "Lover: Okay. One sec.",
                        "Lover: ...Is this it?",
                        "Lover: The number is " + string(global.core_code) + "."
                    ];
                } else {
                    node.afterA = [
                        "Lover: Of course. Is it important for work?",
                        "Lover: Okay. One sec.",
                        "Lover: I’ve looked all around.",
                        "Lover: I don’t think it’s here."
                    ];
                }
            } else {
                node.afterA = [
                    "Lover: Yeah, I don’t care much anymore.",
                    "Lover: If it’s around here, you can pick it up when you come over.",
                    "Lover: If you come over."
                ];
            }

            node.afterB = [
                "Lover: ...Right.",
                "Lover: Sure you will."
            ];

            node.deltaA = good ? +1 : -1;
            node.deltaB = -1;

            return node;
        }
    }

    return node;
};

chat_start_node = function(contact, id) {
    var st = chat_state_get(contact);
    st.busy = true;
    st.active_id = id;

    var node = chat_get_node(contact, id);

    st.cur_optA = node.optA;
    st.cur_optB = node.optB;
    st.cur_afterA = node.afterA;
    st.cur_afterB = node.afterB;
    st.cur_deltaA = node.deltaA;
    st.cur_deltaB = node.deltaB;

    st.awaiting_reply = true;

    st.pending = [];
    st.pending_i = 0;
    chat_push_pending(contact, node.opener);
    chat_schedule_next(contact);
};

chat_on_player_reply = function(contact, opt_index) {
    var st = chat_state_get(contact);
    if (!st.busy) return;
    if (!st.awaiting_reply) return;

    var d = (opt_index == 0) ? st.cur_deltaA : st.cur_deltaB;
    chat_rel_add(contact, d);

    st.awaiting_reply = false;
	st.reply_idle = 0;
	
    // prevent re-answering
    chat_options_set(contact, "-", "-");

    st.pending = [];
    st.pending_i = 0;

    var arr = (opt_index == 0) ? st.cur_afterA : st.cur_afterB;
    chat_push_pending(contact, arr);

    chat_schedule_next(contact);
};
