--[[
	© 2014 CloudSixteen.com do not share, re-distribute or modify
	without permission of its author (kurozael@gmail.com).

	Clockwork was created by Conna Wiles (also known as kurozael.)
	http://cloudsixteen.com/license/clockwork.html
--]]

local Clockwork = Clockwork;
local pairs = pairs;
local ScrH = ScrH;
local ScrW = ScrW;
local table = table;
local vgui = vgui;
local math = math;

local PANEL = {};

-- Called when the panel is initialized.
function PANEL:Init()
	self:SetSize(Clockwork.menu:GetWidth(), Clockwork.menu:GetHeight());
	
	self.inventoryList = vgui.Create("cwPanelList", self);
 	self.inventoryList:SetPadding(2);
 	self.inventoryList:SetSpacing(2);
	
	self.equipmentList = vgui.Create("cwPanelList", self);
 	self.equipmentList:SetPadding(2);
 	self.equipmentList:SetSpacing(2);
	
	self.craftingList = vgui.Create("cwPanelList", self);
 	self.craftingList:SetPadding(2);
 	self.craftingList:SetSpacing(2);
	self.craftingList:SizeToContents();
	self.craftingList:EnableVerticalScrollbar();
	
	self.columnSheet = vgui.Create("DColumnSheet", self);
	self.columnSheet.Navigation:SetWidth(150);
	self.columnSheet:AddSheet(Clockwork.option:GetKey("name_inventory"), self.inventoryList, "icon16/box.png");
	self.columnSheet:AddSheet("Equipment", self.equipmentList, "icon16/shield.png");
	self.columnSheet:AddSheet("Crafting", self.craftingList, "icon16/wrench_orange.png")
	
	Clockwork.inventory.panel = self;
	Clockwork.inventory.panel:Rebuild();
end;

-- Called to by the menu to get the width of the panel.
function PANEL:GetMenuWidth()
	return ScrW() * 0.6;
end;

-- A function to handle unequipping for the panel.
function PANEL:HandleUnequip(itemTable)
	if (itemTable.OnHandleUnequip) then
		itemTable:OnHandleUnequip(
		function(arguments)
			if (arguments) then
				Clockwork.datastream:Start(
					"UnequipItem", {itemTable("uniqueID"), itemTable("itemID"), arguments}
				);
			else
				Clockwork.datastream:Start(
					"UnequipItem", {itemTable("uniqueID"), itemTable("itemID")}
				);
			end;
		end);
	else
		Clockwork.datastream:Start(
			"UnequipItem", {itemTable("uniqueID"), itemTable("itemID")}
		);
	end;
end;

