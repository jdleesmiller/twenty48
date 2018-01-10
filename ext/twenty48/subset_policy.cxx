#include "subset_policy.hpp"

namespace twenty48 {

void subset_policy(
  vbyte_reader_t &original_vbyte_reader,
  policy_reader_t &original_policy_reader,
  vbyte_reader_t &subset_vbyte_reader,
  policy_writer_t &subset_policy_writer)
{
  for (;;) {
    uint64_t subset_nybbles = subset_vbyte_reader.read();
    uint64_t original_nybbles;
    direction_t direction;
    if (subset_nybbles == 0) return;

    for (;;) {
      original_nybbles = original_vbyte_reader.read();
      if (original_nybbles == 0) {
        throw std::runtime_error("subset_policy: end of original states");
      }
      direction = original_policy_reader.read();
      if (original_nybbles == subset_nybbles) break;
    }

    subset_policy_writer.write(direction);
  }
  subset_policy_writer.flush();
}

void subset_policy_with_alternate_actions(
  vbyte_reader_t &original_vbyte_reader,
  policy_reader_t &original_policy_reader,
  alternate_action_reader_t &original_alternate_action_reader,
  vbyte_reader_t &subset_vbyte_reader,
  policy_writer_t &subset_policy_writer,
  alternate_action_writer_t &subset_alternate_action_writer)
{
  for (;;) {
    uint64_t subset_nybbles = subset_vbyte_reader.read();
    uint64_t original_nybbles;
    direction_t action;
    bool alternate_actions[4];
    if (subset_nybbles == 0) return;

    for (;;) {
      original_nybbles = original_vbyte_reader.read();
      if (original_nybbles == 0) {
        throw std::runtime_error("subset_policy: end of original states");
      }
      action = original_policy_reader.read();
      original_alternate_action_reader.read(action, alternate_actions);
      if (original_nybbles == subset_nybbles) break;
    }

    subset_policy_writer.write(action);
    subset_alternate_action_writer.write_actions(action, alternate_actions);
  }
  subset_policy_writer.flush();
  subset_alternate_action_writer.flush();
}

}
