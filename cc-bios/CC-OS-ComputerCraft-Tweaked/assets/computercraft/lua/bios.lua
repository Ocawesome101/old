-- Modified version of CC:Tweaked's bios.lua; an attempt to bring in more of an OpenComputers-y open-ended feeling with the convenience of CC:Tweaked.

-- Load in expect from the module path.
--
-- Ideally we'd use require, but that is part of the shell, and so is not
-- available to the BIOS or any APIs. All APIs load this using dofile, but that
-- has not been defined at this point.
local expect

do
    local h = fs.open("rom/modules/main/cc/expect.lua", "r")
    local f, err = loadstring(h.readAll(), "@expect.lua")
    h.close()

    if not f then error(err) end
    expect = f().expect
end

if _VERSION == "Lua 5.1" then
    -- If we're on Lua 5.1, install parts of the Lua 5.2/5.3 API so that programs can be written against it
    local type = type
    local nativeload = load
    local nativeloadstring = loadstring
    local nativesetfenv = setfenv

    --- Historically load/loadstring would handle the chunk name as if it has
    -- been prefixed with "=". We emulate that behaviour here.
    local function prefix(chunkname)
        if type(chunkname) ~= "string" then return chunkname end
        local head = chunkname:sub(1, 1)
        if head == "=" or head == "@" then
            return chunkname
        else
            return "=" .. chunkname
        end
    end

    function load( x, name, mode, env )
        expect(1, x, "function", "string")
        expect(2, name, "string", "nil")
        expect(3, mode, "string", "nil")
        expect(4, env, "table", "nil")

        local ok, p1, p2 = pcall( function()
            if type(x) == "string" then
                local result, err = nativeloadstring( x, name )
                if result then
                    if env then
                        env._ENV = env
                        nativesetfenv( result, env )
                    end
                    return result
                else
                    return nil, err
                end
            else
                local result, err = nativeload( x, name )
                if result then
                    if env then
                        env._ENV = env
                        nativesetfenv( result, env )
                    end
                    return result
                else
                    return nil, err
                end
            end
        end )
        if ok then
            return p1, p2
        else
            error( p1, 2 )
        end
    end
    table.unpack = unpack
    table.pack = function( ... ) return { n = select( "#", ... ), ... } end

    if _CC_DISABLE_LUA51_FEATURES then
        -- Remove the Lua 5.1 features that will be removed when we update to Lua 5.2, for compatibility testing.
        -- See "disable_lua51_functions" in ComputerCraft.cfg
        setfenv = nil
        getfenv = nil
        loadstring = nil
        unpack = nil
        math.log10 = nil
        table.maxn = nil
    else
        loadstring = function(string, chunkname) return nativeloadstring(string, prefix( chunkname )) end

        -- Inject a stub for the old bit library
        if bit then
            local nativebit = bit
            bit32 = {}
            bit32.arshift = nativebit.brshift
            bit32.band = nativebit.band
            bit32.bnot = nativebit.bnot
            bit32.bor = nativebit.bor
            bit32.btest = function( a, b ) return nativebit.band(a,b) ~= 0 end
            bit32.bxor = nativebit.bxor
            bit32.lshift = nativebit.blshift
            bit32.rshift = nativebit.blogic_rshift
        else
            _G.bit = {
                bnot = bit32.bnot,
                band = bit32.band,
                bor = bit32.bor,
                bxor = bit32.bxor,
                brshift = bit32.arshift,
                blshift = bit32.lshift,
                blogic_rshift = bit32.rshift
            }
        end
    end
end

