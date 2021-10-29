---------------------------------------------------------------------------------
-- Tanks: This is a common way to do state managed game objects so that 
--    the system only needs to share a "game time" and all the information
--    about and object can be calculated locally. 
--    This is what this does for the tanks in this example.

-- 1. Tank splines are created that tanks can drive around.
-- 2. A game is started which then announces to clients the gameobj. 
--    The gameobj then innitiates the number of requested tanks. 
--    On the client side, it uses the time base from the gameobject to do so.
--    And it recieves all the intiial starting positions of the tanks.
-- 3. The game starts playing and tank position is calulated from the spline it
--    has been assigned, the starting pos and the current game time.
-- 4. If a tank is shot, the server checks the time the reuqets occurs
--    and see's which client was first to kill it. 

-- Thats it. Quite simple. If the tanks could shoot, then a shoot event and 
--    vector would need to be added, along with client side and server side
--    collision check and sync. 

---------------------------------------------------------------------------------

OSVehicle   = require("lua.opensteer.os-simplevehicle")
OSPathway   = require("lua.opensteer.os-pathway")
Vec3        = require("lua.opensteer.os-vec")

---------------------------------------------------------------------------------
-- The tank and general game data for a module
local gamedata = {

    max_tanks       = 10,

    -- List of paths used by tanks (common to all games)
    tank_paths      = {
        { 230.08,578.55,328.37,620.25,328.37,620.25,
        328.37,620.25,432.61,606.85,432.61,606.85,
        432.61,606.85,495.16,557.70,495.16,557.70,
        495.16,557.70,578.55,461.65,578.55,461.65,
        578.55,461.65,664.93,425.17,666.41,425.17,
        667.90,425.17,785.55,398.36,785.55,398.36,
        785.55,398.36,815.33,327.62,815.33,326.13,
        815.33,324.64,787.04,236.04,787.04,236.04,
        787.04,236.04,683.54,233.80,683.54,233.80,
        683.54,233.80,663.44,282.95,663.44,282.95,
        663.44,282.95,616.53,345.49,616.53,345.49,
        616.53,345.49,535.37,338.05,535.37,338.05,
        535.37,338.05,397.62,294.86,397.62,294.86,
        397.62,294.86,260.61,290.39,260.61,290.39,
        260.61,290.39,202.53,324.64,202.53,324.64,
        202.53,324.64,137.75,387.19,137.75,387.19,
        137.75,387.19,113.18,436.33,113.18,436.33,
        113.18,436.33,184.66,495.90,184.66,495.90,
        184.66,495.90,221.15,533.88,219.66,533.88 },

        { 138.50,565.15,242.74,562.92,242.74,562.92,
        242.74,562.92,401.34,551.75,401.34,551.75,
        401.34,551.75,431.12,516.75,431.12,516.75,
        431.12,516.75,265.08,524.94,265.08,524.94,
        265.08,524.94,219.66,505.58,219.66,505.58,
        219.66,505.58,116.16,466.86,116.16,466.86,
        116.16,466.86,68.50,491.43,68.50,491.43,
        68.50,491.43,102.75,539.83,102.75,539.83},

        { 331.35,352.19,295.61,206.25,295.61,206.25,
        295.61,206.25,382.72,143.71,382.72,143.71,
        382.72,143.71,459.42,214.44,459.42,214.44,
        459.42,214.44,478.78,364.11,478.03,365.60,
        477.29,367.09,424.42,519.73,424.42,519.73,
        424.42,519.73,424.42,609.83,424.42,609.83,
        424.42,609.83,346.24,648.54,346.24,648.54,
        346.24,648.54,266.57,583.76,266.57,583.76,
        266.57,583.76,326.13,494.41,326.13,494.41,
        326.13,494.41,334.32,404.32,334.32,404.32 },

        { 635.14,355.17,707.37,333.58,707.37,333.58,
        707.37,333.58,766.19,286.67,766.19,286.67,
        766.19,286.67,720.77,174.98,720.77,174.98,
        720.77,174.98,644.08,124.35,644.08,124.35,
        644.08,124.35,541.32,131.05,541.32,131.05,
        541.32,131.05,565.15,166.79,565.15,166.79,
        565.15,166.79,643.33,210.72,644.08,211.47,
        644.82,212.21,662.69,271.78,662.69,271.78,
        662.69,271.78,653.76,311.99,653.76,311.99 },

        { 556.21,642.59,641.10,641.84,641.10,641.84,
        641.10,641.84,761.72,641.84,761.72,641.84,
        761.72,641.84,807.14,615.04,807.14,615.04,
        807.14,615.04,775.87,553.24,775.87,553.24,
        775.87,553.24,737.15,527.92,737.15,527.92,
        737.15,527.92,573.34,528.66,573.34,528.66,
        573.34,528.66,518.98,533.13,519.73,533.88,
        520.47,534.62,502.60,580.04,502.60,580.04,
        502.60,580.04,519.73,619.51,520.47,619.51 },

        { 207.74,357.41,186.15,218.91,186.15,218.91,
        186.15,218.91,281.46,99.03,281.46,99.03,
        281.46,99.03,459.42,154.88,459.42,154.88,
        459.42,154.88,475.80,307.52,475.80,307.52,
        475.80,307.52,601.63,412.51,601.63,412.51,
        601.63,412.51,744.60,469.10,744.60,469.10,
        744.60,469.10,822.78,639.61,822.78,639.61,
        822.78,639.61,707.37,731.19,707.37,731.19,
        707.37,731.19,539.09,675.35,539.09,675.35,
        539.09,675.35,552.49,513.77,552.49,513.77,
        552.49,513.77,423.68,437.08,423.68,437.08,
        423.68,437.08,280.71,540.58,280.71,540.58,
        280.71,540.58,172.00,492.92,172.00,492.92,
        172.00,492.92,97.54,428.14,97.54,428.14 },
    },
    tank_ospaths = {},
    time         = 0.0,         -- OOOH HACK
}

