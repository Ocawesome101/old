-- thread protocol --

proto =
  resolve: (proc, query) -> sched.open proc

urld.add "pid", proto
