local function tcount(tbl)

	local cnt = 0
	for k,v in pairs(tbl) do 
		cnt = cnt + 1 
	end 
	return cnt 
end 



return {
	tcount 		= tcount,
}