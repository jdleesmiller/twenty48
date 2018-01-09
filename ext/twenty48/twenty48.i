%module "twenty48"

%{
#include <sstream>
#include "line.hpp"
#include "state.hpp"
#include "layer_builder.hpp"
#include "layer_q_solver.hpp"
#include "layer_solver.hpp"
#include "merge_states.hpp"
#include "policy_reader.hpp"
#include "policy_writer.hpp"
#include "alternate_action_reader.hpp"
#include "alternate_action_writer.hpp"
#include "solution_writer.hpp"
#include "subset_policy.hpp"
#include "start_states.hpp"
%}

%include "stdint.i"
%include "std_array.i"
%include "std_map.i"
%include "std_string.i"
%include "std_vector.i"

%include "twenty48.hpp"

/******************************************************************************/
/* Line */
/******************************************************************************/

%include "line.hpp"
%extend twenty48::line_t {
  uint8_t __getitem__(size_t i) const {
    return (*self)[i];
  }

  uint64_t __int__() const {
    return self->get_nybbles();
  }

  const char *__str__() {
    std::ostringstream oss(std::ostringstream::out);
    oss << *self;
    return oss.str().c_str();
  }
}

%template(Uint8Array2) std::array<uint8_t, 2>;
%template(Uint8Array3) std::array<uint8_t, 3>;
%template(Uint8Array4) std::array<uint8_t, 4>;

%template(Line2) twenty48::line_t<2>;
%template(Line3) twenty48::line_t<3>;
%template(Line4) twenty48::line_t<4>;

/******************************************************************************/
/* State */
/******************************************************************************/

%include "state.hpp"

%extend twenty48::state_t {
  uint8_t __getitem__(size_t i) const {
    return (*self)[i];
  }

  uint64_t __int__() const {
    return self->get_nybbles();
  }

  const char *__str__() {
    std::ostringstream oss(std::ostringstream::out);
    oss << *self;
    return oss.str().c_str();
  }
}

%template(Uint8Vector) std::vector<uint8_t>;

%template(State2) twenty48::state_t<2>;
%template(State3) twenty48::state_t<3>;
%template(State4) twenty48::state_t<4>;

%template(StateVector2) std::vector<twenty48::state_t<2> >;
%template(StateVector3) std::vector<twenty48::state_t<3> >;
%template(StateVector4) std::vector<twenty48::state_t<4> >;

%template(TransitionMap2) std::map<twenty48::state_t<2>, double>;
%template(TransitionMap3) std::map<twenty48::state_t<3>, double>;
%template(TransitionMap4) std::map<twenty48::state_t<4>, double>;

/******************************************************************************/
/* Valuer */
/******************************************************************************/

%include "valuer.hpp"

%template(Valuer2) twenty48::valuer_t<2>;
%template(Valuer3) twenty48::valuer_t<3>;
%template(Valuer4) twenty48::valuer_t<4>;

/******************************************************************************/
/* LayerBuilder */
/******************************************************************************/

%include "layer_builder.hpp"

%template(LayerBuilder2) twenty48::layer_builder_t<2>;
%template(LayerBuilder3) twenty48::layer_builder_t<3>;
%template(LayerBuilder4) twenty48::layer_builder_t<4>;

%template(StringVector) std::vector<std::string>;

/******************************************************************************/
/* LayerStorage */
/******************************************************************************/

%rename(VByteIndexEntry) twenty48::vbyte_index_entry_t;

%include "vbyte_index.hpp"

%template(VByteIndex) std::vector<twenty48::vbyte_index_entry_t>;

%rename(VByteReader) twenty48::vbyte_reader_t;

%include "vbyte_reader.hpp"

%rename(VByteWriter) twenty48::vbyte_writer_t;

%include "vbyte_writer.hpp"

%include "merge_states.hpp"

/******************************************************************************/
/* LayerSolver */
/******************************************************************************/

%include "layer_solver.hpp"

%template(LayerSolver2) twenty48::layer_solver_t<2>;
%template(LayerSolver3) twenty48::layer_solver_t<3>;
%template(LayerSolver4) twenty48::layer_solver_t<4>;

%include "layer_q_solver.hpp"

%template(LayerQSolver2) twenty48::layer_q_solver_t<2>;
%template(LayerQSolver3) twenty48::layer_q_solver_t<3>;
%template(LayerQSolver4) twenty48::layer_q_solver_t<4>;

/******************************************************************************/
/* Policy Reader/Writer */
/******************************************************************************/

%rename(PolicyReader) twenty48::policy_reader_t;

%extend twenty48::policy_reader_t {
  %exception read {
    try {
      $action
    }
    catch (const std::runtime_error& error) {
      SWIG_exception(SWIG_RuntimeError, error.what());
    }
  }
}

%include "policy_reader.hpp"

%rename(PolicyWriter) twenty48::policy_writer_t;
%include "policy_writer.hpp"

%include "subset_policy.hpp"

/******************************************************************************/
/* Alternate Action Reader/Writer */
/******************************************************************************/

%rename(AlternateActionReader) twenty48::alternate_action_reader_t;
%apply bool *OUTPUT { bool &left, bool &right, bool &up, bool &down }
%extend twenty48::alternate_action_reader_t {
  %exception read {
    try {
      $action
    }
    catch (const std::runtime_error& error) {
      SWIG_exception(SWIG_RuntimeError, error.what());
    }
  }
}
%include "alternate_action_reader.hpp"

%rename(AlternateActionWriter) twenty48::alternate_action_writer_t;

%include "alternate_action_writer.hpp"

/******************************************************************************/
/* Solution Writer */
/******************************************************************************/

%rename(SolutionWriter) twenty48::solution_writer_t;

%include "solution_writer.hpp"

/******************************************************************************/
/* Start States */
/******************************************************************************/

%include "start_states.hpp"

%template(generate_start_states_2) twenty48::generate_start_states<2>;
%template(generate_start_states_3) twenty48::generate_start_states<3>;
%template(generate_start_states_4) twenty48::generate_start_states<4>;
