Ball = Class{}

function Ball:init(x, y, width, height)
    self.x = x
    self.y = y
    self.width = width
    self.height = height

    -- these variables are for keeping track of our velocity on both the X and Y axis, since the ball can move in two dimensions
    -- ballX and ballY change based on their relative velocity (DX and DY)
    -- added to our position every frame to make a linear trajectory that changes every time the ball is hit 
    -- start with no movement
    self.dx = 0
    self.dy = 0
end

function Ball:collides(paddle)
    -- checks left paddle or right paddle, respectively
    -- if the paddle is left paddle, the ball should be to the right of its x + width to avoid collision
    -- if the paddle is right paddle, the entire ball should be to the left of its x to avoid collision
    if self.x > (paddle.x + paddle.width) or paddle.x > (self.x + self.width) then
        return false
    end

    -- checks for paddle being above or below ball, respectively
    -- if the paddle is above the ball, the ball should be below its y + height to avoid collision
    -- if the paddle is below the ball, the entire ball should be above its y to avoid collision
    if self.y > (paddle.y + paddle.height) or paddle.y > (self.y + self.height) then
        return false
    end

    -- otherwise, there is collision
    return true
end

function Ball:reset()
    -- place in middle of screen with no movement
    self.x = VIRTUAL_WIDTH / 2 - 2
    self.y = VIRTUAL_HEIGHT / 2 - 2
    self.dx = 0
    self.dy = 0
end

function Ball:update(dt)
    self.x = self.x + self.dx * dt
    self.y = self.y + self.dy * dt
end

function Ball:render()
    love.graphics.rectangle('fill', self.x, self.y, self.width, self.height)
end