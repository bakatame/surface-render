ffi.cdef[[

    int VirtualProtect(void* lpAddress, unsigned long dwSize, unsigned long flNewProtect, unsigned long* lpflOldProtect);
    void* VirtualAlloc(void* lpAddress, unsigned long dwSize, unsigned long  flAllocationType, unsigned long flProtect);
    int VirtualFree(void* lpAddress, unsigned long dwSize, unsigned long dwFreeType);

    typedef unsigned char wchar_t;
    typedef unsigned int(__thiscall* create_font_t)(void*);
    typedef unsigned int(__thiscall* lock_cursor_t)(void*);
    typedef unsigned int(__thiscall* unlock_cursor_t)(void*); 
    typedef void(__thiscall* set_text_pos_t)(void*, int, int);
    typedef void(__thiscall* line_t)(void*, int, int, int, int);
    typedef wchar_t*(__thiscall* FindSafe_t)(void*, const char*);
    typedef void(__thiscall* set_text_font_t)(void*, unsigned long);
    typedef void(__thiscall* set_color_t)(void*, int, int, int, int);
    typedef void(__thiscall* filled_rect_t)(void*, int, int, int, int);
    typedef unsigned int(__thiscall* set_cursor_pos_t)(void*, int, int);
    typedef void(__thiscall* outlined_rect_t)(void*, int, int, int, int);
    typedef unsigned int(__thiscall* get_cursor_pos_t)(void*, int*, int*);
    typedef void(__thiscall* set_text_color_t)(void*, int, int, int, int);
    typedef void(__thiscall* outlined_circle_t)(void*, int, int, int, int);
    typedef void(__thiscall* print_text_t)(void*, const wchar_t*, int, int);
    typedef int(__thiscall* ConvertAnsiToUnicode_t)(void*, const char*, wchar_t*, int);
    typedef int(__thiscall* ConvertUnicodeToAnsi_t)(void*, const wchar_t*, char*, int);
    typedef void(__thiscall* get_text_size_t)(void*, unsigned long, const wchar_t*, int&, int&);
    typedef void(__thiscall* filled_rect_fade_t)(void*, int, int, int, int, unsigned int, unsigned int, bool);
    typedef void(__thiscall* set_font_glyph_t)(void*, unsigned long, const char*, int, int, int, int, unsigned long, int, int);
]]

local renderer = {
    funcs = {}
}

renderer.__index = renderer

local function uuid(len)
    local res, len = "", len or 32
    for i=1, len do
        res = res .. string.char(utils.random_int(97, 122))
    end
    return res
end

local interface_mt = {}
function interface_mt.get_function(self, index, ret, args)
    local ct = uuid() .. "_t"

    args = args or {}
    if type(args) == "table" then
        table.insert(args, 1, "void*")
    else
        return error("args has to be of type table", 2)
    end
    local success, res = pcall(ffi.cdef, "typedef " .. ret .. " (__thiscall* " .. ct .. ")(" .. table.concat(args, ", ") .. ");")
    if not success then
        error("invalid typedef: " .. res, 2)
    end

    local interface = self[1]
    local success, func = pcall(ffi.cast, ct, interface[0][index])
    if not success then
        return error("failed to cast: " .. func, 2)
    end

    return function(...)
        local success, res = pcall(func, interface, ...)

        if not success then
            return error("call: " .. res, 2)
        end

        if ret == "const char*" then
            return res ~= nil and ffi.string(res) or nil
        end
        return res
    end
end

local function create_interface(dll, interface_name)
    local interface = (type(dll) == "string" and type(interface_name) == "string") and utils.create_interface(dll, interface_name) or dll
    return setmetatable({ffi.cast(ffi.typeof("void***"), interface)}, {__index = interface_mt})
end


local localize = create_interface("localize.dll", "Localize_001")
local convert_ansi_to_unicode = localize:get_function(15, "int", {"const char*", "wchar_t*", "int"})
local convert_unicode_to_ansi = localize:get_function(16, "int", {"const wchar_t*", "char*", "int"})
local find_safe = localize:get_function(12, "wchar_t*", {"const char*"})

