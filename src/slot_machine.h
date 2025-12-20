#ifndef SLOT_MACHINE_H
#define SLOT_MACHINE_H

#include <godot_cpp/classes/node2d.hpp>
#include <godot_cpp/core/class_db.hpp>

namespace godot {

class SlotMachine : public Node2D {
    GDCLASS(SlotMachine, Node2D)

private:
    int credits;
    int bet_amount;
    bool is_spinning;

    // Reel values (0-indexed symbol positions)
    int reel_values[3];

protected:
    static void _bind_methods();

public:
    SlotMachine();
    ~SlotMachine();

    void _ready() override;
    void _process(double delta) override;

    // Slot machine controls
    void spin();
    void stop_spin();
    void set_bet(int amount);
    int get_bet() const;

    // Credits management
    void add_credits(int amount);
    void remove_credits(int amount);
    int get_credits() const;

    // Reel access
    int get_reel_value(int reel_index) const;

    // Win checking
    int calculate_winnings();
    bool check_win();
};

} // namespace godot

#endif // SLOT_MACHINE_H
