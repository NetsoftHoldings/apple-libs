set(Boost_DEFAULT_FIND_COMPONENTS
  chrono date_time exception filesystem iostreams
#  graph prg_exec_monitor python random test_exec_monitor timer wave
  regex serialization system 
  thread unit_test_framework
#  wserialization
)

set(Boost_DEFINITIONS BOOST_AC_USE_PTHREADS BOOST_SP_USE_PTHREADS)