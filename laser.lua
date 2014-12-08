require "vector"
require "effects"

Laser = {}

function Laser:new( pos, dir, color )
    local l = {}
    setmetatable( l, self )
    self.__index = self

    l.pos = pos:copy()
    l.dir = dir:normalize()
    l.color = color or { 64, 255, 64 }
    l.w = 24
    l.h = 4

    return l
end

function Laser:draw()
    love.graphics.push()
    love.graphics.translate( self.pos.x, self.pos.y )
    love.graphics.rotate( self.dir:angle() )

    love.graphics.setColor( self.color )
    love.graphics.rectangle( "fill", -self.w/2, -self.h/2, self.w, self.h )
    if self.debugText ~= nil then
        love.graphics.setColor( 255, 255, 255 )
        love.graphics.printf( self.debugText, -self.w/2, -self.h*4, self.w, "left", 0, love.window.getPixelScale(), love.window.getPixelScale() )
    end

    love.graphics.pop()
end

function Laser:die()
    -- remove this laser from the lasers array
    for i, l in ipairs( lasers ) do
        if l == self then
            table.remove( lasers, i )
        end
    end
end

function Laser:update( dt, i )
    self.pos = self.pos:add( self.dir:multiply( LASER_VEL * dt ) )

    for j, o in ipairs( lasers ) do
        -- All lasers except this one
        if i ~= j and not o.sparks then
            if self:colliding( o ) then
                self:die()
                o:die()

                effects[#effects + 1] = Spark:new( self.pos, self.dir, combineColors( self.color, o.color ) )
                -- TODO: Sound effects?

                -- TODO: spawn enemy/powerup
                return
            end
        end
    end

    -- Wall collisions
    if self.pos.x < 0 then
        self.dir = self.dir:reflect( Vector:new( 1, 0 ) )
        self.pos.x = math.max( self.pos.x, 0 )
    elseif self.pos.x > W then
        self.dir = self.dir:reflect( Vector:new( -1, 0 ) )
        self.pos.x = math.min( self.pos.x, W )
    elseif self.pos.y < 0 then
        self.dir = self.dir:reflect( Vector:new( 0, 1 ) )
        self.pos.y = math.max( self.pos.y, 0 )
    elseif self.pos.y > H then
        self.dir = self.dir:reflect( Vector:new( 0, -1 ) )
        self.pos.y = math.min( self.pos.y, H )
    end
end

function Laser:colliding( o )
    -- This collision detection is very sloppy, but it's good enough for now
    -- TODO: Make this more accurate

    local distVector = o.pos:subtract( self.pos )
    local dist = distVector:length()
    return dist < self.w/2
end

