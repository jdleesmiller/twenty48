%module "twenty48"

%{
#include <sstream>
#include "line.hpp"
#include "state.hpp"
#include "builder.hpp"
%}

%include "stdint.i"
%include "std_array.i"
%include "std_map.i"
%include "std_set.i"
%include "std_vector.i"

/******************************************************************************/
/* Line */
/******************************************************************************/

%include "line.hpp"
%extend twenty48::line_t {
  uint8_t __getitem__(size_t i) const {
    return (*self)[i];
  }

  int __int__() const {
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

  int __int__() const {
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

%template(StateSet2) std::set<twenty48::state_t<2> >;
%template(StateSet3) std::set<twenty48::state_t<3> >;
%template(StateSet4) std::set<twenty48::state_t<4> >;

%template(TransitionMap2) std::map<twenty48::state_t<2>, double>;
%template(TransitionMap3) std::map<twenty48::state_t<3>, double>;
%template(TransitionMap4) std::map<twenty48::state_t<4>, double>;

/******************************************************************************/
/* Builder */
/******************************************************************************/

%include "builder.hpp"

%template(Builder2) twenty48::builder_t<2>;
%template(Builder3) twenty48::builder_t<3>;
%template(Builder4) twenty48::builder_t<4>;