if _VERSION == "Lua 5.3" and not bit32 then
    -- If we're on Lua 5.3, install the bit32 api from Lua 5.2
    -- (Loaded from a string so this file will still parse on <5.3 lua)
    load( [[
        bit32 = {}

        function bit32.arshift( n, bits )
            if type(n) ~= "number" or type(bits) ~= "number" then
                error( "Expected number, number", 2 )
            end
            return n >> bits
        end

        function bit32.band( m, n )
            if type(m) ~= "number" or type(n) ~= "number" then
                error( "Expected number, number", 2 )
            end
            return m & n
        end

        function bit32.bnot( n )
            if type(n) ~= "number" then
                error( "Expected number", 2 )
            end
            return ~n
        end

        function bit32.bor( m, n )
            if type(m) ~= "number" or type(n) ~= "number" then
                error( "Expected number, number", 2 )
            end
            return m | n
        end

        function bit32.btest( m, n )
            if type(m) ~= "number" or type(n) ~= "number" then
                error( "Expected number, number", 2 )
            end
            return (m & n) ~= 0
        end

        function bit32.bxor( m, n )
            if type(m) ~= "number" or type(n) ~= "number" then
                error( "Expected number, number", 2 )
            end
            return m ~ n
        end

        function bit32.lshift( n, bits )
            if type(n) ~= "number" or type(bits) ~= "number" then
                error( "Expected number, number", 2 )
            end
            return n << bits
        end

        function bit32.rshift( n, bits )
            if type(n) ~= "number" or type(bits) ~= "number" then
                error( "Expected number, number", 2 )
            end
            return n >> bits
        end
    ]] )()
end

-- Colors
local colors = {
white = 1,
orange = 2,
magenta = 4,
lightBlue = 8,
yellow = 16,
lime = 32,
pink = 64,
gray = 128,
lightGray = 256,
cyan = 512,
purple = 1024,
blue = 2048,
brown = 4096,
green = 8192,
red = 16384,
black = 32768,

combine = function( ... )
    local r = 0
    for i = 1, select('#', ...) do
        local c = select(i, ...)
        expect(i, c, "number")
        r = bit32.bor(r,c)
    end
    return r
end,

subtract = function( colors, ... )
    expect(1, colors, "number")
    local r = colors
    for i = 1, select('#', ...) do
        local c = select(i, ...)
        expect(i + 1, c, "number")
        r = bit32.band(r, bit32.bnot(c))
    end
    return r
end,

test = function( colors, color )
    expect(1, colors, "number")
    expect(2, color, "number")
    return bit32.band(colors, color) == color
end,

packRGB = function( r, g, b )
    expect(1, r, "number")
    expect(2, g, "number")
    expect(3, b, "number")
    return
        bit32.band( r * 255, 0xFF ) * 2^16 +
        bit32.band( g * 255, 0xFF ) * 2^8 +
        bit32.band( b * 255, 0xFF )
end,

unpackRGB = function( rgb )
    expect(1, rgb, "number")
    return
        bit32.band( bit32.rshift( rgb, 16 ), 0xFF ) / 255,
        bit32.band( bit32.rshift( rgb, 8 ), 0xFF ) / 255,
        bit32.band( rgb, 0xFF ) / 255
end,

rgb8 = function( r, g, b )
    if g == nil and b == nil then
        return unpackRGB( r )
    else
        return packRGB( r, g, b )
    end
end
}

-- Install lua parts of the os api
function os.version()
    return "CC-BIOS 0.8.1"
end

function os.pullEventRaw( sFilter )
    return coroutine.yield( sFilter )
end

function os.pullEvent( sFilter )
    local eventData = table.pack( os.pullEventRaw( sFilter ) )
    if eventData[1] == "terminate" then
        error( "Terminated", 0 )
    end
    return table.unpack( eventData, 1, eventData.n )
end

-- Install globals
function sleep( nTime )
    expect(1, nTime, "number", "nil")
    local timer = os.startTimer( nTime or 0 )
    repeat
        local sEvent, param = os.pullEvent( "timer" )
    until param == timer
end

