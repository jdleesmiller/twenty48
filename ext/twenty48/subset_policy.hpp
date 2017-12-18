#ifndef TWENTY48_SUBSET_POLICY_HPP

#include "twenty48.hpp"
#include "policy_reader.hpp"
#include "policy_writer.hpp"
#include "vbyte_reader.hpp"

namespace twenty48 {

/**
 * Write out a policy for only the states that are present in another
 * list of states (subset_vbyte_reader).
 */
void subset_policy(
  vbyte_reader_t &original_vbyte_reader,
  policy_reader_t &original_policy_reader,
  vbyte_reader_t &subset_vbyte_reader,
  policy_writer_t &subset_policy_writer);

}

#define TWENTY48_SUBSET_POLICY_HPP
#endif
