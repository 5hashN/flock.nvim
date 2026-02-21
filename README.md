# flock.nvim

A Boids flocking simulator that runs directly inside your Neovim buffers using virtual text. The boids swarm around your code and are attracted to your cursor.

It utilizes uniform grid spatial partitioning to handle the n-body kinematics.

https://github.com/5hashN/flock.nvim/raw/main/assets/demo.mp4

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
    "5hashN/flock.nvim",
    opts = {
        num_boids = 40,
        timer_interval = 50,
        visual_char = ">",
    }
}