local surface_mt   = {}
surface_mt.__index = surface_mt
surface_mt.isurface = create_interface("vguimatsurface.dll", "VGUI_Surface031")
surface_mt.fn_set_color            = surface_mt.isurface:get_function(15, "void", {"int", "int", "int", "int"})
surface_mt.fn_filled_rect          = surface_mt.isurface:get_function(16, "void", {"int", "int", "int", "int"})
surface_mt.fn_outlined_rect        = surface_mt.isurface:get_function(18, "void", {"int", "int", "int", "int"})
surface_mt.fn_line                 = surface_mt.isurface:get_function(19, "void", {"int", "int", "int", "int"})
surface_mt.fn_set_text_font        = surface_mt.isurface:get_function(23, "void", {"unsigned long"})
surface_mt.fn_set_text_color       = surface_mt.isurface:get_function(25, "void", {"int", "int", "int", "int"})
surface_mt.fn_set_text_pos         = surface_mt.isurface:get_function(26, "void", {"int", "int"})
surface_mt.fn_print_text           = surface_mt.isurface:get_function(28, "void", {"const wchar_t*", "int", "int" })

surface_mt.fn_unlock_cursor             = surface_mt.isurface:get_function(66, "void")
surface_mt.fn_lock_cursor               = surface_mt.isurface:get_function(67, "void")
surface_mt.fn_create_font               = surface_mt.isurface:get_function(71, "unsigned int")
surface_mt.fn_set_font_glyph            = surface_mt.isurface:get_function(72, "void", {"unsigned long", "const char*", "int", "int", "int", "int", "unsigned long", "int", "int"})
surface_mt.fn_get_text_size             = surface_mt.isurface:get_function(79, "void", {"unsigned long", "const wchar_t*", "int&", "int&"})
surface_mt.fn_get_cursor_pos            = surface_mt.isurface:get_function(100, "unsigned int", {"int*", "int*"})
surface_mt.fn_set_cursor_pos            = surface_mt.isurface:get_function(101, "unsigned int", {"int", "int"})
surface_mt.fn_outlined_circle      = surface_mt.isurface:get_function(103, "void", {"int", "int", "int", "int"})
surface_mt.fn_filled_rect_fade     = surface_mt.isurface:get_function(123, "void", {"int", "int", "int", "int", "unsigned int", "unsigned int", "bool"})

function surface_mt.set_color(r, g, b, a)
    surface_mt.fn_set_color(r, g, b, a)
end

function surface_mt.filled_rect(x0, y0, x1, y1)
    surface_mt.fn_filled_rect(x0, y0, x1, y1)
end

function surface_mt.outlined_rect(x0, y0, x1, y1)
    surface_mt.fn_outlined_rect(x0, y0, x1, y1)
end

function surface_mt.line(x0, y0, x1, y1)
    surface_mt.fn_line(x0, y0, x1, y1)
end

function surface_mt.outlined_circle(x, y, radius, segments)

    surface_mt.fn_outlined_circle(x, y, radius, segments)
end

function surface_mt.filled_rect_fade(x0, y0, x1, y1, alpha0, alpha1, horizontal)
    surface_mt.fn_filled_rect_fade(x0, y0, x1, y1, alpha0, alpha1, horizontal)
end

function surface_mt.set_text_font(font)
    surface_mt.fn_set_text_font(font)
end

function surface_mt.set_text_color(r, g, b, a)
    surface_mt.fn_set_text_color(r, g, b, a)
end

function surface_mt.set_text_pos(x, y)
    surface_mt.fn_set_text_pos(x, y)
end

function surface_mt.print_text(text, localized)
    if localized then 
        local char_buffer = ffi.new('char[1024]')  
        convert_unicode_to_ansi(text, char_buffer, 1024)
        local test = ffi.string(char_buffer)
        surface_mt.fn_print_text(text, test:len(), 0)
    else
        local wide_buffer = ffi.new('wchar_t[1024]')    
        convert_ansi_to_unicode(text, wide_buffer, 1024)
        surface_mt.fn_print_text(wide_buffer, text:len(), 0)
    end
end

function surface_mt.create_font() 
    return (surface_mt.fn_create_font())
end

function surface_mt.set_font_glyph(font, font_name, tall, weight, flags)
    local x = 0
    if type(flags) == "number" then
        x = flags
    elseif type(flags) == "table" then
        for i=1, #flags do
            x = x + flags[i]
        end
    end
    surface_mt.fn_set_font_glyph(font, font_name, tall, weight, 0, 0, bit.bor(x), 0, 0)
end

function surface_mt.get_text_size(font, text)
    local wide_buffer = ffi.new('wchar_t[1024]') 
    local int_ptr = ffi.typeof("int[1]") 
    local wide_ptr = int_ptr() local tall_ptr = int_ptr()

    convert_ansi_to_unicode(text, wide_buffer, 1024)
    surface_mt.fn_get_text_size(font, wide_buffer, wide_ptr, tall_ptr)
    local wide = tonumber(ffi.cast("int", wide_ptr[0]))
    local tall = tonumber(ffi.cast("int", tall_ptr[0]))
    return wide, tall
