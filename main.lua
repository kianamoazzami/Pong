-- get library - push
-- push our window into a virtual resolution to keep window size but pixelate
Push = require 'push'

-- get library - class
-- allows for the uses of classes
Class = require 'class'

require 'Paddle'
require 'Ball'

-- save window actual width and height in constants
WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720 

-- save virtual window width and height in constants (for push library)
VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243

-- speed which we will move our paddle; multiplied by dt (how many seconds have passed since last frame) in update
-- therefore moves same distance over time no matter frame rate 
PADDLE_SPEED = 200;

-- override love.load()
function love.load()
    -- change default filter from bilinear to nearest (nearest pixel)
    love.graphics.setDefaultFilter('nearest', 'nearest')
    love.window.setTitle('Pong');

    -- "seed" the random num generator so that calls to random are always random 
    -- use the current time since that will vary on startup every time
    math.randomseed(os.time())

    -- init fonts with different sizes
    smallFont = love.graphics.newFont('font.ttf', 8)
    scoreFont = love.graphics.newFont('font.ttf', 32) -- biggest font for score
    largeFont = love.graphics.newFont('font.ttf', 16)

    -- set current font
    love.graphics.setFont(smallFont)

    -- sound effects table
    sfx = { 
        ['paddle_hit'] = love.audio.newSource('sounds/paddle_hit.wav', 'static'),
        ['score'] = love.audio.newSource('sounds/score.wav', 'static'),
        ['wall_hit'] = love.audio.newSource('sounds/wall_hit.wav', 'static')
    }

    -- init a lower virtual resolution for retro look
    Push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        resizable = true,
        vsync = true
    })

    -- init number of players (can be 1 or 2)
    numPlayers = 1

    -- init the score variables 
    player1Score = 0
    player2Score = 0

    -- init paddles 
    player1 = Paddle(10, 30, 5, 20)
    player2 = Paddle(VIRTUAL_WIDTH - 10, VIRTUAL_HEIGHT - 30, 5, 20)

    -- init ball in middle of screen
    ball = Ball(VIRTUAL_WIDTH / 2 - 2, VIRTUAL_HEIGHT / 2 - 2, 4, 4)

    -- init serving player (1 or 2) and winning player (0 becuase no winner yet)
    servingPlayer = 1
    winningPlayer = 0

    -- game state variable used to transition between different parts of the game 
    -- menu, main game, high score list, etc
    -- we use this to determine the behaviour during render (draw) and update
    -- we can use a state machine for this in the future 

    -- state can be one of the following: start, serve, play, or done
    gameState = 'start'

end

-- override love.resize() to allow push library to handle resizing 
function love.resize(w, h)
    Push:resize(w, h)
end

