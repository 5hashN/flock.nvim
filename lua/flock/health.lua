local M = {}

function M.check()
    vim.health.start("flock.nvim report")

    -- Extmarks and uv timers require modern Neovim
    if vim.fn.has("nvim-0.9.0") == 1 then
        vim.health.ok("Neovim version >= 0.9.0")
    else
        vim.health.error("Neovim >= 0.9.0 is required for uv timers and extmarks")
    end

    -- Check config initialization
    local config = require("flock.config")
    if config.options and config.options.num_boids then
        vim.health.ok("Configuration loaded successfully")
    else
        vim.health.error("Configuration failed to load properly")
    end
end

return M