-- A function to rebuild the panel.
function PANEL:Rebuild()
	self.equipmentList:Clear();
	self.inventoryList:Clear();
	self.craftingList:Clear();
	
	local cCategories = {};
	local items = {};
	local empty = {};
	
	local label = vgui.Create("cwInfoText", self);
		label:SetText("To interact with an item left click on it to bring up options.");
		label:SetInfoColor("blue");
	self.inventoryList:AddItem(label);
	
	local labelC = vgui.Create("cwInfoText", self);
		labelC:SetText("From this window you can craft certain items. Full implementation in Update 1.");
		labelC:SetInfoColor("blue");
	self.craftingList:AddItem(labelC);
	
	for k, v in pairs(Clockwork.recipe:GetAll()) do
		items[#items + 1] = v;
		cCategories[v.category] = v.category;
	end;
	
	table.sort(items, function(a, b) 
		return a.name < b.name;
	end);

	table.sort(cCategories, function(a, b) 
		return a < b;
	end);

for k, v in pairs(cCategories) do
		local collapsibleCategory = Clockwork.kernel:CreateCustomCategoryPanel(v, self.craftingList);
		self.craftingList:AddItem(collapsibleCategory);

		local categoryList = vgui.Create("DPanelList", collapsibleCategory);
			categoryList:EnableHorizontal(true);
			categoryList:SetAutoSize(true);
			categoryList:SetPadding(4);
			categoryList:SetSpacing(4);
		collapsibleCategory:SetContents(categoryList);
		
		local count = 0;

		for k3, v3 in pairs(items) do
			if (v3.category == v and Clockwork.plugin:Call("PlayerCanSeeRecipe", v3)) then
				count = count + 1;
				local SpawnIcon = Clockwork.kernel:CreateMarkupToolTip(vgui.Create("cwSpawnIcon", self));
				SpawnIcon:SetSize(40, 40);
				SpawnIcon:SetModel(v3.model);
				SpawnIcon:SetToolTip("");

				local informationColor = Clockwork.option:GetColor("information");
				local toolTip = "";
				local recipe = v3.name;
				local clientInventory = Clockwork.inventory:GetClient();
			
				toolTip = Clockwork.kernel:MarkupTextWithColor("[Information]", informationColor);
				toolTip = toolTip.."\n"..recipe;

				if (v3.description) then
					toolTip = toolTip.."\n"..v3.description;
				end;

				Clockwork.plugin:Call("PreRecipeRequired", v3, toolTip);

				toolTip = toolTip.."\n"..Clockwork.kernel:MarkupTextWithColor("[Requires]", informationColor);

				for k2, v2 in pairs(v3.required) do
					local realID = k2;

					if (Clockwork.item:FindByID(k2)) then
						realID = Clockwork.item:FindByID(k2)("uniqueID");
					end;

					local itemCount = table.Count(clientInventory[realID] or empty);

					if (itemCount >= v2) then
						if (v2 != 1) then
							toolTip = toolTip..Clockwork.kernel:MarkupTextWithColor("\n"..itemCount.."/"..v2, Color(0, 255, 0)).." "..Clockwork.kernel:Pluralize(Clockwork.item:FindByID(k2)("name"));
						else
							toolTip = toolTip..Clockwork.kernel:MarkupTextWithColor("\n"..itemCount.."/"..v2, Color(0, 255, 0)).." "..Clockwork.item:FindByID(k2)("name");
						end;
					else
						if (v2 == 1) then
							toolTip = toolTip..Clockwork.kernel:MarkupTextWithColor("\n"..itemCount.."/"..v2, Color(255, 0, 0)).." "..Clockwork.item:FindByID(k2)("name");
						else
							toolTip = toolTip..Clockwork.kernel:MarkupTextWithColor("\n"..itemCount.."/"..v2, Color(255, 0, 0)).." "..Clockwork.kernel:Pluralize(Clockwork.item:FindByID(k2)("name"));
						end;
					end;
				end;

				if (v3.requiredEnts) then
					for k2, v2 in pairs(v3.requiredEnts) do
						local name = v2;
						local entInRadius = false;

						for k4, v4 in pairs(ents.FindByClass(k2)) do
							name = v4.PrintName or v4:GetClass();

							if LocalPlayer():GetPos():Distance(v4:GetPos()) <= Clockwork.config:Get("crafting_radius"):Get() then
								entInRadius = true;
							end;
						end;

						if entInRadius then
							toolTip = toolTip..Clockwork.kernel:MarkupTextWithColor("\n"..name, Color(0, 255, 0));
						else
							toolTip = toolTip..Clockwork.kernel:MarkupTextWithColor("\n"..name, Color(255, 0, 0));
						end;
					end;
				end;

				if (v3.cost) then
					local cost = v3.cost;
					local cash = Clockwork.player:GetCash();
					local name_cash = " "..string.lower(Clockwork.option:GetKey("name_cash"));

					if (cash >= cost) then
						toolTip = toolTip..Clockwork.kernel:MarkupTextWithColor("\n"..cash.."/"..cost..name_cash, Color(0, 255, 0));
					else
						toolTip = toolTip..Clockwork.kernel:MarkupTextWithColor("\n"..cash.."/"..cost..name_cash, Color(255, 0, 0));
					end;
				end;

				if (v3.requiredAttribs) then
					local playerAttribs = {};
					local attribs = Clockwork.attribute:GetAll()
					
					for k,v in pairs(Clockwork.attributes.stored) do
						playerAttribs[k] = v;
					end;

					for k2, v2 in pairs(v3.requiredAttribs) do
						for k4, v4 in pairs(playerAttribs) do
							local attribName = attribs[k4].name;
							local percentAmount = math.Round(v4.amount/attribs[k4].maximum*100);
							local percentRequired = math.Round(v2/attribs[k4].maximum*100);

							if (string.lower(k2) == string.lower(attribName)) then
								if (v4.amount >= v2) then
									toolTip = toolTip..Clockwork.kernel:MarkupTextWithColor("\n"..percentAmount.."%/"..percentRequired.."% "..attribName, Color(0, 255, 0));
								else
									toolTip = toolTip..Clockwork.kernel:MarkupTextWithColor("\n"..percentAmount.."%/"..percentRequired.."% "..attribName, Color(255, 0, 0));
								end;
							end;
						end;
					end;
				end;

				Clockwork.plugin:Call("PostRecipeRequired", v3, toolTip);
				Clockwork.plugin:Call("PreRecipeOutputs", v3, toolTip);

				toolTip = toolTip.."\n"..Clockwork.kernel:MarkupTextWithColor("[Outputs]", informationColor);

				for k2, v2 in pairs(v3.output) do
					if (v2 != 1) then
						toolTip = toolTip.."\n"..v2.." "..Clockwork.kernel:Pluralize(Clockwork.item:FindByID(k2)("name"));
					else
						toolTip = toolTip.."\n"..v2.." "..Clockwork.item:FindByID(k2)("name");
					end;
				end;

				Clockwork.plugin:Call("PostRecipeOutputs", v3, toolTip);
				SpawnIcon:SetMarkupToolTip(toolTip);

				function SpawnIcon.DoClick()
					Clockwork.plugin:Call("RecipeClicked", v3);
					Clockwork.datastream:Start("Craft", v3.name);
					
					timer.Simple(1, function()
						self:Rebuild();
					end);
				end;

				categoryList:AddItem(SpawnIcon);
			end;
		end;

		if (count == 0) then
			collapsibleCategory:Remove();
		end;
	end;	
	
	self.weightForm = vgui.Create("DForm", self);
	self.weightForm:SetPadding(4);
	self.weightForm:SetName("Weight");
	self.weightForm:AddItem(vgui.Create("cwInventoryWeight", self));
	
	if (Clockwork.inventory:UseSpaceSystem()) then
		self.spaceForm = vgui.Create("DForm", self);
		self.spaceForm:SetPadding(4);
		self.spaceForm:SetName("Space");
		self.spaceForm:AddItem(vgui.Create("cwInventorySpace", self));
	end

	local itemsList = {inventory = {}, equipment = {}};
	local categories = {inventory = {}, equipment = {}};
	
	for k, v in pairs(Clockwork.Client:GetWeapons()) do
		local itemTable = Clockwork.item:GetByWeapon(v);
		
		if (itemTable and itemTable.HasPlayerEquipped
		and itemTable:HasPlayerEquipped(Clockwork.Client, true)) then
			local itemCategory = itemTable("equippedCategory", itemTable("category"));
			itemsList.equipment[itemCategory] = itemsList.equipment[itemCategory] or {};
			itemsList.equipment[itemCategory][#itemsList.equipment[itemCategory] + 1] = itemTable;
		end;
	end;
	
	for k, v in pairs(Clockwork.inventory:GetClient()) do
		for k2, v2 in pairs(v) do
			local itemCategory = v2("category");
			
			if (v2.HasPlayerEquipped and v2:HasPlayerEquipped(Clockwork.Client, false)) then
				itemCategory = v2("equippedCategory", itemCategory);
				itemsList.equipment[itemCategory] = itemsList.equipment[itemCategory] or {};
				itemsList.equipment[itemCategory][#itemsList.equipment[itemCategory] + 1] = v2;
			else
				itemsList.inventory[itemCategory] = itemsList.inventory[itemCategory] or {};
				itemsList.inventory[itemCategory][#itemsList.inventory[itemCategory] + 1] = v2;
			end;
		end;
	end;
	
	for k, v in pairs(itemsList.equipment) do
		categories.equipment[#categories.equipment + 1] = {
			itemsList = v,
			category = k
		};
	end;
	
	table.sort(categories.equipment, function(a, b)
		return a.category < b.category;
	end);
	
	for k, v in pairs(itemsList.inventory) do
		categories.inventory[#categories.inventory + 1] = {
			itemsList = v,
			category = k
		};
	end;
	
	table.sort(categories.inventory, function(a, b)
		return a.category < b.category;
	end);
	
	Clockwork.plugin:Call("PlayerInventoryRebuilt", self, categories);
	
	if (self.weightForm) then
		self.inventoryList:AddItem(self.weightForm);
	end;

	if (Clockwork.inventory:UseSpaceSystem() and self.spaceForm) then
		self.inventoryList:AddItem(self.spaceForm);
	end;

	if (#categories.equipment > 0) then
		for k, v in pairs(categories.equipment) do
			local collapsibleCategory = Clockwork.kernel:CreateCustomCategoryPanel(v.category, self.equipmentList);
				collapsibleCategory:SetCookieName("Equipment"..v.category);
			self.equipmentList:AddItem(collapsibleCategory);
			
			local categoryList = vgui.Create("DPanelList", collapsibleCategory);
				categoryList:EnableHorizontal(true);
				categoryList:SetAutoSize(true);
				categoryList:SetPadding(4);
				categoryList:SetSpacing(4);
			collapsibleCategory:SetContents(categoryList);
			
			table.sort(v.itemsList, function(a, b)
				return a("itemID") < b("itemID");
			end);
			
			for k2, v2 in pairs(v.itemsList) do
				local itemData = {
					itemTable = v2, OnPress = function()
						self:HandleUnequip(v2);
					end
				};
				
				self.itemData = itemData;
				categoryList:AddItem(
					vgui.Create("cwInventoryItem", self)
				);
			end;
		end;
	end;
	
	if (#categories.inventory > 0) then
		for k, v in pairs(categories.inventory) do
			local collapsibleCategory = Clockwork.kernel:CreateCustomCategoryPanel(v.category, self.inventoryList);
				collapsibleCategory:SetCookieName("Inventory"..v.category);
			self.inventoryList:AddItem(collapsibleCategory);
			
			local categoryList = vgui.Create("DPanelList", collapsibleCategory);
				categoryList:EnableHorizontal(true);
				categoryList:SetAutoSize(true);
				categoryList:SetPadding(4);
				categoryList:SetSpacing(4);
			collapsibleCategory:SetContents(categoryList);
			
			table.sort(v.itemsList, function(a, b)
				return a("itemID") < b("itemID");
			end);
			
			for k2, v2 in pairs(v.itemsList) do
				local itemData = {
					itemTable = v2
				};
				
				self.itemData = itemData;
				categoryList:AddItem(
					vgui.Create("cwInventoryItem", self)
				);
			end;
		end;
	end;

	self.inventoryList:InvalidateLayout(true);
	self.equipmentList:InvalidateLayout(true);
	self.craftingList:InvalidateLayout(true);
end;

-- Called when the menu is opened.
function PANEL:OnMenuOpened()
	if (Clockwork.menu:IsPanelActive(self)) then
		self:Rebuild();
	end;
end;

-- Called when the panel is selected.
function PANEL:OnSelected() self:Rebuild(); end;

-- Called when the layout should be performed.
function PANEL:PerformLayout(w, h)	
	self:SetSize(w, ScrH() * 0.75);
	self.columnSheet:StretchToParent(4, 28, 4, 4);
	self.inventoryList:StretchToParent(4, 4, 4, 4);
	self.equipmentList:StretchToParent(4, 4, 4, 4);
	self.craftingList:StretchToParent(4, 4, 4, 4);
end;

-- Called when the panel is painted.
function PANEL:Paint(w, h)
	surface.SetDrawColor( 255, 255, 255, 255 )
    surface.DrawRect( 0, 0, w, ScrH() * 0.75)
	
	surface.SetDrawColor( 114, 175, 212, 230 )
    surface.DrawRect( 0, 0, w, h * 0.03)
end;

-- Called each frame.
function PANEL:Think()
	for k, v in pairs(Clockwork.Client:GetWeapons()) do
		local weaponItem = Clockwork.item:GetByWeapon(v);
		if (weaponItem and !v.cwIsWeaponItem) then
			Clockwork.inventory:Rebuild();
			v.cwIsWeaponItem = true;
		end;
	end;
	
	self:InvalidateLayout(true);
end;

vgui.Register("cwInventory", PANEL, "EditablePanel");

local PANEL = {};

-- Called when the panel is initialized.
function PANEL:Init()
	self:SetSize(self:GetParent():GetWide(), 32);
	
	local customData = self:GetParent().customData or {};
	local toolTip = "";
	
	if (customData.information) then
		if (type(customData.information) == "number") then
			customData.information = customData.information.."kg";
		end;
	end;
	
	if (customData.description) then
		toolTip = Clockwork.config:Parse(customData.description);
	end;
	
	if (toolTip == "") then
		toolTip = nil;
	end;
	
	self.nameLabel = vgui.Create("DLabel", self);
	self.nameLabel:SetPos(36, 2);
	self.nameLabel:SetText(customData.name);
	self.nameLabel:SizeToContents();
	
	self.infoLabel = vgui.Create("DLabel", self);
	self.infoLabel:SetPos(36, 2);
	self.infoLabel:SetText(customData.information);
	self.infoLabel:SizeToContents();
	
	self.spawnIcon = Clockwork.kernel:CreateMarkupToolTip(vgui.Create("cwSpawnIcon", self));
	self.spawnIcon:SetColor(customData.spawnIconColor);
	
	-- Called when the spawn icon is clicked.
	function self.spawnIcon.DoClick(spawnIcon)
		if (customData.Callback) then
			customData.Callback();
		end;
	end;
	
	self.spawnIcon:SetModel(customData.model, customData.skin);
	self.spawnIcon:SetToolTip(toolTip);
	self.spawnIcon:SetSize(32, 32);
end;

-- Called each frame.
function PANEL:Think()
	self.infoLabel:SetPos(self.infoLabel.x, 30 - self.infoLabel:GetTall());
end;
	
vgui.Register("cwInventoryCustom", PANEL, "DPanel");

local PANEL = {};

-- Called when the panel is initialized.
function PANEL:Init()
	local itemData = self:GetParent().itemData;
	self:SetSize(48, 48);
	self.itemTable = itemData.itemTable;
	self.spawnIcon = Clockwork.kernel:CreateMarkupToolTip(vgui.Create("cwSpawnIcon", self));
	
	if (!itemData.OnPress) then
		self.spawnIcon.OpenMenu = function(spawnIcon)
			Clockwork.kernel:HandleItemSpawnIconRightClick(self.itemTable, spawnIcon);
		end;
	end;
	
	-- Called when the spawn icon is clicked.
	function self.spawnIcon.DoClick(spawnIcon)
		if (itemData.OnPress) then
			itemData.OnPress();
			return;
		end;
		
		Clockwork.kernel:HandleItemSpawnIconClick(self.itemTable, spawnIcon);
	end;
	
	local model, skin = Clockwork.item:GetIconInfo(self.itemTable);
		self.spawnIcon:SetModel(model, skin);
		self.spawnIcon:SetSize(48, 48);
	self.cachedInfo = {model = model, skin = skin};
end;

-- Called each frame.
function PANEL:Think()
	self.spawnIcon:SetMarkupToolTip(Clockwork.item:GetMarkupToolTip(self.itemTable));
	self.spawnIcon:SetColor(self.itemTable("color"));
	
	--[[ Check if the model or skin has changed and update the spawn icon. --]]
	local model, skin = Clockwork.item:GetIconInfo(self.itemTable);
	
	if (model != self.cachedInfo.model or skin != self.cachedInfo.skin) then
		self.spawnIcon:SetModel(model, skin);
		self.cachedInfo.model = model
		self.cachedInfo.skin = skin;
	end;
end;

vgui.Register("cwInventoryItem", PANEL, "DPanel");

local PANEL = {};

-- Called when the panel is initialized.
function PANEL:Init()
	local maximumWeight = Clockwork.player:GetMaxWeight();
	local colorWhite = Clockwork.option:GetColor("white");
	
	self.spaceUsed = vgui.Create("DPanel", self);
	self.spaceUsed:SetPos(1, 1);
	
	self.weight = vgui.Create("DLabel", self);
	self.weight:SetText("N/A");
	self.weight:SetTextColor(colorWhite);
	self.weight:SizeToContents();
	self.weight:SetExpensiveShadow(1, Color(0, 0, 0, 150));
	
	-- Called when the panel should be painted.
	function self.spaceUsed.Paint(spaceUsed)
		local inventoryWeight = Clockwork.inventory:CalculateWeight(
			Clockwork.inventory:GetClient()
		);
		local maximumWeight = Clockwork.player:GetMaxWeight();
		
		local color = Color(100, 100, 100, 255);
		local width = math.Clamp((spaceUsed:GetWide() / maximumWeight) * inventoryWeight, 0, spaceUsed:GetWide());
		local red = math.Clamp((255 / maximumWeight) * inventoryWeight, 0, 255) ;
		
		if (color) then
			color.r = math.min(color.r - 25, 255);
			color.g = math.min(color.g - 25, 255);
			color.b = math.min(color.b - 25, 255);
		end;
		
		Clockwork.kernel:DrawSimpleGradientBox(0, 0, 0, spaceUsed:GetWide(), spaceUsed:GetTall(), color);
		Clockwork.kernel:DrawSimpleGradientBox(0, 0, 0, width, spaceUsed:GetTall(), Color(139, 215, 113, 255));
	end;
end;

-- Called each frame.
function PANEL:Think()
	local inventoryWeight = Clockwork.inventory:CalculateWeight(
		Clockwork.inventory:GetClient()
	);
	
	self.spaceUsed:SetSize(self:GetWide() - 2, self:GetTall() - 2);
	self.weight:SetText(inventoryWeight.."/"..Clockwork.player:GetMaxWeight().."kg");
	self.weight:SetPos(self:GetWide() / 2 - self.weight:GetWide() / 2, self:GetTall() / 2 - self.weight:GetTall() / 2);
	self.weight:SizeToContents();
end;
	
vgui.Register("cwInventoryWeight", PANEL, "DPanel");

local PANEL = {};

-- Called when the panel is initialized.
function PANEL:Init()
	local maximumSpace = Clockwork.player:GetMaxSpace();
	local colorWhite = Clockwork.option:GetColor("white");
	
	self.spaceUsed = vgui.Create("DPanel", self);
	self.spaceUsed:SetPos(1, 1);
	
	self.space = vgui.Create("DLabel", self);
	self.space:SetText("N/A");
	self.space:SetTextColor(colorWhite);
	self.space:SizeToContents();
	self.space:SetExpensiveShadow(1, Color(0, 0, 0, 150));
	
	-- Called when the panel should be painted.
	function self.spaceUsed.Paint(spaceUsed)
		local inventorySpace = Clockwork.inventory:CalculateSpace(
			Clockwork.inventory:GetClient()
		);
		local maximumSpace = Clockwork.player:GetMaxSpace();
		
		local color = Color(100, 100, 100, 255);
		local width = math.Clamp((spaceUsed:GetWide() / maximumSpace) * inventorySpace, 0, spaceUsed:GetWide());
		local red = math.Clamp((255 / maximumSpace) * inventorySpace, 0, 255) ;
		
		if (color) then
			color.r = math.min(color.r - 25, 255);
			color.g = math.min(color.g - 25, 255);
			color.b = math.min(color.b - 25, 255);
		end;
		
		Clockwork.kernel:DrawSimpleGradientBox(0, 0, 0, spaceUsed:GetWide(), spaceUsed:GetTall(), color);
		Clockwork.kernel:DrawSimpleGradientBox(0, 0, 0, width, spaceUsed:GetTall(), Color(139, 215, 113, 255));
	end;
end;

-- Called each frame.
function PANEL:Think()
	local inventorySpace = Clockwork.inventory:CalculateSpace(
		Clockwork.inventory:GetClient()
	);
	
	self.spaceUsed:SetSize(self:GetWide() - 2, self:GetTall() - 2);
	self.space:SetText(inventorySpace.."/"..Clockwork.player:GetMaxSpace().."l");
	self.space:SetPos(self:GetWide() / 2 - self.space:GetWide() / 2, self:GetTall() / 2 - self.space:GetTall() / 2);
	self.space:SizeToContents();
end;
	
vgui.Register("cwInventorySpace", PANEL, "DPanel");