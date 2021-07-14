local log = require('telescope.log')

local async_job = R('plenary.async_job')
local LinesPipe = R('plenary.async_job.pipes').LinesPipe

local make_entry = require('telescope.make_entry')

return function(opts)
  local entry_maker = opts.entry_maker or make_entry.gen_from_string()
  local fn_command = function(prompt)
    local command_list = opts.command_generator(prompt)
    if command_list == nil then
      return nil
    end

    local command = table.remove(command_list, 1)

    return {
      command = command,
      args = command_list,
    }
  end

  local job
  return setmetatable({
    close = function() 
      if job then
        job:close()
      end
    end,
  }, {
    __call = function(_, prompt, process_result, process_complete)
      if job then
        job:close()
      end

      local job_opts = fn_command(prompt)
      if not job_opts then return end

      -- local writer = nil
      -- if job_opts.writer and Job.is_job(job_opts.writer) then
      --   writer = job_opts.writer
      -- elseif opts.writer then
      --   writer = Job:new(job_opts.writer)
      -- end

      local stdout = LinesPipe()

      job = async_job.spawn {
        command = job_opts.command,
        args = job_opts.args,
        cwd = job_opts.cwd or opts.cwd,
        -- writer = writer,

        stdout = stdout,
      }

      for line in stdout:iter() do
        if process_result(entry_maker(line)) then
          return
        end
      end

      process_complete()
    end,
  })
end
