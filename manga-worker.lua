local utils = require 'mp.utils'
local filearray = {}
local filedims = {}
local opts = {
	archive = false,
	manga = false,
	p7zip = false,
	rar = false,
	tar = false,
	zip = false
}
local aspect_ratio
local root
local length
local index

function check_aspect_ratio(a, b)
	local m = a[0]+b[0]
	local n
	if a[1] > b[1] then
		n = a[1]
	else
		n = b[1]
	end
	if m/n <= aspect_ratio then
		return true
	else
		return false
	end
end

function file_exists(name)
	local f = io.open(name, "r")
	if f == nil then
		return false
	else
		io.close(f)
		return true
	end
end

function generate_name(cur_page, next_page)
	local cur_base = string.gsub(cur_page, ".*/", "")
	cur_base = string.gsub(cur_base, "%..*", "")
	local next_base = string.gsub(next_page, ".*/", "")
	next_base = string.gsub(next_base, "%..*", "")
	local name = cur_base.."-"..next_base..".png"
	return name
end

function get_index()
	local filename = mp.get_property("filename")
	local index
	for i=0,length do
		if string.match(filearray[i], filename) then
			index = i
			break
		end
	end
	return index
end

function create_stitches()
	local start = get_index()
	if not (filearray[start] and filearray[start+1]) then
		return
	end
	if start+10 > length then
		last = length - 2
	else
		last = start+10
	end
	for i=start,last do
		local width_check = check_aspect_ratio(filedims[i], filedims[i+1])
		local name = generate_name(filearray[i], filearray[i+1])
		if not file_exists(name) and width_check then
			if opts.archive then
				local archive = string.gsub(root, ".*/", "")
				if opts.p7zip then
					os.execute("7z e "..archive.." "..filearray[i].." "..filearray[i+1])
				elseif opts.rar then
					os.execute("unrar e "..archive.." "..filearray[i].." "..filearray[i+1])
				elseif opts.tar then
					os.execute("tar -xf "..archive.." "..filearray[i].." "..filearray[i+1])
				elseif opts.zip then
					os.execute("unzip "..archive.." "..filearray[i].." "..filearray[i+1])
				end
			else
				cur_page = utils.join_path(root, filearray[i])
				next_page = utils.join_path(root, filearray[i+1])
			end
			if opts.manga then
				os.execute("convert "..filearray[i+1].." "..filearray[i].." +append "..name)
			else
				os.execute("convert "..filearray[i].." "..filearray[i+1].." +append "..name)
			end
			if opts.archive then
				os.execute("rm "..filearray[i].." "..filearray[i+1])
			end
		end
	end
end

function str_split(str, delim)
	local split = {}
	local i = 0
	for token in string.gmatch(str, "([^"..delim.."]+)") do
		split[i] = token
		i = i + 1
	end
	return split
end

function get_dims(page)
	local dims = {}
	local p
	local str
	if opts.archive then
		local archive = string.gsub(root, ".*/", "")
		if opts.p7zip then
			p = io.popen("7z e -so "..archive.." "..page.." | identify -")
		elseif opts.rar then
			p = io.popen("unrar p "..archive.." "..page.." | identify -")
		elseif opts.tar then
			p = io.popen("tar -xOf "..archive.." "..page.." | identify -")
		elseif opts.zip then
			p = io.popen("unzip -p "..archive.." "..page.." | identify -")
		end
		io.input(p)
		str = io.read()
		if str == nil then
			dims = nil
		else
			local i, j = string.find(str, "[0-9]+x[0-9]+")
			local sub = string.sub(str, i, j)
			dims = str_split(sub, "x")
		end
	else
		local path = utils.join_path(root, page)
		p = io.popen("identify -format '%w,%h' "..path)
		io.input(p)
		str = io.read()
		io.close()
		if str == nil then
			dims = nil
		else
			dims = str_split(str, ",")
		end
	end
	return dims
end

function get_filelist(path)
	local filelist
	if opts.archive then
		local archive = string.gsub(path, ".*/", "")
		if opts.p7zip then
			filelist = io.popen("7z l -slt "..archive.. " | grep 'Path =' | grep -v "..archive.." | sed 's/Path = //g'")
		elseif opts.rar then
			filelist = io.popen("unrar l "..archive)
		elseif opts.tar then
			filelist = io.popen("tar -tf "..archive.. " | sort")
		elseif opts.zip then
			filelist = io.popen("zipinfo -1 "..archive)
		end
	else
		filelist = io.popen("ls "..path)
	end
	return filelist
end

mp.register_script_message("start-worker", function(archive, manga, p7zip, rar, tar, zip, ratio, base)
	if archive == "true" then
		opts.archive = true
	end
	if manga == "true" then
		opts.manga = true
	end
	if p7zip == "true" then
		opts.p7zip = true
	end
	if rar == "true" then
		opts.rar = true
	end
	if tar == "true" then
		opts.tar = true
	end
	if zip == "true" then
		opts.zip = true
	end
	root = base
	aspect_ratio = tonumber(ratio)
	local filelist = get_filelist(root)
	local i = 0
	for filename in filelist:lines() do
		filename = string.gsub(filename, " ", "\\ ")
		local dims = get_dims(filename)
		if dims ~= nil then
			filearray[i] = filename
			filedims[i] = dims
			i = i + 1
		end
	end
	filelist:close()
	length = i
	mp.register_event("file-loaded", create_stitches)
end)