end

function surface_mt.get_cursor_pos() 
   local int_ptr = ffi.typeof("int[1]") 
   local x_ptr = int_ptr() local y_ptr = int_ptr()
   surface_mt.fn_get_cursor_pos(x_ptr, y_ptr)
   local x = tonumber(ffi.cast("int", x_ptr[0]))
   local y = tonumber(ffi.cast("int", y_ptr[0]))
   return x, y
end

function surface_mt.set_cursor_pos(x, y)
    surface_mt.fn_set_cursor_pos(x, y)
end

function surface_mt.unlock_cursor() 
    surface_mt.fn_unlock_cursor()
end

function surface_mt.lock_cursor() 
    surface_mt.fn_lock_cursor()
end

renderer.create_font = function (windows_font_name, tall, weight, flags)
    if type(windows_font_name) ~= "string" or type(tall) ~= "number" or type(weight) ~= "number" or type(flags) ~= "number" then
        error("[renderer.create_font] invalid arguments")
        return false
    end

    local font = surface_mt.create_font()
    if type(flags) == "nil" then 
        flags = 0 
    end
    surface_mt.set_font_glyph(font, windows_font_name, tall, weight, flags)
    return font
end

renderer.localize_string = function (text)
    if type(text) ~= "string" then
        error("[renderer.localize_string] invalid arguments")
        return false
    end

    local localized_string = find_safe(text)
    local char_buffer = ffi.new('char[1024]')
    convert_unicode_to_ansi(localized_string, char_buffer, 1024)
    return ffi.string(char_buffer)
end

renderer.text = function (x, y, r, g, b, a, font, text)
    if type(x) ~= "number" or type(y) ~= "number" or type(r) ~= "number" or type(g) ~= "number" or type(b) ~= "number" or type(a) ~= "number" or type(font) ~= "number" or type(text) ~= "string" then
        error("[renderer.text] invalid arguments")
        return false
    end

    table.insert(renderer.funcs,
        function ()
            surface_mt.set_text_pos(x, y)
            surface_mt.set_text_font(font)
            surface_mt.set_text_color(r, g, b, a)
            surface_mt.print_text(tostring(text), false)
        end
    )
end

renderer.localized_text = function (x, y, r, g, b, a, font, text)
    if type(x) ~= "number" or type(y) ~= "number" or type(r) ~= "number" or type(g) ~= "number" or type(b) ~= "number" or type(a) ~= "number" or type(font) ~= "number" or type(text) ~= "string" then
        error("[renderer.localized_text] invalid arguments")
        return false
    end

    table.insert(renderer.funcs,
        function ()
            surface_mt.set_text_pos(x, y)
            surface_mt.set_text_font(font)
            surface_mt.set_text_color(r, g, b, a)

            local localized_string = find_safe(text)

            surface_mt.print_text(localized_string, true)
        end
    )
end

renderer.line = function (x0, y0, x1, y1, r, g, b, a)
    if type(x0) ~= "number" or type(y0) ~= "number" or type(x1) ~= "number" or type(y1) ~= "number" or type(r) ~= "number" or type(g) ~= "number" or type(b) ~= "number" or type(a) ~= "number" then
        error("[renderer.line] invalid arguments")
        return false
    end

    table.insert(renderer.funcs,
        function ()
            surface_mt.set_color(r, g, b, a)
            surface_mt.line(x0, y0, x1, y1)
        end
    )
end

renderer.filled_rect = function (x, y, w, h, r, g, b, a)
    if type(x) ~= "number" or type(y) ~= "number" or type(w) ~= "number" or type(h) ~= "number" or type(r) ~= "number" or type(g) ~= "number" or type(b) ~= "number" or type(a) ~= "number" then
        error("[renderer.filled_rect] invalid arguments")
        return false
    end

    table.insert(renderer.funcs,
        function ()
            surface_mt.set_color(r, g, b, a)
            surface_mt.filled_rect(x, y, x + w, y + h)
        end
    )
end

renderer.outlined_rect = function (x, y, w, h, r, g, b, a)
    if type(x) ~= "number" or type(y) ~= "number" or type(w) ~= "number" or type(h) ~= "number" or type(r) ~= "number" or type(g) ~= "number" or type(b) ~= "number" or type(a) ~= "number" then
        error("[renderer.outlined_rect] invalid arguments")
        return false
    end

    table.insert(renderer.funcs,
        function ()
            surface_mt.set_color(r, g, b, a)
            surface_mt.outlined_rect(x, y, x + w, y + h)
        end
    )
