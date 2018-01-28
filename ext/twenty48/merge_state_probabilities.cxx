#include "merge_state_probabilities.hpp"

#include <queue>

#include "binary_reader.hpp"
#include "binary_writer.hpp"
#include "state_value.hpp"

namespace twenty48 {

typedef binary_reader_t<state_value_t> state_value_reader_t;
typedef binary_writer_t<state_value_t> state_value_writer_t;

//
// A wrapper for a state_value_reader_t that remembers the last state that we
// read. We need to remember the state so we can put it into the appropriate
// place in the priority queue.
//
struct head_t {
  head_t(const char *input_pathname) : reader(input_pathname) {
    head.state = 0;
    head.value = 0.0;
  }

  const state_value_t &peek() const {
    return head;
  }

  bool done() const {
    return reader.done();
  }

  void read() {
    head = reader.read();
  }

private:
  state_value_reader_t reader;
  state_value_t head;
};

typedef head_t *head_ptr;

struct head_compare_t {
  bool operator()(const head_ptr &lhs, const head_ptr &rhs) const {
    return lhs->peek().state > rhs->peek().state;
  }
};

typedef std::priority_queue<
  head_ptr, std::vector<head_ptr>, head_compare_t> head_queue_t;

size_t merge_state_probabilities(
  const std::vector<std::string> &input_pathnames,
  const char *output_pathname)
{
  size_t num_states = 0;
  state_value_t state_value;
  state_value.state = 0;
  state_value.value = 0.0;

  state_value_writer_t writer(output_pathname);

  // Open input files.
  // Invariant: the inputs queue contains only heads for which the state is
  // non-zero; a zero state indicates end of file, so this means that we are
  // removing heads that reach end of file.
  head_queue_t inputs;
  for (typename std::vector<std::string>::const_iterator it =
    input_pathnames.begin(); it != input_pathnames.end(); ++it) {
    head_ptr head = new head_t(it->c_str());
    if (head->done()) {
      delete head;
    } else {
      head->read();
      inputs.push(head);
    }
  }

  while (inputs.size() > 0) {
    head_ptr top = inputs.top();
    inputs.pop();

    if (top->peek().state == state_value.state) {
      // If we pop the same state off multiple streams; add the probabilities.
      state_value.value += top->peek().value;
    } else {
      // We're done with this state; write it and read the next.
      if (state_value.state != 0) writer.write(state_value);
      num_states += 1;

      state_value = top->peek();
    }

    if (top->done()) {
      delete top;
    } else {
      top->read();
      inputs.push(top);
    }
  }

  if (state_value.state != 0) writer.write(state_value);

  return num_states;
}

}
