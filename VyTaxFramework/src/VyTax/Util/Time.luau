local Time = {}

function Time.Seconds(seconds: number): number
	return seconds
end

function Time.Minutes(minutes: number): number
	return minutes * 60
end

function Time.Hours(hours: number): number
	return hours * 3600
end

function Time.Days(days: number): number
	return days * 86400
end

function Time.Format(seconds: number): string
	local s = seconds % 60
	local m = math.floor(seconds / 60) % 60
	local h = math.floor(seconds / 3600)
	if h > 0 then
		return ("%02d:%02d:%02d"):format(h, m, s)
	end
	return ("%02d:%02d"):format(m, s)
end

function Time.FormatLong(seconds: number): string
	local s = seconds % 60
	local m = math.floor(seconds / 60) % 60
	local h = math.floor(seconds / 3600)
	local d = math.floor(seconds / 86400)
	local parts = {}
	if d > 0 then table.insert(parts, ("%d day%s"):format(d, d ~= 1 and "s" or "")) end
	if h > 0 then table.insert(parts, ("%d hour%s"):format(h, h ~= 1 and "s" or "")) end
	if m > 0 then table.insert(parts, ("%d min%s"):format(m, m ~= 1 and "s" or "")) end
	if s > 0 or #parts == 0 then table.insert(parts, ("%d sec%s"):format(s, s ~= 1 and "s" or "")) end
	return table.concat(parts, ", ")
end

function Time.Clock(): number
	return os.clock()
end

function Time.Timestamp(): number
	return DateTime.now().UnixTimestampMillis
end

function Timestamp()
	return DateTime.now().UnixTimestampMillis
end

return Time