end

renderer.filled_outlined_rect = function (x, y, w, h, r0, g0, b0, a0, r1, g1, b1, a1)
    if type(x) ~= "number" or type(y) ~= "number" or type(w) ~= "number" or type(h) ~= "number" or type(r0) ~= "number" or type(g0) ~= "number" or type(b0) ~= "number" or type(a0) ~= "number" or type(r1) ~= "number" or type(g1) ~= "number" or type(b1) ~= "number" or type(a1) ~= "number" then
        error("[renderer.filled_outlined_rect] invalid arguments")
        return false
    end

    table.insert(renderer.funcs,
        function ()
            surface_mt.set_color(r0, g0, b0, a0)
            surface_mt.filled_rect(x, y, x + w, y + h)
            surface_mt.set_color(r1, g1, b1, a1)
            surface_mt.outlined_rect(x, y, x + w, y + h)
        end
    )
end

renderer.filled_gradient_rect = function (x, y, w, h, r0, g0, b0, a0, r1, g1, b1, a1, horizontal)
    if type(x) ~= "number" or type(y) ~= "number" or type(w) ~= "number" or type(h) ~= "number" or type(r0) ~= "number" or type(g0) ~= "number" or type(b0) ~= "number" or type(a0) ~= "number" or type(r1) ~= "number" or type(g1) ~= "number" or type(b1) ~= "number" or type(a1) ~= "number" or type(horizontal) ~= "boolean" then
        error("[renderer.filled_gradient_rect] invalid arguments")
        return false
    end

    table.insert(renderer.funcs,
        function ()
            surface_mt.set_color(r0, g0, b0, a0)
            surface_mt.filled_rect_fade(x, y, x + w, y + h, 255, 255, horizontal)
        
            surface_mt.set_color(r1, g1, b1, a1)
            surface_mt.filled_rect_fade(x, y, x + w, y + h, 0, 255, horizontal)
        end
    )
end

renderer.outlined_circle = function (x, y, r, g, b, a, radius, segments)
    if type(x) ~= "number" or type(y) ~= "number" or type(r) ~= "number" or type(g) ~= "number" or type(b) ~= "number" or type(a) ~= "number" or type(radius) ~= "number" or type(segments) ~= "number" then
        error("[renderer.outlined_circle] invalid arguments")
        return false
    end

    table.insert(renderer.funcs,
        function ()
            surface_mt.set_color(r, g, b, a)
            surface_mt.outlined_circle(x, y, radius, segments)
        end
    )
end

renderer.test_font = function (x, y, r, g, b, a, font)
    if type(x) ~= "number" or type(y) ~= "number" or type(r) ~= "number" or type(g) ~= "number" or type(b) ~= "number" or type(a) ~= "number" or type(font) ~= "number" then
        error("[renderer.test_font] invalid arguments")
        return false
    end

    table.insert(renderer.funcs,
        function ()
            local _, height_offset = surface_mt.get_text_size(font, "a b c d e f g h i j k l m n o p q r s t u v w x y z")
           
            renderer.text(x, y, r, g, b, a, font, "a b c d e f g h i j k l m n o p q r s t u v w x y z 0 1 2 3 4 5 6 7 8 9 ß + # ä ö ü , . -")
            renderer.text(x, y + height_offset, r, g, b, a,  font, "A B C D E F G H I J K L M N O P Q R S T U V W X Y Z = ! \" § $ % & / ( ) = ? { [ ] } \\ * ' _ : ; ~ ")
        end
    )
end

renderer.get_text_size = function (font, text)
    if type(font) ~= "number" or type(text) ~= "string" then
        error("[renderer.get_text_size] invalid arguments")
        return false
    end

    return surface_mt.get_text_size(font, text)
end

renderer.set_mouse_pos = function (x, y)
    if type(x) ~= "number" or type(y) ~= "number" then
        error("[renderer.set_mouse_pos] invalid arguments")
        return false
    end

    table.insert(renderer.funcs,
        function ()
            surface_mt.set_cursor_pos(x, y)
        end
    )
end

renderer.get_mouse_pos = function ()
    return surface_mt.get_cursor_pos()
end

renderer.unlock_cursor = function ()
    table.insert(renderer.funcs,
        function ()
            surface_mt.unlock_cursor()
        end
    )
