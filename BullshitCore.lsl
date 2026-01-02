// Bullshit (Cheat) Card Game - Core Engine V2.1 (Visual Polish)
// Created for Second Life pure LSL integration

// --- Global Variables ---
list DECK = ["AC", "2C", "3C", "4C", "5C", "6C", "7C", "8C", "9C", "10C", "JC", "QC", "KC",
             "AD", "2D", "3D", "4D", "5D", "6D", "7D", "8D", "9D", "10D", "JD", "QD", "KD",
             "AH", "2H", "3H", "4H", "5H", "6H", "7H", "8H", "9H", "10H", "JH", "QH", "KH",
             "AS", "2S", "3S", "4S", "5S", "6S", "7S", "8S", "9S", "10S", "JS", "QS", "KS"];

list RANKS = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"];

// Player management
list PLAYERS = []; 
list HANDS = [];   
integer currentPlayerIdx = -1;

// Game State
integer GAME_STATE = 0; 
integer REQUIRED_RANK_IDX = 0; 
list PILE = []; 
list LAST_PLAYED_CARDS = []; 
key LAST_PLAYER = NULL_KEY;
key CHALLENGER = NULL_KEY;
integer DECLARED_COUNT = 0;

// Communication
integer DIALOG_CHAN = -99988;
integer DIALOG_HANDLE;

// Buffer for selection
list SELECTED_CARD_INDICES = [];

// --- Visual/Audio Assets ---
string SOUND_PLAY = "51ad36e1-95ee-6663-8a3d-4c31169622d9";
string SOUND_WIN = "3d1d5289-49cd-2c7c-40ad-f3d3a6f4a86b";
string SOUND_BUZZ = "f4a06241-e298-958a-36fb-863ac1b7397e";

// --- Helper Functions ---

DoParticles(vector color) {
    llParticleSystem([
        PSYS_PART_FLAGS, PSYS_PART_INTERP_COLOR_MASK | PSYS_PART_INTERP_SCALE_MASK | PSYS_PART_EMISSIVE_MASK,
        PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_EXPLODE,
        PSYS_PART_START_COLOR, color,
        PSYS_PART_END_COLOR, color,
        PSYS_PART_START_SCALE, <0.1, 0.1, 0.0>,
        PSYS_PART_END_SCALE, <0.5, 0.5, 0.0>,
        PSYS_SRC_BURST_RATE, 0.05,
        PSYS_SRC_BURST_PART_COUNT, 20,
        PSYS_PART_MAX_AGE, 1.5,
        PSYS_SRC_MAX_AGE, 0.5
    ]);
}

list Shuffle(list input) {
    list output = [];
    while (llGetListLength(input) > 0) {
        integer rand = (integer)llFrand(llGetListLength(input));
        output += llList2List(input, rand, rand);
        input = llDeleteSubList(input, rand, rand);
    }
    return output;
}

UpdateHovertext() {
    string text = "--- [BULLSHIT GAME] ---\n";
    if (GAME_STATE == 0) {
        text += "Waiting for players... (" + (string)llGetListLength(PLAYERS) + "/8)\nClick to Join (Sit)";
    } else {
        key curAv = llList2Key(PLAYERS, currentPlayerIdx);
        text += "Turn: " + llKey2Name(curAv) + "\n";
        text += "Must play: " + llList2String(RANKS, REQUIRED_RANK_IDX) + "s\n";
        text += "Cards in Pile: " + (string)llGetListLength(PILE) + "\n";
        if (LAST_PLAYER != NULL_KEY) {
            text += "Last Move: " + (string)DECLARED_COUNT + " card(s) by " + llKey2Name(LAST_PLAYER);
        }
    }
    llSetText(text, <1.0, 1.0, 1.0>, 1.0);
}

ShowSelectionMenu(key id) {
    integer pIdx = llListFindList(PLAYERS, [id]);
    list hand = llParseString2List(llList2String(HANDS, pIdx), [","], []);
    
    string msg = "Select up to 4 cards to play as " + llList2String(RANKS, REQUIRED_RANK_IDX) + "s.\n";
    msg += "Selected: " + (string)llGetListLength(SELECTED_CARD_INDICES) + " card(s)\n\nHand:";
    
    list buttons = ["BACK", "PLAY", "RESET"];
    integer i;
    for (i = 0; i < llGetListLength(hand) && i < 9; i++) {
        buttons += [(string)(i + 1)];
        msg += "\n" + (string)(i + 1) + ": " + llList2String(hand, i);
    }
    
    llDialog(id, msg, buttons, DIALOG_CHAN);
}

