# System/101
*Can I just get a working microkernel already???*

System/101 attempts to be a hybrid kernel.  Components where speed is important, such as filesystems, have been integrated into the kernel.  Everything else is a daemon or a library.

## Daemons and IPC
System/101 uses daemons for most areas of the system where performance is non-critical.  All communication is done through channels or signals - there is no message passing.  Channels are opened through the IPCFS, mounted at `/ipc`.  Daemons should create a virtual filesystem and register it with `ipcfs.register("file", vfstab)`.  The IPCFS is not a daemon as its implementation is greatly simplified when integrated into the kernel.

## Component Interaction
User-level component calls should be made through `componentd`.  If possible, components should not be directly called and the appropriate library used instead.

## User Interface
System/101's primary user interface is a fairly simple text-based GUI, though a terminal interface is available for low-memory systems.

### Structure
The GUI's structure consists of a few fairly basic elements: windows, clickables, text, input, and menus.  Each has unique attributes.

Windows are the base of every GUI - draggable, and closing a window will terminate it.  Clickables may take the form of a button or just clickable text.  Text elements are scrollable and will always be automatically wrapped to the window size.  Input elements read text input from the user.  Menus provide a drop-down menu that can either be single-element-selecton, multiple-element-selection, or buttons with callbacks.  One special element, the background, is created on initialization.  All other elements must be a child of the background.

Every element must have a parent except the window, which may optionally have a parent window.  When the parent is terminated, so are all child elements.  If an element is defined below its parent window, the window will be made scrollable.  Elements may not be defined above or to the side of their parent window.

A terminal emulator is a special type of window.

Menu elements' children may only be other menus or buttons.

Elements will be rendered to a buffer and blitted to the screen.  If this is not possible, elements will be rendered directly to the screen.

### Methods
The following is a list of currently available element methods.

#### Generic
  - `element:newElement(class:number, attributes:table): table`
    - Creates a new element as a child of the element on which the `newElement` method is called.
 
  - `element:children(): table`
    - Returns a table of the element's children.

  - `element:render([yp:number])`
    - Called by the window system when the element should redraw itself.

  - `element:clicked([xp:number[, yp:number]])`
    - Called by the window system when an element is clicked.  If the element's properties are appropriately set, `xp` and `yp` may be specified relative to the element.

##### Attributes
```lua
element.info = {
  x           = 0, -- X and Y are relative to the parent element
  y           = 0,
  type        = #, -- see element.types
  subtype     = #, -- see 'Subtypes below'
  title       = "Window", -- only applies to Window and Menu elements
  foreground  = 0x000000, -- element foreground (text) color
  background  = 0xFFFFFF, -- element background color
}

element.types = {
  WINDOW        = 1,
  WINDOW_TERM   = 2,
  TEXT          = 4,
  CLICKABLE     = 8,
  INPUT         = 16,
  MENU_SINGLE   = 32, -- drop-down, single selection
  MENU_MULTIPLE = 64, -- drop-down, multiple selection, can only have button children
}
```
