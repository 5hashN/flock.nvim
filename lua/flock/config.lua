local M = {}

M.defaults = {
    num_boids = 40,
    dt = 0.1,
    timer_interval = 50, -- millisec
    visual_char = ">",
    hl_group = "String",
    weights = {
        separation = 4,
        alignment = 1.0,
        cohesion = 0.8,
        cursor = 0.6,
    },
    perception_radius = 12.0,
    max_speed = 2.5,
}

M.options = {}

function M.setup(user_opts)
    M.options = vim.tbl_deep_extend("force", M.defaults, user_opts or {})
end

return M
