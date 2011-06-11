--[[

	dice.lua - A dice rolling module useful for bell curve type random distributions
	================================================================================
	
	(c)2011 Shaun Sullivan
	Electric Plum, LLC
	www.electricplum.com
	
	twitter: @LiquidSullivan
	email: shaun@electricplum.com
	
	Please use freely in any of your projects!
		
		Example usage:
			
			local dice = require("dice")
			-- Most compact method roll 4d6 and subtract 2 from the roll
			local dRoller = dice.new({dice=4, sides=6, adjust=-2})
			dRoller.roll()
			
			local dRoller = dice.new()

			-- Roll 3 6 sided dice and add 1 to the result (string method)
			local roll = dRoller.rollFromDiceString("3d6+1")
			print("roll = "..tostring(roll))

			-- Add 3 8 sided dice and one 12 and then roll
			dRoller.reset()
			dRoller.addMultipleDice(3, 8)
			dRoller.addDie(12)
			roll = dRoller.roll()
			print("roll = "..roll)

			-- Roll 4 10-sided dice and add 6 to the total
			for i=1,10 do
				print(dRoller.rollFromDiceString("4d10+6"))
			end
		
]]--

module (..., package.seeall)

-------------------------------------------------------------------------------
-- new
--
-- Construct a new one and return it
-- Optional object constructor arguments: {dice, sides, adjust, seed}
--
-------------------------------------------------------------------------------
new = function(args)
	
	-- Table we'll return
	local t = {}
	
	-- privates

	-- array of dice
	local _dies = {}
	-- number of dice 
	local _numDies = 0
	-- random seed to use default to os.time() but can be overriden by the caller 
	local _seed = os.time()
	-- something to add or subtract to/from the die roll 
	local _adjust = 0

	-------------------------------------------------------------------------------
	-- initInternal
	-------------------------------------------------------------------------------
	local initInternal = function(args)
	
		if args then
			
			-- Use the caller's seed or just seed with the time
			_seed = args.seed or _seed
			_numDies = args.dice or 0
			_adjust = args.adjust or 0 
			
			if (_numDies > 0) then
			
				for i=1,_numDies do
					
					-- default to 6 sided 
					_dies[i] = args.sides or 6
					
				end
			end
				
		else
			
			-- No args passed at all, so we start empty
			_seed = os.time()
			_numDies =  0
			_adjust = 0
		
		end
		
		-- Seed, note the caller can pass in a seed to get a repeatable sequence
		math.randomseed(_seed)
		
	end

	-------------------------------------------------------------------------------
	-- rollInternal
	-------------------------------------------------------------------------------
	local rollInternal = function()
	
		local total = 0
	
		for i=1,_numDies do
			total = total + math.random(1, _dies[i])
		end
	
		return total + _adjust
	
	end
	
	-------------------------------------------------------------------------------
	-- quickResetInternal
	--
	-- Called by rollFromDiceString to make sure it gets a clean roll
	--
	-------------------------------------------------------------------------------
	local quickResetInternal = function()
		_dies = nil
		_dies = {}
		_numDies = 0
		_adjust = 0
	end
	
	-------------------------------------------------------------------------------
	-- Constructor
	-------------------------------------------------------------------------------
	initInternal(args)
	
	-- ============================================================================
	-- public interface
	-- ============================================================================
	
	-------------------------------------------------------------------------------
	-- reset
	-------------------------------------------------------------------------------
	t.reset = function(args)
		initInternal(args)
	end

	-------------------------------------------------------------------------------
	-- addDie
	-------------------------------------------------------------------------------
	t.addDie = function(sides) 

		_numDies = _numDies + 1
		_dies[_numDies] = sides
	
	end
	
	-------------------------------------------------------------------------------
	-- addMultipleDice
	-------------------------------------------------------------------------------
	t.addMultipleDice = function(numDiceToAdd, numSides)
		
		numDiceToAdd = numDiceToAdd or 1
		numSides = numSides or 6
		
		if (numDiceToAdd < 1) then
			print("bad args, forcing one die")	
			numDiceToAdd = 1
		end
		
		if (numSides < 1) then
			print("bad args, forcing 6 sides")	
			numSides = 6 
		end
			
		--for i=1,#_dies do
		for i=1,numDiceToAdd do
		
			_numDies = _numDies + 1
			_dies[_numDies] = numSides
		
		end
	
	end

	-------------------------------------------------------------------------------
	-- rollFromDiceString	
	--
	-- Pass in a string like "4d6+3" (roll 4 6 sided dice and add 3)
	-------------------------------------------------------------------------------
	t.rollFromDiceString = function(s)
		
		-- "split" Lifted from Crawlspace Lib 
		-- https://github.com/AdamBuchweitz/CrawlSpaceLib 
		local split = function(str, pat)
		    local t = {}
		    local fpat = "(.-)" .. pat
		    local last_end = 1
		    local s, e, cap = str:find(fpat, 1)
		    while s do
		        if s ~= 1 or cap ~= "" then table.insert(t,cap) end
		        last_end = e+1
		        s, e, cap = str:find(fpat, last_end)
		    end
		    if last_end <= #str then
		        cap = str:sub(last_end)
		        table.insert(t,cap)
		    end
		    return t
		end
		
		-- Sanity check to at least make sure we have a "d" in the string
		local dLoc = string.find(s, "d") or 0
		
		if (dLoc > 0) then
			
			local addSubRoll = 0
			local dice = split(s, "d")
			local numD = tonumber(dice[1])
			local stopAt = 0
			local sides = 0
			
			-- not super robust here, you could pass in +- in the same 
			-- string and break it, but just testing... 	
			if (string.find(s, "+")) then
				
				local plus = string.find(s, "+")
				addSubRoll = tonumber(string.sub(s, plus + 1))
				stopAt = plus - 1
				
			elseif (string.find(s, "-")) then
				
				local minus = string.find(s, "-")
				addSubRoll = tonumber(string.sub(s, minus + 1)) * -1
				stopAt = minus - 1
			
			else
				stopAt = 0
			end			
			
			local dPos = string.find(s, "d")
			
			if (stopAt ~= 0) then
				sides = tonumber(string.sub(s, dPos + 1, stopAt))
			else
				sides = tonumber(string.sub(s, dPos))
			end
			
			-- We don't want to add to previous initializations
			quickResetInternal()
			t.addMultipleDice(numD, sides)
			
			_adjust = addSubRoll
			return(rollInternal())
			
		else
			assert(false, "Bad arguments")
		end	
		
		
	end

	-------------------------------------------------------------------------------
	-- roll
	-------------------------------------------------------------------------------
	t.roll = function()
		
		return rollInternal()
		
	end
	
	-------------------------------------------------------------------------------
	-- get_Seed
	--
	-- getter for the seed if the caller wants to store it for 
	-- some future replay
	-------------------------------------------------------------------------------
	t.get_Seed = function()

		return _seed
	
	end
	
	return t
	
end
