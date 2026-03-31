-- Resolve import paths for `gf`.
-- Handles:
--   SvelteKit $-prefixed aliases ($lib, $entities, etc.)
--   Go module-local imports (strips module prefix from go.mod)

local M = {}

--- Cache of alias mappings per project root, keyed by sveltekit tsconfig path.
---@type table<string, table<string, string>>
local alias_cache = {}

--- Cache of Go module prefixes, keyed by go.mod path.
---@type table<string, string>
local gomod_cache = {}

--- Find the nearest ancestor directory containing the given marker file/dir.
---@param start string starting directory
---@param marker string file or directory name to look for
---@return string|nil
local function find_root(start, marker)
  local dir = start
  while dir and dir ~= "/" do
    if vim.uv.fs_stat(dir .. "/" .. marker) then
      return dir
    end
    dir = vim.fn.fnamemodify(dir, ":h")
  end
end

--- Load $-alias mappings from the nearest .svelte-kit/tsconfig.json.
---@param bufdir string directory of the current buffer
---@return table<string, string> map of alias prefix -> resolved directory
local function load_sveltekit_aliases(bufdir)
  local pkg_root = find_root(bufdir, ".svelte-kit")
  if not pkg_root then return {} end

  local tsconfig_path = pkg_root .. "/.svelte-kit/tsconfig.json"
  if alias_cache[tsconfig_path] then
    return alias_cache[tsconfig_path]
  end

  local ok, content = pcall(vim.fn.readfile, tsconfig_path)
  if not ok then
    alias_cache[tsconfig_path] = {}
    return {}
  end

  local text = table.concat(content, "\n")
  local parsed_ok, tsconfig = pcall(vim.json.decode, text)
  if not parsed_ok or not tsconfig.compilerOptions or not tsconfig.compilerOptions.paths then
    alias_cache[tsconfig_path] = {}
    return {}
  end

  local aliases = {}
  local sveltekit_dir = pkg_root .. "/.svelte-kit"

  for alias, targets in pairs(tsconfig.compilerOptions.paths) do
    if not alias:find("%*") and #targets > 0 then
      local target = targets[1]
      local resolved = vim.fn.simplify(sveltekit_dir .. "/" .. target)
      aliases[alias] = resolved
    end
    if alias:find("/%*$") and #targets > 0 then
      local prefix = alias:gsub("/%*$", "")
      local target = targets[1]:gsub("/%*$", "")
      local resolved = vim.fn.simplify(sveltekit_dir .. "/" .. target)
      aliases[prefix] = resolved
    end
  end

  alias_cache[tsconfig_path] = aliases
  return aliases
end

--- Resolve a SvelteKit import path.
---@param path string
---@return string
function M.resolve(path)
  path = path:gsub("^['\"]", ""):gsub("['\";]$", "")

  if not path:match("^%$") then
    return path
  end

  local bufdir = vim.fn.expand("%:p:h")
  local aliases = load_sveltekit_aliases(bufdir)

  local best_prefix, best_dir = nil, nil
  for prefix, dir in pairs(aliases) do
    if path == prefix or path:sub(1, #prefix + 1) == prefix .. "/" then
      if not best_prefix or #prefix > #best_prefix then
        best_prefix = prefix
        best_dir = dir
      end
    end
  end

  if best_prefix and best_dir then
    local remainder = path:sub(#best_prefix + 1)
    return best_dir .. remainder
  end

  return path
end

--- Resolve a Go module-local import to its local path.
--- e.g. "github.com/jhwheeler/rheo/internal/engine" -> "/home/.../rheo/internal/engine"
---@param path string
---@return string
function M.resolve_go(path)
  path = path:gsub("^['\"]", ""):gsub("['\"]$", "")

  local bufdir = vim.fn.expand("%:p:h")
  local mod_root = find_root(bufdir, "go.mod")
  if not mod_root then return path end

  local gomod_path = mod_root .. "/go.mod"
  if not gomod_cache[gomod_path] then
    local ok, lines = pcall(vim.fn.readfile, gomod_path)
    if ok then
      for _, line in ipairs(lines) do
        local mod = line:match("^module%s+(.+)$")
        if mod then
          gomod_cache[gomod_path] = { root = mod_root, prefix = mod }
          break
        end
      end
    end
    if not gomod_cache[gomod_path] then
      gomod_cache[gomod_path] = {}
      return path
    end
  end

  local entry = gomod_cache[gomod_path]
  if not entry.prefix then return path end

  -- Check if the import starts with the module prefix
  if path == entry.prefix then
    return entry.root
  end
  local prefix_slash = entry.prefix .. "/"
  if path:sub(1, #prefix_slash) == prefix_slash then
    local remainder = path:sub(#prefix_slash + 1)
    return entry.root .. "/" .. remainder
  end

  return path
end

return M