ShowActionMenu(key id) {
    string msg = "It's NOT your turn.\n\nCards in pile: " + (string)llGetListLength(PILE);
    list buttons = ["Refresh", "Rules"];
    if (LAST_PLAYER != NULL_KEY && id != LAST_PLAYER) {
        buttons += ["BULLSHIT!"];
    }
    llDialog(id, msg, buttons, DIALOG_CHAN);
}

GivePile(key id) {
    integer pIdx = llListFindList(PLAYERS, [id]);
    list hand = llParseString2List(llList2String(HANDS, pIdx), [","], []);
    hand += PILE;
    HANDS = llListReplaceList(HANDS, [llDumpList2String(hand, ",")], pIdx, pIdx);
    PILE = [];
}

ResetGame() {
    PLAYERS = [];
    HANDS = [];
    PILE = [];
    LAST_PLAYER = NULL_KEY;
    GAME_STATE = 0;
    UpdateHovertext();
    llParticleSystem([]);
}

default {
    state_entry() {
        llSitTarget(<0,0,0.1>, ZERO_ROTATION);
        DIALOG_HANDLE = llListen(DIALOG_CHAN, "", NULL_KEY, "");
        ResetGame();
    }

    changed(integer change) {
        if (change & CHANGED_LINK) {
            integer i;
            integer numPrims = llGetNumberOfPrims();
            list currentAvatars = [];
            
            // Find all avatars sitting on the linkset
            for (i = 1; i <= numPrims; i++) {
                key av = llGetLinkKey(i);
                if (llGetAgentSize(av) != ZERO_VECTOR) {
                    currentAvatars += [av];
                }
            }
            
            // Sync PLAYERS list
            integer numAvs = llGetListLength(currentAvatars);
            for (i = 0; i < numAvs; i++) {
                key sitAv = llList2Key(currentAvatars, i);
                if (llListFindList(PLAYERS, [sitAv]) == -1) {
                    if (llGetListLength(PLAYERS) < 8) {
                        PLAYERS += [sitAv];
                        llRegionSayTo(sitAv, 0, "Welcome to Bullshit! Click the table to start.");
                        UpdateHovertext();
                    } else {
                        llUnSit(sitAv);
                    }
                }
            }
            
            // Remove players who stood up
            for (i = llGetListLength(PLAYERS) - 1; i >= 0; i--) {
                key p = llList2Key(PLAYERS, i);
                if (llListFindList(currentAvatars, [p]) == -1) {
                    PLAYERS = llDeleteSubList(PLAYERS, i, i);
                    if (GAME_STATE != 0) {
                        llShout(0, "A player left! Game resetting...");
                        ResetGame();
                    }
                    UpdateHovertext();
                }
            }
        }
    }

    touch_start(integer num) {
        key id = llDetectedKey(0);
        if (GAME_STATE == 0) {
            if (llGetListLength(PLAYERS) >= 2) state start_game;
            else llRegionSayTo(id, 0, "Need at least 2 players.");
        } else {
            if (id == llList2Key(PLAYERS, currentPlayerIdx)) ShowSelectionMenu(id);
            else ShowActionMenu(id);
        }
    }

    listen(integer chan, string name, key id, string msg) {
        if (msg == "BULLSHIT!") {
            CHALLENGER = id;
            state challenge;
        }
    }
}

state start_game {
    state_entry() {
        llShout(0, "Shuffling and dealing...");
        list shuffled = Shuffle(DECK);
        integer n = llGetListLength(PLAYERS);
        integer per = 52 / n;
        integer i;
        for (i = 0; i < n; i++) {
            list h = llList2List(shuffled, i*per, (i+1)*per - 1);
            HANDS += [llDumpList2String(h, ",")];
        }
        currentPlayerIdx = 0;
        REQUIRED_RANK_IDX = 0;
        GAME_STATE = 1;
        state play;
    }
}

