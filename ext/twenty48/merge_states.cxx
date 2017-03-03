#include "merge_states.hpp"

#include <limits>
#include <queue>

#include "vbyte_reader.hpp"
#include "vbyte_writer.hpp"

namespace twenty48 {

//
// A wrapper for a vbyte_reader_t that just remembers the last value that we
// read. We need to remember the value so we can put it into the appropriate
// place in the priority queue.
//
struct head_t {
  head_t(const char *input_pathname) : reader(input_pathname) { read(); }

  uint64_t peek() const {
    return value;
  }

  void read() {
    value = reader.read();
  }

private:
  vbyte_reader_t reader;
  uint64_t value;
};

typedef head_t *head_ptr;

struct head_compare_t {
  bool operator()(const head_ptr &lhs, const head_ptr &rhs) const {
    return lhs->peek() > rhs->peek();
  }
};

typedef std::priority_queue<
  head_ptr, std::vector<head_ptr>, head_compare_t> head_queue_t;

size_t merge_states(const std::vector<std::string> &input_pathnames,
  const char *output_pathname, size_t index_stride,
  twenty48::vbyte_index_t &vbyte_index)
{
  size_t num_states = 0;
  uint64_t value = 0;

  vbyte_writer_t vbyte_writer(output_pathname);

  // Open input files.
  // Invariant: the inputs queue contains only heads for which the value is
  // non-zero; a zero value indicates end of file, so this means that we are
  // removing heads that reach end of file.
  head_queue_t inputs;
  for (typename std::vector<std::string>::const_iterator it =
    input_pathnames.begin(); it != input_pathnames.end(); ++it) {
    head_ptr head = new head_t(it->c_str());
    if (head->peek() > 0) {
      inputs.push(head);
    } else {
      delete head;
    }
  }

  while (inputs.size() > 0) {
    head_ptr top = inputs.top();
    inputs.pop();

    // We may pop the same state off multiple streams; only write it once.
    if (top->peek() != value) {
      value = top->peek();

      // Write the min state.
      vbyte_writer.write(value);
      num_states += 1;

      // Update index if necessary.
      if (num_states % index_stride == 0) {
        vbyte_index.push_back(vbyte_index_entry_t(
          vbyte_writer.get_bytes_written(),
          vbyte_writer.get_previous()));
      }
    }

    top->read();

    // A zero means that we've reached the end of the input; remove it.
    if (top->peek() == 0) {
      delete top;
    } else {
      inputs.push(top);
    }
  }

  return num_states;
}

}
