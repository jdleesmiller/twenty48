%module "twenty48"

%{
#include <sstream>
#include "line.hpp"
#include "state.hpp"
#include "builder.hpp"
#include "layer_builder.hpp"
#include "state_hash_set.hpp"
%}

%include "stdint.i"
%include "std_array.i"
%include "std_map.i"
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

%template(StateVector2) std::vector<twenty48::state_t<2> >;
%template(StateVector3) std::vector<twenty48::state_t<3> >;
%template(StateVector4) std::vector<twenty48::state_t<4> >;

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

/******************************************************************************/
/* LayerBuilder */
/******************************************************************************/

%include "layer_builder.hpp"

%template(LayerBuilder2) twenty48::layer_builder_t<2>;
%template(LayerBuilder3) twenty48::layer_builder_t<3>;
%template(LayerBuilder4) twenty48::layer_builder_t<4>;

/******************************************************************************/
/* StateHashSet */
/******************************************************************************/

%include "state_hash_set.hpp"

%extend twenty48::state_hash_set_t {
  %exception insert {
    try {
      $action
    }
    catch (const std::length_error& error) {
      SWIG_exception(SWIG_RuntimeError, error.what());
    }
  }
}

%template(StateHashSet2) twenty48::state_hash_set_t<2>;
%template(StateHashSet3) twenty48::state_hash_set_t<3>;
%template(StateHashSet4) twenty48::state_hash_set_t<4>;
