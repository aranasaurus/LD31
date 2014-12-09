require "vector"

Spark = {}

function Spark:new( pos, dir, color, decay, length, density )
    local e = {}
    setmetatable( e, self )
    self.__index = self

    e.pos = pos:copy()
    e.dir = dir:copy()
    e.length = length or 6
    e.density = density or 12
    e.color = color or { 255, 255, 255 }
    e.alpha = 255
    e.decay = decay or 255/45

    e.sparks = {}
    local angle = (2 * math.pi) / e.density
    for i = 1, e.density do
        local s = {
            pos = Vector:new( 0, 0 ),
            vel = e.dir:rotate( angle * i ),
        }

        e.sparks[i] = s
    end
    return e
end

function Spark:update( dt )
    self.alpha = self.alpha - self.decay
    for i, s in ipairs( self.sparks ) do
        s.pos = s.pos:add( s.vel:multiply( LASER_VEL * 0.66 * dt ) )
    end
end

function Spark:draw()
    love.graphics.push()
    love.graphics.translate( self.pos.x, self.pos.y )

    for i, s in ipairs( self.sparks ) do
        love.graphics.push()

        love.graphics.setColor( self.color[1], self.color[2], self.color[3], self.alpha )
        local l = s.vel:multiply( self.length )
        local p1 = s.pos:subtract( l )
        local p2 = s.pos:add( l )
        love.graphics.setLineWidth( 1 )
        love.graphics.line( p1.x, p1.y, p2.x, p2.y )

        love.graphics.pop()
    end

    love.graphics.pop()
end

-----------
-- Utils --
-----------

function combineColors( c1, c2 )
    local cmyk1 = rgbaToCmyk( c1 )
    local cmyk2 = rgbaToCmyk( c2 )

    local cmyk = {
        c = (cmyk1.c + cmyk2.c) / 2,
        m = (cmyk1.m + cmyk2.m) / 2,
        y = (cmyk1.y + cmyk2.y) / 2,
        k = (cmyk1.k + cmyk2.k) / 2,
        a = math.max( c1[4] or 255, c2[4] or 255 )
    }
    return cmykToRgba( cmyk )
end

function rgbaToCmyk( rgba )
    local cmyk = { c = 0, y = 0, m = 0, k = 0 }

    cmyk.c = 255 - rgba[1]
    cmyk.m = 255 - rgba[2]
    cmyk.y = 255 - rgba[3]
    cmyk.k = math.min( cmyk.c, cmyk.m, cmyk.y )

    cmyk.c = ((cmyk.c - cmyk.k) / (255 - cmyk.k))
    cmyk.m = ((cmyk.m - cmyk.k) / (255 - cmyk.k))
    cmyk.y = ((cmyk.y - cmyk.k) / (255 - cmyk.k))
    cmyk.k = cmyk.k/255
    cmyk.a = rgba[4]

    return cmyk
end

function cmykToRgba( cmyk )
    local r = cmyk.c * (1 - cmyk.k) + cmyk.k
    local g = cmyk.m * (1 - cmyk.k) + cmyk.k
    local b = cmyk.y * (1 - cmyk.k) + cmyk.k
    r = math.ceil( (1 - r) * 255 )
    g = math.ceil( (1 - g) * 255 )
    b = math.ceil( (1 - b) * 255 )

    return { r, g, b, cmyk.a }
end

function shipExplosion( ship, density, decay )
    local density = density or 16
    local decay = decay or 255/25
    effects[#effects + 1] = Spark:new( ship.pos, ship.dir, ship.color, decay/2, 12, 48 )
    for i = 1, density do
        local c = ship.laserColors[love.math.random( 1, #ship.laserColors )]
        local dec = love.math.random() * decay
        local len = love.math.random( 4, 16 )
        local dens = love.math.random( 6, 32 )
        effects[#effects + 1] = Spark:new( ship.pos, randomDir( ship.dir ), c, dec, len, dens )
    end
end

function randomDir( dir )
    return dir:multiply( love.math.random() + 1 ):rotate( love.math.random( 2 * math.pi ) )
end
