local config = require("flock.config")
local M = {}

local boids = {}
local timer = nil
local ns_id = vim.api.nvim_create_namespace("flock_namespace")

local function init_boids()
    boids = {}
    local width = vim.api.nvim_win_get_width(0)
    local height = vim.api.nvim_win_get_height(0)

    for _ = 1, config.options.num_boids do
        table.insert(boids, {
            x = math.random() * width,
            y = math.random() * height,
            vx = (math.random() - 0.5) * 2,
            vy = (math.random() - 0.5) * 2,
        })
    end
end

local function build_grid()
    local grid = {}
    local cell_size = config.options.perception_radius

    for _, b in ipairs(boids) do
        local cx = math.floor(b.x / cell_size)
        local cy = math.floor(b.y / cell_size)
        local key = cx .. "," .. cy

        if not grid[key] then
            grid[key] = {}
        end
        table.insert(grid[key], b)
    end

    return grid, cell_size
end

local function update_kinematics()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local target_y = cursor[1] - 1
    local target_x = cursor[2]

    local width = vim.api.nvim_win_get_width(0)
    local height = vim.api.nvim_win_get_height(0)

    local grid, cell_size = build_grid()

    local grid_cols = math.ceil(width / cell_size)
    local grid_rows = math.ceil(height / cell_size)

    for _, b in ipairs(boids) do
        local sep_x, sep_y = 0, 0
        local align_x, align_y = 0, 0
        local coh_x, coh_y = 0, 0
        local total_neighbors = 0

        local bcx = math.floor(b.x / cell_size)
        local bcy = math.floor(b.y / cell_size)

        -- Spatial partition lookup
        for dx = -1, 1 do
            for dy = -1, 1 do
                local nx = (bcx + dx) % grid_cols
                local ny = (bcy + dy) % grid_rows
                local neighbor_key = nx .. "," .. ny

                local cell_boids = grid[neighbor_key]
                if cell_boids then
                    for _, other in ipairs(cell_boids) do
                        if b ~= other then
                            local dx_pos = other.x - b.x
                            local dy_pos = other.y - b.y

                            -- Standardize distance
                            if dx_pos > width / 2 then
                                dx_pos = dx_pos - width
                            end
                            if dx_pos < -width / 2 then
                                dx_pos = dx_pos + width
                            end
                            if dy_pos > height / 2 then
                                dy_pos = dy_pos - height
                            end
                            if dy_pos < -height / 2 then
                                dy_pos = dy_pos + height
                            end

                            local dist = math.sqrt(dx_pos ^ 2 + dy_pos ^ 2)

                            if dist < config.options.perception_radius and dist > 0 then
                                local push_strength = 1.0 / dist
                                sep_x = sep_x - (dx_pos / dist) * push_strength
                                sep_y = sep_y - (dy_pos / dist) * push_strength

                                align_x = align_x + other.vx
                                align_y = align_y + other.vy

                                coh_x = coh_x + other.x
                                coh_y = coh_y + other.y

                                total_neighbors = total_neighbors + 1
                            end
                        end
                    end
                end
            end
        end

        local ax, ay = 0, 0

        if total_neighbors > 0 then
            align_x = (align_x / total_neighbors) - b.vx
            align_y = (align_y / total_neighbors) - b.vy

            coh_x = (coh_x / total_neighbors) - b.x
            coh_y = (coh_y / total_neighbors) - b.y

            ax = (sep_x * config.options.weights.separation)
                + (align_x * config.options.weights.alignment)
                + (coh_x * config.options.weights.cohesion)
        end

        -- Cursor attractor logic
        local dx_cursor = target_x - b.x
        local dy_cursor = target_y - b.y

        if dx_cursor > width / 2 then
            dx_cursor = dx_cursor - width
        end
        if dx_cursor < -width / 2 then
            dx_cursor = dx_cursor + width
        end
        if dy_cursor > height / 2 then
            dy_cursor = dy_cursor - height
        end
        if dy_cursor < -height / 2 then
            dy_cursor = dy_cursor + height
        end

        local dist_cursor = math.sqrt(dx_cursor ^ 2 + dy_cursor ^ 2)

        if dist_cursor > 0 then
            local norm_dx = dx_cursor / dist_cursor
            local norm_dy = dy_cursor / dist_cursor

            ax = ax + (norm_dx * config.options.weights.cursor)
            ay = ay + (norm_dy * config.options.weights.cursor)
        end

        -- Euler Stepper
        b.vx = b.vx + (ax * config.options.dt)
        b.vy = b.vy + (ay * config.options.dt)

        local speed = math.sqrt(b.vx ^ 2 + b.vy ^ 2)
        if speed > config.options.max_speed then
            b.vx = (b.vx / speed) * config.options.max_speed
            b.vy = (b.vy / speed) * config.options.max_speed
        end

        b.x = b.x + (b.vx * config.options.dt)
        b.y = b.y + (b.vy * config.options.dt)

        -- Wrap coords to window
        b.x = b.x % width
        b.y = b.y % height
    end
end

local function render()
    local buf = vim.api.nvim_get_current_buf()
    local line_count = vim.api.nvim_buf_line_count(buf)

    -- Clear previous frame extmarks
    vim.api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)

    for _, b in ipairs(boids) do
        local row = math.floor(b.y)
        local col = math.floor(b.x)

        -- Check for boundaries
        if row >= 0 and row < line_count and col >= 0 then
            local char = config.options.visual_char
            if math.abs(b.vx) > math.abs(b.vy) then
                char = b.vx > 0 and ">" or "<"
            else
                char = b.vy > 0 and "v" or "^"
            end

            pcall(vim.api.nvim_buf_set_extmark, buf, ns_id, row, col, {
                virt_text = { { char, config.options.hl_group } },
                virt_text_pos = "overlay",
                hl_mode = "combine",
            })
        end
    end
end

function M.setup(opts)
    config.setup(opts)
end

function M.start()
    if timer then
        return
    end

    init_boids()
    timer = vim.uv.new_timer()

    timer:start(
        0,
        config.options.timer_interval,
        vim.schedule_wrap(function()
            update_kinematics()
            render()
        end)
    )
end

function M.stop()
    if timer then
        timer:stop()
        timer:close()
        timer = nil
    end
    local buf = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)
end

return M