---------------------------------------------------------------------------------
-- Build poly paths for the tanks
for k,v in ipairs(gamedata.tank_paths) do 

    -- convert points to OSVec3 
    local points = {}
    local radius = 1

    local ptcount = table.getn(v) / 2 
    for i=0, ptcount - 1 do  
        local pt = Vec3Set(v[i * 2 + 1 ], 0, v[i * 2 + 2])
        points[i] = pt
    end

    local polypath = OSPathway()
    polypath.initialize( ptcount, points, radius, true )
    gamedata.tank_ospaths[k] = polypath
end

---------------------------------------------------------------------------------

local Tank = function( gameobj ) 

    local self = {}
    self.mover = OSVehicle()

    gameobj.tank_count = gameobj.tank_count + 1
    self.m_tanks    = gameobj.tanks        -- useful for collisions/avoidance
    self.m_MyID     = gameobj.tank_count

    -- // reset state
    self.reset = function() 
        self.mover.reset() -- // reset the vehicle 
        self.mover.setSpeed (2.0)         -- // speed along Forward direction.
        self.mover.setMaxForce (20.7)      -- // steering force is clipped to this magnitude
        self.mover.setMaxSpeed (2)         -- // velocity is clipped to this magnitude
        self.mover.setRadius(1.25)

        -- // Place at start of a path 
        self.allpaths = gamedata.tank_paths
        self.path = math.random(1, table.getn(self.allpaths))
        self.ospath = gamedata.tank_ospaths[self.path]
        self.pathlen = self.ospath.getTotalPathLength()

        -- Make the start point constant for a specific game module. All games will share this
        if(self.dist_start == nil) then self.dist_start = math.random(self.pathlen) end
        self.dist = self.dist_start

        local pos = self.ospath.mapPathDistanceToPoint(self.dist)
        self.mover.setPosition( Vec3Set(pos.x, 0, pos.z ) )

        local spos = vmath.vector3(pos.x, 752-pos.z, 0.5)
        self.tobj = factory.create("/tanks#tankfactory", spos, nil, {})
        msg.post(self.tobj, "tank_id", {id = self.m_MyID })
    end

    -- // per frame simulation update
    -- // (parameter names commented out to prevent compiler warning from "-W")
    self.update = function( elapsedTime) 

        if(self.tobj and go.get(self.tobj, "position")) then 
      
            self.dist = self.dist_start + elapsedTime * self.mover.speed() + 3.0
            local pos = self.ospath.mapPathDistanceToPoint(self.dist)

         local seekTarget = self.mover.xxxsteerForSeek(pos)
         self.mover.applySteeringForce (seekTarget.mult(2.0), elapsedTime)
 
--            self.mover.setPosition( Vec3Set(pos.x, 0, pos.z ) )
        end
    end

    self.reset()
    return self
end

---------------------------------------------------------------------------------
-- Create some tanks that follow some paths.
local function createTanks( gameobj )
    local tanks = {}
    gameobj.tank_count = 0
    for i=1, gamedata.max_tanks do 
        table.insert( tanks, Tank(gameobj) )
    end 
    gameobj.tanks = tanks
    gamedata.tanks = tanks
end

---------------------------------------------------------------------------------
-- Reset the tanks
local function updateTank( tid )
    local tank = gamedata.tanks[tid]
    if(tank) then 
        tank.update( gamedata.time ) 
        return tank
    end 
end

---------------------------------------------------------------------------------
-- Reset the tanks
local function resetTanks( gameobj )
    for k,tank in ipairs(gameobj.tanks) do 
        tank.reset()
    end 
end
---------------------------------------------------------------------------------

return {
    createTanks     = createTanks,
    updateTank      = updateTank,
    resetTanks      = resetTanks,

    gamedata         = gamedata,
}

---------------------------------------------------------------------------------
