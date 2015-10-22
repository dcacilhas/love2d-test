debug = true

-- Player
player = {
    x = 200,
    y = 710,
    speed = 150,
    img = nil
}
isAlive = true
score = 0

-- Timers
canShoot = true
canShootTimerMax = 0.2
canShootTimer = canShootTimerMax
createEnemyTimerMax = 0.4
createEnemyTimer = createEnemyTimerMax

-- Image storage
bulletImg = nil
enemyImg = nil

-- Entity storage
bullets = {}
enemies = {}

-- Collision detection taken function from http://love2d.org/wiki/BoundingBox.lua
-- Returns true if two boxes overlap, false if they don't
-- x1,y1 are the left-top coords of the first box, while w1,h1 are its width and height
-- x2,y2,w2 & h2 are the same, but for the second box
function CheckCollision(x1,y1,w1,h1, x2,y2,w2,h2)
    return  x1 < x2+w2 and
            x2 < x1+w1 and
            y1 < y2+h2 and
            y2 < y1+h1
end

-- Loading
function love.load(arg)
    player.img = love.graphics.newImage('assets/img/plane.png')
    enemyImg = love.graphics.newImage('assets/img/enemy.png')
    bulletImg = love.graphics.newImage('assets/img/bullet.png')

    -- Sounds
    playerShoot = love.audio.newSource('assets/audio/shoot.wav', 'static')
    playerExplosion = love.audio.newSource('assets/audio/player_explosion.wav', 'static')
    enemyExplosion = love.audio.newSource('assets/audio/explosion.wav', 'static')
end

-- Updating
function love.update(dt)
    -- Input: Quit
    if love.keyboard.isDown('escape') then
        love.event.push('quit')
    end

    -- Input: Move left/right
    if love.keyboard.isDown('left', 'a') then
        if player.x > 0 then
            player.x = player.x - (player.speed * dt)
        end
    elseif love.keyboard.isDown('right', 'd') then
        if player.x < (love.graphics.getWidth() - player.img:getWidth()) then
            player.x = player.x + (player.speed * dt)
        end
    end

    -- Input: Move up/down
    if love.keyboard.isDown('up', 'w') then
        if player.y > 0 then
            player.y = player.y - (player.speed * dt)
        end
    elseif love.keyboard.isDown('down', 's') then
        if player.y < (love.graphics.getHeight() - player.img:getHeight()) then
            player.y = player.y + (player.speed * dt)
        end
    end

    -- Timer: Player shots
    canShootTimer = canShootTimer - (1 * dt)
    if canShootTimer < 0 then
        canShoot = true
    end

    -- Input: Shoot
    if love.keyboard.isDown(' ', 'lctrl', 'rctrl') and canShoot and isAlive then
        newBullet = {
            x = player.x + (player.img:getWidth() / 2) - (bulletImg:getWidth() / 2),
            y = player.y,
            speed = 250,
            img = bulletImg
        }
        table.insert(bullets, newBullet)
        playerShoot:play()
        canShoot = false
        canShootTimer = canShootTimerMax
    end

    -- Update: Bullet positions
    for i, bullet in ipairs(bullets) do
        bullet.y = bullet.y - (bullet.speed * dt)

        if bullet.y < 0 then
            table.remove(bullets, i)
        end
    end

    -- Timer: Enemy creation
    createEnemyTimer = createEnemyTimer - (1 * dt)
    if createEnemyTimer < 0 then
        createEnemyTimer = createEnemyTimerMax

        rnd = math.random(10, love.graphics.getWidth() - enemyImg:getWidth())
        newEnemy = {
            x = rnd,
            y = -enemyImg:getHeight(),
            speed = 200,
            img = enemyImg
        }
        table.insert(enemies, newEnemy)
    end

    -- Update: Enemy position
    for i, enemy in ipairs(enemies) do
        enemy.y = enemy.y + (enemy.speed * dt)

        if enemy.y > love.graphics.getHeight() then
            table.remove(enemies, i)
        end
    end

    -- Collision detection
    for i, enemy in ipairs(enemies) do
        for j, bullet in ipairs(bullets) do
            -- Collision: Enemy/bullet
            if CheckCollision(  enemy.x, enemy.y, enemy.img:getWidth(), enemy.img:getHeight(),
                                bullet.x, bullet.y, bullet.img:getWidth(), bullet.img:getHeight()) then
                table.remove(bullets, j)
                table.remove(enemies, i)
                enemyExplosion:play()
                score = score + 1
            end
        end

        -- Collision: Enemy/player
        if CheckCollision(  enemy.x, enemy.y, enemy.img:getWidth(), enemy.img:getHeight(),
                                player.x, player.y, player.img:getWidth(), player.img:getHeight()) 
        and isAlive then
            table.remove(enemies, i)
            playerExplosion:play()
            isAlive = false
        end
    end

    -- Restart game
    if not isAlive and love.keyboard.isDown('r') then
        bullets = {}
        enemies = {}

        canShootTimer = canShootTimerMax
        createEnemyTimer = createEnemyTimerMax

        player.x = 200
        player.y = 710

        isAlive = true
        score = 0
    end
end

-- Drawing
function love.draw(dt)
    for i, bullet in ipairs(bullets) do
        love.graphics.draw(bullet.img, bullet.x, bullet.y)
    end

    for i, enemy in ipairs(enemies) do
        love.graphics.draw(enemy.img, enemy.x, enemy.y)
    end

    love.graphics.print('Score: ' .. score, 10, 10)

    if isAlive then
        love.graphics.draw(player.img, player.x, player.y)
    else
        love.graphics.print('Press "R" to restart', love.graphics:getWidth() / 2 - 50, love.graphics:getHeight() / 2 - 10)
    end

    if debug then
        fps = tostring(love.timer.getFPS())
        love.graphics.print('FPS: ' .. fps, love.graphics:getWidth() - 60, 10)
    end
end