-- override love.draw() (called after update by LOVE2D)
function love.draw()
    -- start rendering at the virtual resolution
    Push:apply('start')

    -- set background colour 
    love.graphics.clear(239/255, 207/255, 227/255, 255/255)

    -- display score all the time
    love.graphics.setFont(scoreFont)
    love.graphics.print(tostring(player1Score), VIRTUAL_WIDTH / 2 - 50, VIRTUAL_HEIGHT / 3)
    love.graphics.print(tostring(player2Score), VIRTUAL_WIDTH / 2 + 30, VIRTUAL_HEIGHT / 3)

    -- display other text depending on state
    if gameState == 'start' then
         love.graphics.setFont(smallFont)
         love.graphics.printf('Pong', 0, 10, VIRTUAL_WIDTH, 'center')
         love.graphics.printf('Select number of players on keyboard: 1 or 2', 0, 20, VIRTUAL_WIDTH, 'center') 
    elseif gameState == 'serve' then
        love.graphics.setFont(smallFont)
        love.graphics.printf('Player ' .. tostring(servingPlayer) .. "'s serve", 0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('Press Enter to serve', 0, 20, VIRTUAL_WIDTH, 'center')
    elseif gameState == 'done' then
        love.graphics.setFont(largeFont)
        love.graphics.printf('Player ' .. tostring(winningPlayer) .. ' wins!', 0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.setFont(smallFont)
        love.graphics.printf('Press Enter to restart', 0, 30, VIRTUAL_WIDTH, 'center')
    end

    -- render paddles using their class render method
    player1:render()
    player2:render()

    -- render ball using its class render method
    ball:render()

    -- FPS on screen for debugging 
    displayFPS()

    -- stop rendering at the virtual resolution (anything written after this is in window res)
    Push:apply('end')
end

-- when a key is pressed, this function is called
function love.keypressed(key)
    -- choose number of players
    if gameState == 'start' then 
        if key == '1' then
            numPlayers = 1
            gameState = 'serve'
        elseif key == '2' then
            numPlayers = 2
            gameState = 'serve'
        end
    end

    if key == 'escape' then 
        -- terminate app
        love.event.quit()
    elseif key == 'enter' or key == 'return' then
        if gameState == 'serve' then
            gameState = 'play'
        elseif gameState == 'done' then
            -- restart game
            gameState = 'start'
        
            player1Score = 0
            player2Score = 0

            -- player who lost will serve 
            if winningPlayer == 1 then
                servingPlayer = 2
            else
                servingPlayer = 1
            end

            ball:reset()
        end
    end
end

function love.update(dt)
    handleState()

    -- player 1 movement
    if love.keyboard.isDown('w') then
        player1.dy = -PADDLE_SPEED
    elseif love.keyboard.isDown('s') then
        player1.dy = PADDLE_SPEED
    else
        player1.dy = 0
    end

    -- player 2 movement (dependent on number of players)
    if numPlayers == 1 and gameState == 'play' then
        -- center of paddle follows the y position of the ball
        -- slower speed allows for player 2 to lose sometimes when speed of ball is high
        if ball.y < (player2.y + player2.height / 2) then
            player2.dy = -PADDLE_SPEED * 0.45
        elseif ball.y > (player2.y + player2.height / 2) then
            player2.dy = PADDLE_SPEED * 0.45
        else
            player2.dy = 0
        end
    elseif numPlayers == 2 then 
        if love.keyboard.isDown('up') then
            player2.dy = -PADDLE_SPEED
        elseif love.keyboard.isDown('down') then
            player2.dy = PADDLE_SPEED
        else
            player2.dy = 0
        end
    end 

    -- update ball but only if we are in play state 
    if gameState == 'play' then
        ball:update(dt)
    end

    player1:update(dt)
    player2:update(dt)
end

function displayFPS()
    love.graphics.setFont(smallFont)
    love.graphics.setColor(0, 255, 0, 255) 
    love.graphics.print('FPS: ' .. tostring(love.timer.getFPS()), 10, 10)
end

function handleState() 
    if gameState == 'serve' then 
        -- randomize velocity
        ball.dy = math.random(-50, 50)

        -- x component is serving-player dependent 
        if servingPlayer == 1 then
            ball.dx = math.random(100, 200)
        else
            ball.dx = -math.random(100, 200)
        end
    elseif gameState == 'play' then
        updatePlay()
    end
end

function updatePlay() 
    -- detect paddle collision  
    if ball:collides(player1) then
        -- reposition ball in front of paddle 
        ball.x = player1.x + 5
        onPaddleCollision()
    elseif ball:collides(player2) then
        -- reposition ball in front of paddle 
        ball.x = player2.x - 4
        onPaddleCollision()
    end

    -- detect upper and lower edge screen collision
    if ball.y <= 0 then
        -- reposition ball and reverse velocity 
        ball.y = 0
        ball.dy = -ball.dy
        -- play wall hit sound
        sfx['wall_hit']:play()
    elseif ball.y >= (VIRTUAL_HEIGHT - 4) then
        -- reposition ball and reverse velocity 
        ball.y = VIRTUAL_HEIGHT - 4
        ball.dy = -ball.dy
        -- play wall hit sound
        sfx['wall_hit']:play()
    end

    -- detect ball passing through left or right edges of screen
    if ball.x < 0 then 
        -- player who lost round will serve
        servingPlayer = 1
        player2Score = player2Score + 1
        onPlayerScore(2)
    elseif ball.x > VIRTUAL_WIDTH then
        -- player who lost round will serve
        servingPlayer = 2
        player1Score = player1Score + 1
        onPlayerScore(1)
    end
end 

function onPaddleCollision()
    -- reverse x direction and slightly increase speed
    ball.dx = -ball.dx * 1.03

    -- keep y direction and randomize speed
    if ball.dy < 0 then
        ball.dy = -math.random(10, 150)
    else
        ball.dy = math.random(10, 150)
    end

    -- play paddle hit sound
    sfx['paddle_hit']:play()
end

function onPlayerScore(playerNum)
    -- play score sound 
    sfx['score']:play()

    -- first player to 10 will win the whole game
    if player1Score == 10 or player2Score == 10 then
        winningPlayer = playerNum
        gameState = 'done'
    else
        -- game is not done; start a new round
        gameState = 'serve'
        ball:reset()
    end
end