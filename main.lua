-- Require the dkjson library
json = require("lib.dkjson")  -- Adjusting the path to the lib/dkjson.lua file

-- Define the global variables for high scores and player
highScores = {}

function love.load()
    -- Set the game title
    love.window.setTitle("Avoiders")

    -- Seed the random number generator
    math.randomseed(os.time())

    -- Initialize player object
    player = {}
    player.x = love.graphics.getWidth() / 2  -- Player start X position
    player.y = love.graphics.getHeight() - 100  -- Player start Y position
    player.width = 50  -- Player width (modify as per image size)
    player.height = 50  -- Player height (modify as per image size)
    player.image = love.graphics.newImage("assets/Player.png")  -- Load player image
    player.health = 3  -- Starting health
    playerName = ""  -- Initialize player name for leaderboard

    -- Initialize the obstacles table
    obstacles = {}

    -- Points system
    points = 0

    -- Load assets
    enemyImage = love.graphics.newImage("assets/Enemy.png")
    logoImage = love.graphics.newImage("assets/Logo.png")  -- Load logo image

    -- Adjust logo size (75% smaller)
    logoScale = 0.25  -- 75% smaller (0.25 is 25% of the original size)

    -- Load high scores
    loadHighScores()

    -- Set initial game state
    gameState = "title"  -- Title screen state initially

    -- Reset player state
    resetGame()
end

function love.update(dt)
    if gameState == "play" then
        -- Move the player
        if love.keyboard.isDown("left") then
            player.x = player.x - 5
        elseif love.keyboard.isDown("right") then
            player.x = player.x + 5
        end

        -- Create random obstacles
        if math.random() < 0.01 then
            table.insert(obstacles, {x = math.random(0, love.graphics.getWidth() - 50), y = 0, width = 50, height = 50})
        end

        -- Update obstacle positions
        for i, obs in ipairs(obstacles) do
            obs.y = obs.y + 5
            -- Check for collisions with player
            if player.x < obs.x + obs.width and
               player.x + player.width > obs.x and
               player.y < obs.y + obs.height and
               player.y + player.height > obs.y then
                player.health = player.health - 1  -- Lose health on collision
                table.remove(obstacles, i)  -- Remove the obstacle
            end
        end

        -- Remove obstacles that go off screen
        for i = #obstacles, 1, -1 do
            if obstacles[i].y > love.graphics.getHeight() then
                table.remove(obstacles, i)
                points = points + 1  -- Earn a point for dodging
            end
        end

        -- Check for game over
        if player.health <= 0 then
            gameState = "gameover"
        end
    end
end

function love.draw()
    if gameState == "title" then
        -- Title Screen
        love.graphics.setColor(1, 1, 1) -- White

        -- Calculate the position to center the logo at the top
        local logoWidth = logoImage:getWidth() * logoScale
        local logoHeight = logoImage:getHeight() * logoScale
        local logoX = (love.graphics.getWidth() - logoWidth) / 2
        local logoY = 50  -- Place it at the top of the screen

        -- Draw the logo with the new size and position
        love.graphics.draw(logoImage, logoX, logoY, 0, logoScale, logoScale)

        love.graphics.printf("Press Enter to Start", 0, 200, 800, "center")
        love.graphics.printf("Press R to Reset High Scores", 0, 250, 800, "center")

        -- Display Leaderboard
        love.graphics.printf("Leaderboard:", 0, 350, 800, "center")
        for i, entry in ipairs(highScores) do
            love.graphics.printf(i .. ". " .. entry.name .. " - " .. entry.score, 0, 350 + i * 20, 800, "center")
        end
    elseif gameState == "play" then
        -- Draw the Player
        love.graphics.draw(player.image, player.x, player.y)

        -- Draw the Obstacles (Enemies)
        for i, obs in ipairs(obstacles) do
            love.graphics.draw(enemyImage, obs.x, obs.y)
        end

        -- Draw the Score and Health
        love.graphics.setColor(1, 1, 1) -- White color
        love.graphics.print("Points: " .. points, 10, 10)
        love.graphics.print("Health: " .. player.health, 10, 30)
    elseif gameState == "gameover" then
        -- Game Over Screen
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Game Over", 0, 100, 800, "center")
        love.graphics.printf("Final Score: " .. points, 0, 150, 800, "center")
        love.graphics.printf("Enter Your Name: " .. playerName, 0, 200, 800, "center")
        love.graphics.printf("Press Enter to Submit", 0, 250, 800, "center")

        -- Display Leaderboard
        love.graphics.printf("Leaderboard:", 0, 350, 800, "center")
        for i, entry in ipairs(highScores) do
            love.graphics.printf(i .. ". " .. entry.name .. " - " .. entry.score, 0, 350 + i * 20, 800, "center")
        end
    end
end

function love.keypressed(key)
    if gameState == "title" then
        if key == "return" then
            gameState = "play"  -- Start the game
        elseif key == "r" then
            resetHighScores()  -- Reset the high scores
        end
    elseif gameState == "gameover" then
        if key == "return" then
            -- Submit the score and name
            addHighScore(playerName, points)
            saveHighScores()
            gameState = "title"  -- Go back to the title screen
            resetGame()  -- Reset the game
        end
    end
end

-- Load high scores from the file
function loadHighScores()
    local filename = "highscore.json"
    local file = love.filesystem.read(filename)
    if file then
        highScores = json.decode(file) or {}  -- Use json.decode instead of love.filesystem.decode
    end
end

-- Save high scores to the file
function saveHighScores()
    local file = json.encode(highScores)  -- Use json.encode instead of love.filesystem.encode
    love.filesystem.write("highscore.json", file)
end

-- Reset high scores
function resetHighScores()
    highScores = {}
    saveHighScores()  -- Save the empty high scores
end

-- Add a high score to the leaderboard
function addHighScore(name, score)
    table.insert(highScores, {name = name, score = score})
    table.sort(highScores, function(a, b) return a.score > b.score end)
    if #highScores > 5 then
        table.remove(highScores, #highScores)  -- Keep only top 5 scores
    end
end

-- Reset the game state
function resetGame()
    player.x = love.graphics.getWidth() / 2
    player.y = love.graphics.getHeight() - 100
    player.health = 3
    playerName = ""
    points = 0
    obstacles = {}
end