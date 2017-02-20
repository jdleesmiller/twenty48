#include "merge_states.hpp"

#include <limits>
#include <memory>

#include "vbyte_reader.hpp"
#include "vbyte_writer.hpp"

namespace twenty48 {

size_t merge_states(const std::vector<std::string> &input_pathnames,
  const char *output_pathname)
{
  size_t num_states = 0;
  const size_t n = input_pathnames.size();
  const uint64_t inf_value = std::numeric_limits<uint64_t>::max();
  typedef std::vector<std::unique_ptr<vbyte_reader_t> > reader_vector_t;

  vbyte_writer_t vbyte_writer(output_pathname);

  // Open input files.
  reader_vector_t inputs;
  for (typename std::vector<std::string>::const_iterator it =
    input_pathnames.begin(); it != input_pathnames.end(); ++it) {
    inputs.emplace_back(new vbyte_reader_t(it->c_str()));
  }

  // Read first value from each file.
  std::vector<uint64_t> heads;
  for (typename reader_vector_t::iterator it = inputs.begin();
    it != inputs.end(); ++it) {
    uint64_t nybbles = (*it)->read();
    if (nybbles == 0) {
      heads.push_back(inf_value);
    } else {
      heads.push_back(nybbles);
    }
  }

  std::vector<size_t> min_indexes;
  for (;;) {
    // Find the smallest state among the current heads.
    uint64_t min_value = inf_value;
    for (size_t i = 0; i < n; ++i) {
      if (heads[i] < min_value) {
        min_value = heads[i];
        min_indexes.clear();
        min_indexes.push_back(i);
      } else if (heads[i] == min_value) {
        min_indexes.push_back(i);
      }
    }

    // If all heads are infinite, we're done.
    if (min_value == inf_value) break;

    // Write the min state.
    vbyte_writer.write(min_value);
    num_states += 1;

    // Pop the head states that matched the min state we just wrote.
    for (typename std::vector<size_t>::const_iterator it =
      min_indexes.begin(); it != min_indexes.end(); ++it) {
      uint64_t next_nybbles = inputs[*it]->read();
      if (next_nybbles == 0) {
        heads[*it] = inf_value;
      } else {
        heads[*it] = next_nybbles;
      }
    }

    min_indexes.clear();
  }
  return num_states;
}

}
