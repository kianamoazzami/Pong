Paddle = Class{}

function Paddle:init(x, y, width, height)
    -- pass in dimensions and position of paddle being created
    -- paddle starts with no movement
    self.x = x
    self.y = y
    self.width = width
    self.height = height
    self.dy = 0
end

function Paddle:update(dt)
    if self.dy < 0 then
        -- prevents paddle from going past the top edge of the screen
        self.y = math.max(0, self.y + self.dy * dt)
    else
        -- prevents paddle from going past the bottom edge of the screen with min
        self.y = math.min(VIRTUAL_HEIGHT - self.height, self.y + self.dy * dt)
    end
end

function Paddle:render()
    love.graphics.rectangle('fill', self.x, self.y, self.width, self.height)
end