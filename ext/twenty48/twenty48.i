%module "twenty48"

%{
#include <sstream>
#include "line.hpp"
#include "state.hpp"
%}

%include "stdint.i"
%include "std_array.i"
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
