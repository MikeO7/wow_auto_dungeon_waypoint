import sys

with open('Core.lua', 'r') as f:
    content = f.read()

search_str = """
local closeBtn = CreateFrame("Button", nil, statusFrame, "UIPanelButtonTemplate")
closeBtn:SetSize(24, 24)
closeBtn:SetPoint("TOPRIGHT", statusFrame, "TOPRIGHT", -4, -4)
closeBtn:SetText("X")
"""

replace_str = """
local closeBtn = CreateFrame("Button", nil, statusFrame, "UIPanelCloseButton")
closeBtn:SetSize(24, 24)
closeBtn:SetPoint("TOPRIGHT", statusFrame, "TOPRIGHT", -4, -4)
"""

if search_str in content:
    content = content.replace(search_str, replace_str)
    with open('Core.lua', 'w') as f:
        f.write(content)
    print("Replaced successfully")
else:
    print("Could not find search string")
