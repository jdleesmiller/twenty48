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

}
