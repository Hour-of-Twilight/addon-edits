local MAJOR_VERSION = "LibTranslit-1.0"
local MINOR_VERSION = 3
if not LibStub then
	error(MAJOR_VERSION .. " requires LibStub.")
end
local lib = LibStub:NewLibrary(MAJOR_VERSION, MINOR_VERSION)
if not lib then
	return
end

local CyrToLat = {
	[""] = "A",
	[""] = "a",
	[""] = "B",
	[""] = "b",
	[""] = "V",
	[""] = "v",
	[""] = "G",
	[""] = "g",
	[""] = "D",
	[""] = "d",
	[""] = "E",
	[""] = "e",
	[""] = "e",
	[""] = "e",
	[""] = "Zh",
	[""] = "zh",
	[""] = "Z",
	[""] = "z",
	[""] = "I",
	[""] = "i",
	[""] = "Y",
	[""] = "y",
	[""] = "K",
	[""] = "k",
	[""] = "L",
	[""] = "l",
	[""] = "M",
	[""] = "m",
	[""] = "N",
	[""] = "n",
	[""] = "O",
	[""] = "o",
	[""] = "P",
	[""] = "p",
	[""] = "R",
	[""] = "r",
	[""] = "S",
	[""] = "s",
	[""] = "T",
	[""] = "t",
	[""] = "U",
	[""] = "u",
	[""] = "F",
	[""] = "f",
	[""] = "Kh",
	[""] = "kh",
	[""] = "Ts",
	[""] = "ts",
	[""] = "Ch",
	[""] = "ch",
	[""] = "Sh",
	[""] = "sh",
	[""] = "Shch",
	[""] = "shch",
	[""] = "",
	[""] = "",
	[""] = "Y",
	[""] = "y",
	[""] = "",
	[""] = "",
	[""] = "E",
	[""] = "e",
	[""] = "Yu",
	[""] = "yu",
	[""] = "Ya",
	[""] = "ya"
}

function lib:Transliterate(str, mark)
	if not str then
		return ""
	end

	local mark = mark or ""
	local tstr = ""
	local marked = false
	local i = 1

	while i <= string.len(str) do
		local c = str:sub(i, i)
		local b = string.byte(c)

		if b == 208 or b == 209 then
			if marked == false then
				tstr = tstr .. mark
				marked = true
			end
			c = str:sub(i + 1, i + 1)
			tstr = tstr .. (CyrToLat[string.char(b, string.byte(c))] or string.char(b, string.byte(c)))

			i = i + 2
		else
			if c == " " or c == "-" then
				marked = false
			end
			tstr = tstr .. c
			i = i + 1
		end
	end

	return tstr
end