state play {
    state_entry() {
        SELECTED_CARD_INDICES = [];
        UpdateHovertext();
    }

    listen(integer chan, string name, key id, string msg) {
        if (chan != DIALOG_CHAN) return;
        
        if (msg == "BULLSHIT!") {
            CHALLENGER = id;
            state challenge;
            return;
        }

        integer pIdx = llListFindList(PLAYERS, [id]);
        if (id == llList2Key(PLAYERS, currentPlayerIdx)) {
            if (msg == "PLAY") {
                if (llGetListLength(SELECTED_CARD_INDICES) == 0) {
                    llRegionSayTo(id, 0, "Select cards first!");
                    ShowSelectionMenu(id);
                    return;
                }
                
                list hand = llParseString2List(llList2String(HANDS, pIdx), [","], []);
                LAST_PLAYED_CARDS = [];
                DECLARED_COUNT = llGetListLength(SELECTED_CARD_INDICES);
                
                SELECTED_CARD_INDICES = llListSort(SELECTED_CARD_INDICES, 1, FALSE);
                integer i;
                for (i = 0; i < DECLARED_COUNT; i++) {
                    integer idx = llList2Integer(SELECTED_CARD_INDICES, i);
                    LAST_PLAYED_CARDS += [llList2String(hand, idx)];
                    hand = llDeleteSubList(hand, idx, idx);
                }
                
                PILE += LAST_PLAYED_CARDS;
                HANDS = llListReplaceList(HANDS, [llDumpList2String(hand, ",")], pIdx, pIdx);
                LAST_PLAYER = id;
                
                llPlaySound(SOUND_PLAY, 1.0);
                llShout(0, name + " played " + (string)DECLARED_COUNT + " card(s) as " + llList2String(RANKS, REQUIRED_RANK_IDX) + "s.");
                
                if (llGetListLength(hand) == 0) {
                    llShout(0, name + " is OUT OF CARDS! Challenge now or lose!");
                }
                
                currentPlayerIdx = (currentPlayerIdx + 1) % llGetListLength(PLAYERS);
                REQUIRED_RANK_IDX = (REQUIRED_RANK_IDX + 1) % 13;
                state_entry();
            } else if (msg == "RESET") {
                SELECTED_CARD_INDICES = [];
                ShowSelectionMenu(id);
            } else if ((integer)msg > 0) {
                integer idx = (integer)msg - 1;
                if (llListFindList(SELECTED_CARD_INDICES, [idx]) == -1) {
                    if (llGetListLength(SELECTED_CARD_INDICES) < 4) {
                        SELECTED_CARD_INDICES += [idx];
                        llPlaySound(SOUND_PLAY, 0.5);
                    }
                }
                ShowSelectionMenu(id);
            }
        }
    }

    touch_start(integer num) {
        key id = llDetectedKey(0);
        if (id == llList2Key(PLAYERS, currentPlayerIdx)) ShowSelectionMenu(id);
        else ShowActionMenu(id);
    }
}

state challenge {
    state_entry() {
        llShout(0, llKey2Name(CHALLENGER) + " calls BULLSHIT on " + llKey2Name(LAST_PLAYER) + "!");
        llSleep(2.0);
        
        integer prevRankIdx = (REQUIRED_RANK_IDX + 12) % 13;
        string reqRank = llList2String(RANKS, prevRankIdx);
        
        llShout(0, "Revealing cards: " + llDumpList2String(LAST_PLAYED_CARDS, ", "));
        
        integer isLying = FALSE;
        integer i;
        for (i = 0; i < llGetListLength(LAST_PLAYED_CARDS); i++) {
            string c = llList2String(LAST_PLAYED_CARDS, i);
            if (llGetSubString(c, 0, llStringLength(reqRank)-1) != reqRank) isLying = TRUE;
        }
        
        if (isLying) {
            llShout(0, "BUSTED! " + llKey2Name(LAST_PLAYER) + " takes the pile!");
            DoParticles(<1.0, 0.0, 0.0>); // RED
            llPlaySound(SOUND_BUZZ, 1.0);
            GivePile(LAST_PLAYER);
            currentPlayerIdx = llListFindList(PLAYERS, [LAST_PLAYER]);
        } else {
            llShout(0, "TRUTH! " + llKey2Name(CHALLENGER) + " takes the pile!");
            DoParticles(<0.0, 1.0, 0.0>); // GREEN
            GivePile(CHALLENGER);
            currentPlayerIdx = llListFindList(PLAYERS, [CHALLENGER]);
        }
        
        integer lpIdx = llListFindList(PLAYERS, [LAST_PLAYER]);
        if (llList2String(HANDS, lpIdx) == "" && !isLying) {
            llShout(0, "CONGRATULATIONS! " + llKey2Name(LAST_PLAYER) + " WINS THE GAME!");
            llPlaySound(SOUND_WIN, 1.0);
            DoParticles(<1.0, 0.8, 0.0>);
            llSleep(5.0);
            ResetGame();
            state default;
        }

        llSleep(3.0);
        llParticleSystem([]);
        state play;
    }
}
