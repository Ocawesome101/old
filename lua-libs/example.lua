-- tui example --

local tui = require("lib.tui")

local struct = {
  "Module A",
  "Module B",
  "Module C",
  {
    text = "Misc Modules",
    items = {
      "Module D",
      "Module E",
      "Module F"
    }
  }
}

local ret = tui.menuAdvanced(struct)
