if vim.g.loaded_flock == 1 then
    return
end
vim.g.loaded_flock = 1

local flock = require("flock")

vim.api.nvim_create_user_command("FlockStart", flock.start, { desc = "Start the Boids flocking simulation" })
vim.api.nvim_create_user_command("FlockStop", flock.stop, { desc = "Stop the Boids flocking simulation" })