end

renderer.lock_cursor = function ()
    table.insert(renderer.funcs,
        function ()
            surface_mt.lock_cursor()
        end
    )
end

local buff = {free = {}}
local vmt_hook = {hooks = {}}

local vmt_helpers = {
    copy = function (dst, src, len)
        return ffi.copy(ffi.cast('void*', dst), ffi.cast('const void*', src), len)
    end,
    
    VirtualProtect = function (lpAddress, dwSize, flNewProtect, lpflOldProtect)
        return ffi.C.VirtualProtect(ffi.cast('void*', lpAddress), dwSize, flNewProtect, lpflOldProtect)
    end,
    
    VirtualAlloc = function(lpAddress, dwSize, flAllocationType, flProtect, blFree)
        local alloc = ffi.C.VirtualAlloc(lpAddress, dwSize, flAllocationType, flProtect)
        if blFree then
            table.insert(buff.free, function()
                ffi.C.VirtualFree(alloc, 0, 0x8000)
            end)
        end
        return ffi.cast("intptr_t", alloc)
    end
}

vmt_hook.new = function (vt)
    local new_hook = {}
    local org_func = {}
    local old_prot = ffi.new('unsigned long[1]')
    local virtual_table = ffi.cast('intptr_t**', vt)[0]

    new_hook.this = virtual_table
    new_hook.hookMethod = function(cast, func, method)
        org_func[method] = virtual_table[method]
        vmt_helpers.VirtualProtect(virtual_table + method, 4, 0x4, old_prot)

        virtual_table[method] = ffi.cast('intptr_t', ffi.cast(cast, func))
        vmt_helpers.VirtualProtect(virtual_table + method, 4, old_prot[0], old_prot)

        return ffi.cast(cast, org_func[method])
    end

    new_hook.unHookMethod = function(method)
        vmt_helpers.VirtualProtect(virtual_table + method, 4, 0x4, old_prot)
        local alloc_addr = vmt_helpers.VirtualAlloc(nil, 5, 0x1000, 0x40, false)
        local trampoline_bytes = ffi.new('uint8_t[?]', 5, 0x90)

        trampoline_bytes[0] = 0xE9
        ffi.cast('int32_t*', trampoline_bytes + 1)[0] = org_func[method] - tonumber(alloc_addr) - 5

        vmt_helpers.copy(alloc_addr, trampoline_bytes, 5)
        virtual_table[method] = ffi.cast('intptr_t', alloc_addr)

        vmt_helpers.VirtualProtect(virtual_table + method, 4, old_prot[0], old_prot)
        org_func[method] = nil
    end

    new_hook.unHookAll = function()
        for method, func in pairs(org_func) do
            new_hook.unHookMethod(method)
        end
    end

    table.insert(vmt_hook.hooks, new_hook.unHookAll)
    return new_hook
end

local vgui2 = utils.create_interface("vgui2.dll", "VGUI_Panel009")
local VGUI_Panel009 = vmt_hook.new(vgui2)
local panel_interface = ffi.cast(ffi.typeof("void***"), vgui2)
local get_panel_name = ffi.cast(ffi.typeof("const char*(__thiscall*)(void*, uint32_t)"), panel_interface[0][36])

local painttraverse = function (void, int, bool, bool2)
    local panel_name = ffi.string(get_panel_name(void, int))
    if panel_name == "FocusOverlayPanel" then
        for _, render in pairs(renderer.funcs) do
            render()
        end
        renderer.funcs = {}
    end
    VGUI_Panel(void, int, bool, bool2)
end
VGUI_Panel = VGUI_Panel009.hookMethod("void(__thiscall*)(void*, unsigned int, bool, bool)", painttraverse, 41)

events.shutdown:set(function()
    for _, un_hook in ipairs(vmt_hook.hooks) do
        un_hook()
    end
end)

--  < example >
    
--[[ local font = renderer.create_font("Verdana", 13, 300, 0x080)

events.render:set(function(ctx)
    local en_text = "Suface_Render"
    local cn_text = "中文渲染测试"
    local textsize_x, textsize_y = renderer.get_text_size(font, cn_text)
    renderer.outlined_rect(297, 158, textsize_x + 7, textsize_y + 4, 255, 0, 0, 255)
    renderer.filled_rect(298, 159, textsize_x + 5, textsize_y + 2, 16, 16, 16, 255)
    renderer.text(300, 160, 255, 0, 0, 255, font, cn_text)
end) ]]

return renderer