function write( sText )
    expect(1, sText, "string", "number")

    local w,h = term.getSize()
    local x,y = term.getCursorPos()

    local nLinesPrinted = 0
    local function newLine()
        if y + 1 <= h then
            term.setCursorPos(1, y + 1)
        else
            term.setCursorPos(1, h)
            term.scroll(1)
        end
        x, y = term.getCursorPos()
        nLinesPrinted = nLinesPrinted + 1
    end

    -- Print the line with proper word wrapping
    while string.len(sText) > 0 do
        local whitespace = string.match( sText, "^[ \t]+" )
        if whitespace then
            -- Print whitespace
            term.write( whitespace )
            x,y = term.getCursorPos()
            sText = string.sub( sText, string.len(whitespace) + 1 )
        end

        local newline = string.match( sText, "^\n" )
        if newline then
            -- Print newlines
            newLine()
            sText = string.sub( sText, 2 )
        end

        local text = string.match( sText, "^[^ \t\n]+" )
        if text then
            sText = string.sub( sText, string.len(text) + 1 )
            if string.len(text) > w then
                -- Print a multiline word
                while string.len( text ) > 0 do
                    if x > w then
                        newLine()
                    end
                    term.write( text )
                    text = string.sub( text, (w-x) + 2 )
                    x,y = term.getCursorPos()
                end
            else
                -- Print a word normally
                if x + string.len(text) - 1 > w then
                    newLine()
                end
                term.write( text )
                x,y = term.getCursorPos()
            end
        end
    end

    return nLinesPrinted
end

function print( ... )
    local nLinesPrinted = 0
    local nLimit = select("#", ... )
    for n = 1, nLimit do
        local s = tostring( select( n, ... ) )
        if n < nLimit then
            s = s .. "\t"
        end
        nLinesPrinted = nLinesPrinted + write( s )
    end
    nLinesPrinted = nLinesPrinted + write( "\n" )
    return nLinesPrinted
end

function printError( ... )
    local oldColour
    if term.isColour() then
        oldColour = term.getTextColour()
        term.setTextColour( colors.red )
    end
    print( ... )
    if term.isColour() then
        term.setTextColour( oldColour )
    end
end

function loadfile( filename, mode, env )
    -- Support the previous `loadfile(filename, env)` form instead.
    if type(mode) == "table" and env == nil then
        mode, env = nil, mode
    end

    expect(1, filename, "string")
    expect(2, mode, "string", "nil")
    expect(3, env, "table", "nil")

    local file = fs.open( filename, "r" )
    if not file then return nil, "File not found" end

    local func, err = load( file.readAll(), "@" .. fs.getName( filename ), mode, env )
    file.close()
    return func, err
end

function dofile( _sFile )
    expect(1, _sFile, "string")

    local fnFile, e = loadfile( _sFile, nil, _G )
    if fnFile then
        return fnFile()
    else
        error( e, 2 )
    end
end

keys = dofile("/rom/apis/keys.lua")

