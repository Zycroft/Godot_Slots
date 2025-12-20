#include "slot_machine.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

using namespace godot;

void SlotMachine::_bind_methods() {
    // Slot controls
    ClassDB::bind_method(D_METHOD("spin"), &SlotMachine::spin);
    ClassDB::bind_method(D_METHOD("stop_spin"), &SlotMachine::stop_spin);
    ClassDB::bind_method(D_METHOD("set_bet", "amount"), &SlotMachine::set_bet);
    ClassDB::bind_method(D_METHOD("get_bet"), &SlotMachine::get_bet);

    // Credits
    ClassDB::bind_method(D_METHOD("add_credits", "amount"), &SlotMachine::add_credits);
    ClassDB::bind_method(D_METHOD("remove_credits", "amount"), &SlotMachine::remove_credits);
    ClassDB::bind_method(D_METHOD("get_credits"), &SlotMachine::get_credits);

    // Reels
    ClassDB::bind_method(D_METHOD("get_reel_value", "reel_index"), &SlotMachine::get_reel_value);

    // Win checking
    ClassDB::bind_method(D_METHOD("calculate_winnings"), &SlotMachine::calculate_winnings);
    ClassDB::bind_method(D_METHOD("check_win"), &SlotMachine::check_win);

    // Properties
    ADD_PROPERTY(PropertyInfo(Variant::INT, "bet_amount"), "set_bet", "get_bet");
    ADD_PROPERTY(PropertyInfo(Variant::INT, "credits"), "", "get_credits");

    // Signals
    ADD_SIGNAL(MethodInfo("spin_started"));
    ADD_SIGNAL(MethodInfo("spin_stopped", PropertyInfo(Variant::ARRAY, "results")));
    ADD_SIGNAL(MethodInfo("win", PropertyInfo(Variant::INT, "amount")));
    ADD_SIGNAL(MethodInfo("credits_changed", PropertyInfo(Variant::INT, "new_amount")));
}

SlotMachine::SlotMachine() {
    credits = 100;
    bet_amount = 1;
    is_spinning = false;
    reel_values[0] = 0;
    reel_values[1] = 0;
    reel_values[2] = 0;
}

SlotMachine::~SlotMachine() {
}

void SlotMachine::_ready() {
    UtilityFunctions::print("SlotMachine initialized with ", credits, " credits");
}

void SlotMachine::_process(double delta) {
    // Handle spinning animation logic here
}

void SlotMachine::spin() {
    if (is_spinning || credits < bet_amount) {
        return;
    }

    is_spinning = true;
    remove_credits(bet_amount);
    emit_signal("spin_started");

    // Generate random results for each reel (0-5 for 6 symbols)
    for (int i = 0; i < 3; i++) {
        reel_values[i] = UtilityFunctions::randi() % 6;
    }
}

void SlotMachine::stop_spin() {
    if (!is_spinning) {
        return;
    }

    is_spinning = false;

    Array results;
    for (int i = 0; i < 3; i++) {
        results.append(reel_values[i]);
    }
    emit_signal("spin_stopped", results);

    if (check_win()) {
        int winnings = calculate_winnings();
        add_credits(winnings);
        emit_signal("win", winnings);
    }
}

void SlotMachine::set_bet(int amount) {
    if (amount > 0 && amount <= credits) {
        bet_amount = amount;
    }
}

int SlotMachine::get_bet() const {
    return bet_amount;
}

void SlotMachine::add_credits(int amount) {
    credits += amount;
    emit_signal("credits_changed", credits);
}

void SlotMachine::remove_credits(int amount) {
    credits -= amount;
    if (credits < 0) {
        credits = 0;
    }
    emit_signal("credits_changed", credits);
}

int SlotMachine::get_credits() const {
    return credits;
}

int SlotMachine::get_reel_value(int reel_index) const {
    if (reel_index >= 0 && reel_index < 3) {
        return reel_values[reel_index];
    }
    return -1;
}

int SlotMachine::calculate_winnings() {
    // Three of a kind
    if (reel_values[0] == reel_values[1] && reel_values[1] == reel_values[2]) {
        // Higher value symbols pay more
        return bet_amount * (reel_values[0] + 1) * 10;
    }

    // Two of a kind
    if (reel_values[0] == reel_values[1] ||
        reel_values[1] == reel_values[2] ||
        reel_values[0] == reel_values[2]) {
        return bet_amount * 2;
    }

    return 0;
}

bool SlotMachine::check_win() {
    return calculate_winnings() > 0;
}
