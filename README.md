# flock.nvim

A Boids flocking simulator that runs directly inside your Neovim buffers using virtual text. The boids swarm around your code and are attracted to your cursor.

It utilizes uniform grid spatial partitioning to handle the n-body kinematics.

https://github.com/user-attachments/assets/6e033994-4d54-4af3-89fb-0f87da803db8

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
