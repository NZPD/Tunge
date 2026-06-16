local Table = {}

function Table.DeepCopy(t: { any }): { any }
	if type(t) ~= "table" then return t end
	local copy = {}
	for k, v in next, t do
		copy[Table.DeepCopy(k)] = Table.DeepCopy(v)
	end
	return setmetatable(copy, getmetatable(t))
end

function Table.Merge(t1: { any }, t2: { any }): { any }
	local result = Table.DeepCopy(t1)
	for k, v in next, t2 do
		result[k] = v
	end
	return result
end

function Table.Find(t: { any }, predicate: (any, number?) -> boolean): any?
	for i, v in t do
		if predicate(v, i) then return v, i end
	end
	return nil
end

function Table.Filter(t: { any }, predicate: (any, number?) -> boolean): { any }
	local result = {}
	for i, v in t do
		if predicate(v, i) then
			result[#result + 1] = v
		end
	end
	return result
end

function Table.Map(t: { any }, transform: (any, number?) -> any): { any }
	local result = {}
	for i, v in t do
		result[i] = transform(v, i)
	end
	return result
end

function Table.Keys(t: { any }): { any }
	local keys = {}
	for k in next, t do
		keys[#keys + 1] = k
	end
	return keys
end

function Table.Values(t: { any }): { any }
	local values = {}
	for _, v in next, t do
		values[#values + 1] = v
	end
	return values
end

function Table.Shuffle(t: { any }): { any }
	local shuffled = Table.DeepCopy(t)
	for i = #shuffled, 2, -1 do
		local j = math.random(1, i)
		shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
	end
	return shuffled
end

function Table.Count(t: { any }): number
	local count = 0
	for _ in next, t do count += 1 end
	return count
end

function Table.IsEmpty(t: { any }): boolean
	return next(t) == nil
end

function Table.PickRandom(t: { any }): any?
	local items = Table.Values(t)
	if #items == 0 then return nil end
	return items[math.random(1, #items)]
end

return Table