function read( _sReplaceChar, _tHistory, _fnComplete, _sDefault )
    expect(1, _sReplaceChar, "string", "nil")
    expect(2, _tHistory, "table", "nil")
    expect(3, _fnComplete, "function", "nil")
    expect(4, _sDefault, "string", "nil")

    term.setCursorBlink( true )

    local sLine
    if type( _sDefault ) == "string" then
        sLine = _sDefault
    else
        sLine = ""
    end
    local nHistoryPos
    local nPos, nScroll = #sLine, 0
    if _sReplaceChar then
        _sReplaceChar = string.sub( _sReplaceChar, 1, 1 )
    end

    local tCompletions
    local nCompletion
    local function recomplete()
        if _fnComplete and nPos == string.len(sLine) then
            tCompletions = _fnComplete( sLine )
            if tCompletions and #tCompletions > 0 then
                nCompletion = 1
            else
                nCompletion = nil
            end
        else
            tCompletions = nil
            nCompletion = nil
        end
    end

    local function uncomplete()
        tCompletions = nil
        nCompletion = nil
    end

    local w = term.getSize()
    local sx = term.getCursorPos()

    local function redraw( _bClear )
        local cursor_pos = nPos - nScroll
        if sx + cursor_pos >= w then
            -- We've moved beyond the RHS, ensure we're on the edge.
            nScroll = sx + nPos - w
        elseif cursor_pos < 0 then
            -- We've moved beyond the LHS, ensure we're on the edge.
            nScroll = nPos
        end

        local _, cy = term.getCursorPos()
        term.setCursorPos( sx, cy )
        local sReplace = (_bClear and " ") or _sReplaceChar
        if sReplace then
            term.write( string.rep( sReplace, math.max( #sLine - nScroll, 0 ) ) )
        else
            term.write( string.sub( sLine, nScroll + 1 ) )
        end

        if nCompletion then
            local sCompletion = tCompletions[ nCompletion ]
            local oldText, oldBg
            if not _bClear then
                oldText = term.getTextColor()
                oldBg = term.getBackgroundColor()
                term.setTextColor( colors.white )
                term.setBackgroundColor( colors.gray )
            end
            if sReplace then
                term.write( string.rep( sReplace, #sCompletion ) )
            else
                term.write( sCompletion )
            end
            if not _bClear then
                term.setTextColor( oldText )
                term.setBackgroundColor( oldBg )
            end
        end

        term.setCursorPos( sx + nPos - nScroll, cy )
    end

    local function clear()
        redraw( true )
    end

    recomplete()
    redraw()

    local function acceptCompletion()
        if nCompletion then
            -- Clear
            clear()

            -- Find the common prefix of all the other suggestions which start with the same letter as the current one
            local sCompletion = tCompletions[ nCompletion ]
            sLine = sLine .. sCompletion
            nPos = #sLine

            -- Redraw
            recomplete()
            redraw()
        end
    end
    while true do
        local sEvent, param, param1, param2 = os.pullEvent()
        if sEvent == "char" then
            -- Typed key
            clear()
            sLine = string.sub( sLine, 1, nPos ) .. param .. string.sub( sLine, nPos + 1 )
            nPos = nPos + 1
            recomplete()
            redraw()

        elseif sEvent == "paste" then
            -- Pasted text
            clear()
            sLine = string.sub( sLine, 1, nPos ) .. param .. string.sub( sLine, nPos + 1 )
            nPos = nPos + #param
            recomplete()
            redraw()

        elseif sEvent == "key" then
            if param == keys.enter then
                -- Enter
                if nCompletion then
                    clear()
                    uncomplete()
                    redraw()
                end
                break

            elseif param == keys.left then
                -- Left
                if nPos > 0 then
                    clear()
                    nPos = nPos - 1
                    recomplete()
                    redraw()
                end

            elseif param == keys.right then
                -- Right
                if nPos < #sLine then
                    -- Move right
                    clear()
                    nPos = nPos + 1
                    recomplete()
                    redraw()
                else
                    -- Accept autocomplete
                    acceptCompletion()
                end

            elseif param == keys.up or param == keys.down then
                -- Up or down
                if nCompletion then
                    -- Cycle completions
                    clear()
                    if param == keys.up then
                        nCompletion = nCompletion - 1
                        if nCompletion < 1 then
                            nCompletion = #tCompletions
                        end
                    elseif param == keys.down then
                        nCompletion = nCompletion + 1
                        if nCompletion > #tCompletions then
                            nCompletion = 1
                        end
                    end
                    redraw()

                elseif _tHistory then
                    -- Cycle history
                    clear()
                    if param == keys.up then
                        -- Up
                        if nHistoryPos == nil then
                            if #_tHistory > 0 then
                                nHistoryPos = #_tHistory
                            end
                        elseif nHistoryPos > 1 then
                            nHistoryPos = nHistoryPos - 1
                        end
                    else
                        -- Down
                        if nHistoryPos == #_tHistory then
                            nHistoryPos = nil
                        elseif nHistoryPos ~= nil then
                            nHistoryPos = nHistoryPos + 1
                        end
                    end
                    if nHistoryPos then
                        sLine = _tHistory[nHistoryPos]
                        nPos, nScroll = #sLine, 0
                    else
                        sLine = ""
                        nPos, nScroll = 0, 0
                    end
                    uncomplete()
                    redraw()

                end

            elseif param == keys.backspace then
                -- Backspace
                if nPos > 0 then
                    clear()
                    sLine = string.sub( sLine, 1, nPos - 1 ) .. string.sub( sLine, nPos + 1 )
                    nPos = nPos - 1
                    if nScroll > 0 then nScroll = nScroll - 1 end
                    recomplete()
                    redraw()
                end

            elseif param == keys.home then
                -- Home
                if nPos > 0 then
                    clear()
                    nPos = 0
                    recomplete()
                    redraw()
                end

            elseif param == keys.delete then
                -- Delete
                if nPos < #sLine then
                    clear()
                    sLine = string.sub( sLine, 1, nPos ) .. string.sub( sLine, nPos + 2 )
                    recomplete()
                    redraw()
                end

            elseif param == keys["end"] then
                -- End
                if nPos < #sLine then
                    clear()
                    nPos = #sLine
                    recomplete()
                    redraw()
                end

            elseif param == keys.tab then
                -- Tab (accept autocomplete)
                acceptCompletion()

            end

        elseif sEvent == "mouse_click" or sEvent == "mouse_drag" and param == 1 then
            local _, cy = term.getCursorPos()
            if param1 >= sx and param1 <= w and param2 == cy then
                -- Ensure we don't scroll beyond the current line
                nPos = math.min(math.max(nScroll + param1 - sx, 0), #sLine)
                redraw()
            end

        elseif sEvent == "term_resize" then
            -- Terminal resized
            w = term.getSize()
            redraw()

        end
    end

    local cx, cy = term.getCursorPos()
    term.setCursorBlink( false )
    term.setCursorPos( w + 1, cy )
    print()

    return sLine
end

-- Install the rest of the OS api
function os.run( _tEnv, _sPath, ... )
    expect(1, _tEnv, "table")
    expect(2, _sPath, "string")

    local tArgs = table.pack( ... )
    local tEnv = _tEnv
    setmetatable( tEnv, { __index = _G } )
    local fnFile, err = loadfile( _sPath, nil, tEnv )
    if fnFile then
        local ok, err = pcall( function()
            fnFile( table.unpack( tArgs, 1, tArgs.n ) )
        end )
        if not ok then
            if err and err ~= "" then
                printError( err )
            end
            return false
        end
        return true
    end
    if err and err ~= "" then
        printError( err )
    end
    return false
end

local tAPIsLoading = {}
function os.loadAPI( _sPath )
    expect(1, _sPath, "string")
    local sName = fs.getName( _sPath )
    if sName:sub(-4) == ".lua" then
        sName = sName:sub(1,-5)
    end
    if tAPIsLoading[sName] == true then
        printError( "API "..sName.." is already being loaded" )
        return false
    end
    tAPIsLoading[sName] = true

    local tEnv = {}
    setmetatable( tEnv, { __index = _G } )
    local fnAPI, err = loadfile( _sPath, nil, tEnv )
    if fnAPI then
        local ok, err = pcall( fnAPI )
        if not ok then
            tAPIsLoading[sName] = nil
            return error( "Failed to load API " .. sName .. " due to " .. err, 1 )
        end
    else
        tAPIsLoading[sName] = nil
        return error( "Failed to load API " .. sName .. " due to " .. err, 1 )
    end

    local tAPI = {}
    for k,v in pairs( tEnv ) do
        if k ~= "_ENV" then
            tAPI[k] =  v
        end
    end

    _G[sName] = tAPI
    tAPIsLoading[sName] = nil
    return true
end

function os.unloadAPI( _sName )
    expect(1, _sName, "string")
    if _sName ~= "_G" and type(_G[_sName]) == "table" then
        _G[_sName] = nil
    end
end

function os.sleep( nTime )
    sleep( nTime )
end

local nativeShutdown = os.shutdown
function os.shutdown()
    nativeShutdown()
    while true do
        coroutine.yield()
    end
end

local nativeReboot = os.reboot
function os.reboot()
    nativeReboot()
    while true do
        coroutine.yield()
    end
end

-- Install the lua part of the HTTP api (if enabled)
if http then
    local nativeHTTPRequest = http.request

    local methods = {
        GET = true, POST = true, HEAD = true,
        OPTIONS = true, PUT = true, DELETE = true
    }

    local function checkKey( options, key, ty, opt )
        local value = options[key]
        local valueTy = type(value)

        if (value ~= nil or not opt) and valueTy ~= ty then
            error(("bad field '%s' (expected %s, got %s"):format(key, ty, valueTy), 4)
        end
    end

    local function checkOptions( options, body )
        checkKey( options, "url", "string")
        if body == false then
          checkKey( options, "body", "nil" )
        else
          checkKey( options, "body", "string", not body )
        end
        checkKey( options, "headers", "table", true )
        checkKey( options, "method", "string", true )
        checkKey( options, "redirect", "boolean", true )

        if options.method and not methods[options.method] then
            error( "Unsupported HTTP method", 3 )
        end
    end

    local function wrapRequest( _url, ... )
        local ok, err = nativeHTTPRequest( ... )
        if ok then
            while true do
                local event, param1, param2, param3 = os.pullEvent()
                if event == "http_success" and param1 == _url then
                    return param2
                elseif event == "http_failure" and param1 == _url then
                    return nil, param2, param3
                end
            end
        end
        return nil, err
    end

    http.get = function( _url, _headers, _binary)
        if type( _url ) == "table" then
            checkOptions( _url, false )
            return wrapRequest( _url.url, _url )
        end

        expect(1, _url, "string")
        expect(2, _headers, "table", "nil")
        expect(3, _binary, "boolean", "nil")
        return wrapRequest( _url, _url, nil, _headers, _binary )
    end

    http.post = function( _url, _post, _headers, _binary)
        if type( _url ) == "table" then
            checkOptions( _url, true )
            return wrapRequest( _url.url, _url )
        end

        expect(1, _url, "string")
        expect(2, _post, "string")
        expect(3, _headers, "table", "nil")
        expect(4, _binary, "boolean", "nil")
        return wrapRequest( _url, _url, _post, _headers, _binary )
    end

    http.request = function( _url, _post, _headers, _binary )
        local url
        if type( _url ) == "table" then
            checkOptions( _url )
            url = _url.url
        else
            expect(1, _url, "string")
            expect(2, _post, "string", "nil")
            expect(3, _headers, "table", "nil")
            expect(4, _binary, "boolean", "nil")
            url = _url.url
        end

        local ok, err = nativeHTTPRequest( _url, _post, _headers, _binary )
        if not ok then
            os.queueEvent( "http_failure", url, err )
        end
        return ok, err
    end

    local nativeCheckURL = http.checkURL
    http.checkURLAsync = nativeCheckURL
    http.checkURL = function( _url )
        local ok, err = nativeCheckURL( _url )
        if not ok then return ok, err end

        while true do
            local event, url, ok, err = os.pullEvent( "http_check" )
            if url == _url then return ok, err end
        end
    end

    local nativeWebsocket = http.websocket
    http.websocketAsync = nativeWebsocket
    http.websocket = function( _url, _headers )
        expect(1, _url, "string")
        expect(2, _headers, "table", "nil")

        local ok, err = nativeWebsocket( _url, _headers )
        if not ok then return ok, err end

        while true do
            local event, url, param = os.pullEvent( )
            if event == "websocket_success" and url == _url then
                return param
            elseif event == "websocket_failure" and url == _url then
                return false, param
            end
        end
    end
end

-- Install the lua part of the FS api
local tEmpty = {}
function fs.complete( sPath, sLocation, bIncludeFiles, bIncludeDirs )
    expect(1, sPath, "string")
    expect(2, sLocation, "string")
    expect(3, bIncludeFiles, "boolean", "nil")
    expect(4, bIncludeDirs, "boolean", "nil")

    bIncludeFiles = (bIncludeFiles ~= false)
    bIncludeDirs = (bIncludeDirs ~= false)
    local sDir = sLocation
    local nStart = 1
    local nSlash = string.find( sPath, "[/\\]", nStart )
    if nSlash == 1 then
        sDir = ""
        nStart = 2
    end
    local sName
    while not sName do
        local nSlash = string.find( sPath, "[/\\]", nStart )
        if nSlash then
            local sPart = string.sub( sPath, nStart, nSlash - 1 )
            sDir = fs.combine( sDir, sPart )
            nStart = nSlash + 1
        else
            sName = string.sub( sPath, nStart )
        end
    end

    if fs.isDir( sDir ) then
        local tResults = {}
        if bIncludeDirs and sPath == "" then
            table.insert( tResults, "." )
        end
        if sDir ~= "" then
            if sPath == "" then
                table.insert( tResults, (bIncludeDirs and "..") or "../" )
            elseif sPath == "." then
                table.insert( tResults, (bIncludeDirs and ".") or "./" )
            end
        end
        local tFiles = fs.list( sDir )
        for n=1,#tFiles do
            local sFile = tFiles[n]
            if #sFile >= #sName and string.sub( sFile, 1, #sName ) == sName then
                local bIsDir = fs.isDir( fs.combine( sDir, sFile ) )
                local sResult = string.sub( sFile, #sName + 1 )
                if bIsDir then
                    table.insert( tResults, sResult .. "/" )
                    if bIncludeDirs and #sResult > 0 then
                        table.insert( tResults, sResult )
                    end
                else
                    if bIncludeFiles and #sResult > 0 then
                        table.insert( tResults, sResult )
                    end
                end
            end
        end
        return tResults
    end
    return tEmpty
end

local function chk_boot()
    -- Check for bootable things
    local tBoot = {}

    print("Scanning /")
    if fs.exists("/boot") then
        table.insert(tBoot, "/boot")
    end

    local placeholderVariableThatServesAsAnIteratorForLookingAtDisks = 2 -- Sorry 'bout the variable name
    
    if fs.exists("/disk") then
        print("Scanning /disk")
        if fs.exists("/disk/boot") then
            table.insert(tBoot, "/disk/boot")
        end
    end

    while true do
        if fs.exists("/disk" .. tostring(placeholderVariableThatServesAsAnIteratorForLookingAtDisks)) then
            print("Scanning /disk" .. tostring(placeholderVariableThatServesAsAnIteratorForLookingAtDisks))
            if fs.exists("/disk" .. tostring(placeholderVariableThatServesAsAnIteratorForLookingAtDisks) .. "/boot") then
                table.insert(tBoot, "/disk" .. placeholderVariableThatServesAsAnIteratorForLookingAtDisks .. "/boot")
            end
        else
            break
        end
        placeholderVariableThatServesAsAnIteratorForLookingAtDisks = placeholderVariableThatServesAsAnIteratorForLookingAtDisks + 1
    end

    if #tBoot < 1 then
        printError("No bootable media found-- booting into help menu")
        table.insert(tBoot, "/rom/modules/help/")
    end
    return tBoot
end

local function boot(path)
    os.sleep(1)
    if fs.exists(path .. "/boot.lua") then
        dofile(path .. "/boot.lua")
    else
        printError("boot.lua not found on selected medium. Cannot continue.")
    end
end

-- Test

print("If you can read this message, there is a high chance that you have eyes, that the stars have aligned, and that the BIOS has successfully loaded.\n")

print("Checking for bootable operating systems....")

local tBoot = chk_boot()

if #tBoot == 1 then
    print("Booting from " .. tBoot[1])
    boot(tBoot[1]) -- boot tBoot[1]
else
    print("Please select a medium to boot from:")
    for i=1, #tBoot, 1 do
        print(tostring(i) .. ": " .. tBoot[i])
    end
    
    while true do
        local input = tonumber(read())
        if tBoot[input] then
            boot(tBoot[input])
            break
        end
    end
end

print("Execution complete-- Shutting down")
os.sleep(1)

-- End
os.shutdown()
