#ifndef TWENTY48_SUBSET_POLICY_HPP

#include "twenty48.hpp"
#include "alternate_action_reader.hpp"
#include "alternate_action_writer.hpp"
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

void subset_policy_with_alternate_actions(
  twenty48::vbyte_reader_t &original_vbyte_reader,
  twenty48::policy_reader_t &original_policy_reader,
  twenty48::alternate_action_reader_t &original_alternate_action_reader,
  twenty48::vbyte_reader_t &subset_vbyte_reader,
  twenty48::policy_writer_t &subset_policy_writer,
  twenty48::alternate_action_writer_t &subset_alternate_action_writer
);

}

#define TWENTY48_SUBSET_POLICY_HPP
#endif
