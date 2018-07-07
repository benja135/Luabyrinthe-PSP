-- Benja135, Luabyrinthe Revolution, PSP luaplayer HMv2
-- Clavier virtuel

local strings = {{"0","1","2","3","4","5","6","7","8","9"," ","=","@","-",">","<","!","?",":","a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"},
{"0","1","2","3","4","5","6","7","8","9"," ","=","@","-",">","<","!","?",":","A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"}}
local selection = 1
local colonne = 9
local nbr_string = {45,10}
local maj = 1
local text = ""
local old_text = text
local l = 1
local c = 1
local fond = Image.createEmpty(480,272)
local color = Color.new(0,0,0,125)
local lim = {15,4}

-- Tableau de couleur pour les menus 
local color_text = {}
for i=1,nbr_string[1] do
	color_text[i] = {}
	for y=1,nbr_string[1] do 
		color_text[i][y] = 0
	end
	color_text[i][i] = vert
end

function clavier(type,info) -- 1: tout, 2: que chiffre

	selection = 1
	text = ""
	affichage_end()
	oldpad = pad
	while true do
		pad = Controls.read()
		screen.startDraw()
		screen.clear(0)
		

		Image.clear(fond,color)
		Image.blit(0,0,fond)
		
		screen.print(50,35,info,0.9,blanc,vert,4)
		
		l = 1
		c = 1
		for i=1, nbr_string[1] do
			if type == 1 or (type == 2 and i <= nbr_string[2]) then
				screen.print(50+(c-1)*17,50+(l-1)*15,strings[maj][i],0.9,blanc,color_text[selection][i],4)
				if i/colonne == l then
					l = l + 1
					c = 1
				else
					c = c + 1
				end
			end
		end
		
		screen.print(50,50+l*15,text,0.9,blanc,rouge,4)
		
		if pad:down() and oldpad ~= pad then
			selection = selection + colonne
		elseif pad:up() and oldpad ~= pad then
			selection = selection - colonne
		end
		
		if pad:right() and oldpad ~= pad then
			selection = selection + 1
		elseif pad:left() and oldpad ~= pad then
			selection = selection - 1
		end
		
		if selection > nbr_string[type] then
			selection = selection - nbr_string[type]
		elseif selection < 1 then
			selection = selection + nbr_string[type]
		end
		
		if pad:square() and oldpad ~= pad then
			if maj == 1 then
				maj = 2
			else
				maj = 1
			end
		end
		
		if pad:cross() and oldpad ~= pad and #text < lim[type] then
			text = text..strings[maj][selection]
		end
		
		if pad:circle() and oldpad ~= pad then -- On enleve le dernier string
			old_text = text
			text = ""
			for i=1,#old_text-1 do
				text = text..string.sub(old_text,i,i)
			end
		end
		
		if pad:start() and oldpad ~= pad then 
			if text == "" then
				if type == 1 then
					text = "Default"
				elseif type == 2 then
					text = "0"
				end
			end
			return text
		end
		affichage_end()
		oldpad = pad
	end
	
end