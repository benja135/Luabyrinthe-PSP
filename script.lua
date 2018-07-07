-- Benja135 -- Luabyrinthe Revolution B2 -- PSP luaplayer HMv2 --

-- Performances
System.setcpuspeed(333)
System.memclean()
debug = true

dofile("codes/global.lua")

-- Configurations
local config = {langue = 1, queue = 1, particules = 1, theme = 2, sons = 1, musiques = 1}

-- Fonction pour écrire hors d'une boucle les préchargements
local function write(text)
	screen.startDraw()
	screen.clear(0)
	screen.print(10,257,text,0.8,blanc,0,4)
	screen.endDraw()
	screen.flipscreen()
end

write("Initializing variables...")

-- Deplacement
local move = {timer = 1, timer_lim = 0, vitesse = 1, nbr = 0}

-- Gestion du temps	
local temps = {timer = Timer.new(), minutes = 0, secondes = 0, centiemes = 0, mili = 0}
local zero_string = "0" -- Pour l'affichage du temps

-- Ennemis
local ennemis = {}
local ennemis_nbr = 0

-- Bombes
local bombe = {}
local bombe_num = 1 -- nombre de bombe posé
local bombe_po = 2 -- la porté des bombes 
local deto = {img = Image.load("images/divers/deto.png"), po = 2} -- Détonateur
local explo_temps = 200 -- Temps de réaction en chaine

-- Menus 
local background_create = Image.createEmpty(480,272)
local alpha_transparent = 0
local color_transparent = Color.new(0,0,0,alpha_transparent) -- Transparence pour le menu perdu, pause... 
local selection = 1 -- Pour le main, les autre sont local aux sous menus
local color_end_lvl = {rouge, vert} -- Pour changer la couleur entre le menu "perdu" et "gagné"
local background = Image.load("images/divers/background.png") -- background du menu main
local logo = {x = 330, y = 110, img = Image.load("images/divers/logo.png"), size = {x = 121, y = 18}, v = {x=(121/18)/5,y=1/5}} -- le "revolution", taille d'origine: 121*18

-- Divers
local fps = {timer = Timer.new(), fps = 0, i = 0} -- FPS
local tile_end = {x = 0, y = 0} -- position end
local frag = 0 -- fragement ramassé par le joueur
local tail = {} -- tableau pour la "queue"
local footer = Image.load("images/divers/footer.png") -- Images du pied de page
local particules_max = 25
local anim_change = true
local select_img = {bloc = Image.load("images/divers/select.png"), cell = Image.load("images/divers/select2.png")}
local grille = {} -- LA grille
for i=1,30 do grille[i] = {} end -- Initialisation de la grille


-- Tableau de couleur pour les menus 
local color_text = {}
for i=1,10 do
	color_text[i] = {}
	for y=1,10 do 
		color_text[i][y] = 0
	end
	color_text[i][i] = vert
end

write("Loading images...")

-- Images de l'animation des explosions
local explo_anim = {}
for i=1,9 do
	explo_anim[i] = Image.load("images/anim/boom"..i..".png")
end

-- Tableau du perso, avec ses tuiles
local perso = {bombe = 0, statut = "right", x = 1, y = 1}

-- Chargement des tuiles et définition de leur comportement et de leur priorité d'affichage
-- e: comportement pour les ennemis, b: comportement pour le destruction par bombes, 
-- p: comportement pour la pose de bombe, j: pour le joueur
-- Priorités 0: aucune priorité ou pas nécéssaire
local tile = {}
for i=1,3 do
	tile[i] = {
	{img = Image.load("images/tiles/"..i.."/void.png"), e = 1, b = 1, p = 1, j = 1, prio = 0}, -- 1
	{img = Image.load("images/tiles/"..i.."/wall.png"), e = 0, b = 1, p = 0, j = 0, prio = 0},
	{img = Image.load("images/tiles/"..i.."/killer.png"), e = 0, b = 1, p = 0, j = 1, prio = 2},
	{img = Image.load("images/tiles/"..i.."/end.png"), e = 0, b = 0, p = 0, j = 1, prio = 0},
	{img = Image.load("images/tiles/"..i.."/frag.png"), e = 1, b = 1, p = 1, j = 1, prio = 0}, -- 5
	{img = Image.load("images/tiles/"..i.."/bombe.png"), e = 0, b = 1, p = 0, j = 0, prio = 0},
	{img = Image.load("images/tiles/"..i.."/refuge.png"), e = 0, b = 0, p = 1, j = 1, prio = 0},
	{img = Image.load("images/tiles/"..i.."/unbreakable.png"), e = 0, b = 0, p = 0, j = 0, prio = 0},
	{img = Image.load("images/tiles/"..i.."/break.png"), e = 1, b = 1, p = 1, j = 1, prio = 0},
	{img = Image.load("images/tiles/"..i.."/start.png"), e = 1, b = 1, p = 1, j = 1, prio = 0}, -- 10
	{img = Image.load("images/tiles/"..i.."/perso.png"), e = 1, b = 0, p = 0, j = 1, prio = 2},
	{img = Image.load("images/tiles/"..i.."/tail1.png"), e = 1, b = 0, p = 1, j = 1, prio = 1},
	{img = Image.load("images/tiles/"..i.."/tail2.png"), e = 1, b = 0, p = 1, j = 1, prio = 1} -- 13
	}
end

write("Preloading levels...")

--local gt = // GAME_TYPE: la variable GT se passe mintenant de f(x) en f(x)
local level_num = 1 -- Niveau actuel
local level_nbr = {0,0} -- Nombre de niveau total du mode aventure et arcade
local level = {} -- Enorme tableau contenant tout les niveaux
local chemin = {"levels/aventure/","levels/arcade/"}

-- On ouvre toutes les sauvegardes de niveau et on les mets dans l'énorme tableau 'level'
for c=1,2 do
	local i = 1 
	level[c] = {}
	while i == level_nbr[c]+1 do --
		if System.doesFileExist(chemin[c]..i..".txt") == 1 then
			level_nbr[c] = level_nbr[c] + 1
			dofile(chemin[c]..i..".txt")
			level[c][level_nbr[c]] = save_lvl
			save_lvl = nil
		end
		i = i + 1
	end
end

write("Loading texts...")

-- Tableau des textes
local text = {}
text = 
{	{	creer = "Creer",
		charger = "Charger",
		par = " par ",
		aventure = "Aventure",
		arcade = "Arcade",
		magasin = "Magasin",
		statistiques = "Statistiques",
		editeur = "Editeur",
		classement = "Classement",
		bonus = "Bonus",
		options = "Options",
		grille = {"Grille active","Grille desactive"},
		queue = {"Queue active","Queue desactive"},
		particules = {"Particules actives","Particules desactives"},
		langue = "Francais/English",
		bombe = "Bombes: ",
		temps = "Temps: ",
		pause = "Pause",
		sons = {"Sons actives","Sons desactives"},
		musique = {"Musique active","Musique desactive"},
		reprendre = "Reprendre",
		retour = "Retour au menu",
		recommencer = "Recommencer",
		fin = {titre={"Dommage !","Felicitation !"},ligne={"Recommencer le niveau","Niveau suivant"},ligne2={"Retour au menu","Recommencer le niveau"},ligne3={"","Retour au menu"}},
		objectif = {"Magic Square requis: ","Challenge Magic Square: ","Challenge deplacement: ","Challenge temps: "},
		theme = {"Theme 1","Theme 2","Theme 3"}
	},
	{
		creer = "Create",
		charger = "Load",
		par = " by ",
		aventure = "Adventure",
		arcade = "Arcade",
		magasin = "Shop",
		statistiques = "Stats",
		editeur = "Editor",
		classement = "Rank",
		bonus = "Bonus",
		options = "Options",
		grille = {"Grid enabled","Grid disabled"},
		queue = {"Tail enabled","Tail disabled"},
		particules = {"Particles enabled","Particles disabled"},
		sons = {"Sounds enabled","Sounds disabled"},
		musique = {"Music enabled","Music disabled"},
		langue = "English/Francais",
		bombe = "Bombs: ",
		temps = "Time: ",
		pause = "Pause",
		reprendre = "Resume",
		retour = "Back to menu",
		recommencer = "Restart",
		fin = {titre={"Try again !","Congratulations !"},ligne={"Restart the level","Next level"},ligne2={"Back to menu","Restart the level"},ligne3={"","Retour au menu"}},
		objectif = {"Magic Square required: ","Challenge Magic Square: ","Challenge move: ","Challenge time: "},		
		theme = {"Theme 1","Theme 2","Theme 3"}
	}	}
	
write("Loading functions...")

function choix_editeur()

	affichage_end() -- Evite un léger écran noir
	oldpad = Controls.read()
	local selection = 1
	
	while true do
	pad = Controls.read()
	affichage_start()
	
	selection = selection_menu(2,selection)
	
	screen.print(30,120,text[config.langue].editeur,1.1,noir,vert,4)
	screen.print(100,150,text[config.langue].creer,0.8,noir,color_text[selection][1],4)
	screen.print(100,165,text[config.langue].charger,0.8,noir,color_text[selection][2],4)
	
	if pad:cross() and selection == 1 and oldpad ~= pad then
		editeur(0)
	elseif pad:cross() and selection == 2 and oldpad ~= pad then
		liste_level(2,true)
	elseif pad:circle() and oldpad ~= pad then
		main()
	end
	
	oldpad = pad 
	affichage_end()
	end
	
end

function editeur(choix)

	if choix == 0 then
		for x=1,30 do -- On initialise la grille vide
			for y=1,16 do
				grille[x][y] = 1
			end
		end
	else
		grille = level[2][choix].code	-- On charge la grille du niveau choisi
	end
		
	affichage_end()
	local selection = 1
	oldpad = Controls.read()
	local curseur = {x = 1, y = 1}
	local bloc_nbr = 13
	
	while true do
	pad = Controls.read()
	screen.startDraw()
	screen.clear(0)
	
	-- Map aléatoire pour le fun!
	if pad:select() and oldpad ~= pad then
		for x=1,30 do
			for y=1,16 do
				local case = math.floor(math.random(1,11))
				if case == 4 or case == 10 then case = 1 end
				grille[x][y] = case 
			end
		end
		grille[math.floor(math.random(1,31))][math.floor(math.random(1,17))] = 4
		grille[math.floor(math.random(1,31))][math.floor(math.random(1,17))] = 10
	end
	
	for x=1,30 do -- on affiche les tuiles
		for y=1,16 do
			Image.blit((x-1)*16,(y-1)*16,tile[config.theme][grille[x][y]].img)
		end
	end

	-- Gére les blocs de construction
		for i=1,bloc_nbr do -- Afficher tout les bloc de construction
			Image.blit(16*(i-1),16^2,tile[config.theme][i].img)
		end
		if pad:r() and oldpad ~= pad then
			selection = selection + 1
		elseif pad:l() and oldpad ~= pad then
			selection = selection - 1
		end
		if selection > bloc_nbr then
			selection = 1
		elseif selection < 1 then
			selection = bloc_nbr
		end
		Image.blit(16*(selection-1)-1,16^2-1,select_img.bloc) -- Affiche le curseur sur les blocs de construction
	
	-- Gére le curseur sur la grille
		if pad:right() and oldpad ~= pad then
			curseur.x = curseur.x + 1
		elseif pad:left() and oldpad ~= pad then
			curseur.x = curseur.x - 1
		end
		if pad:up() and oldpad ~= pad then
			curseur.y = curseur.y - 1
		elseif pad:down() and oldpad ~= pad then
			curseur.y = curseur.y + 1
		end
		if curseur.x > 30 then
			curseur.x = 1
		elseif curseur.x < 1 then
			curseur.x = 30
		end
		if curseur.y > 16 then
			curseur.y = 1
		elseif curseur.y < 1 then
			curseur.y = 16
		end
		Image.blit(16*(curseur.x-1),16*(curseur.y-1),select_img.cell)
		
	if pad:cross() and oldpad ~= pad then
		if selection == 4 or selection == 10 then -- Si on veux poser le start ou le end
			for x=1,30 do
				for y=1,16 do
					if grille[x][y] == selection then grille[x][y] = 1 end -- On enléve l'ancien start ou end
				end
			end
		end
		grille[curseur.x][curseur.y] = selection -- on pose le nouveau
	end

	if pad:square() then -- On efface la cellule
		grille[curseur.x][curseur.y] = 1
	end
	
	if pad:circle() and oldpad ~= pad then
		choix_editeur()
	end
			
	if pad:start() then -- Si on valide la création de la map
		for x=1,30 do
			for y=1,16 do
				if grille[x][y] == 4 then -- Si le point end est bien en place
					local fin = {x=x,y=y}
					grille[x][y] = 1
					for x=1,30 do
						for y=1,16 do
							if grille[x][y] == 10 then -- Le point start est en place donc on peut sauvegarde le lv
								local begin = {x=x,y=y}
								grille[x][y] = 1
								local bombe_nbr = clavier(2,"Nombre de bombe?")
								local temps = clavier(2,"Challenge temps?")
								local move = clavier(2,"Challenge deplacement?")								
								local frag_max = clavier(2,"Challenge fragment?")
								local frag = clavier(2,"Fragment minimum?")
								local titre = clavier(1,"Titre du niveau?")
								local auteur = clavier(1,"Auteur?")
								local save_lvl = 'save_lvl={begin={x='..begin.x..',y='..begin.y..'},fin={x='..fin.x..',y='..fin.y..'},auteur="'..auteur..
								'",bombe_nbr='..bombe_nbr..', objectif={frag='..frag..',frag_max='..frag_max..',temps='..temps..',move ='..move..'}, titre="'..titre..
								'", code={'
								for x=1,30 do
									save_lvl = save_lvl.."{"
									for y=1,16 do
										save_lvl = save_lvl..grille[x][y]
										if y < 16 then save_lvl = save_lvl.."," end
									end
									if x < 30 then save_lvl = save_lvl.."}," else save_lvl = save_lvl.."}}}" end
								end
								level_nbr[2] = level_nbr[2] + 1
								file = io.open("levels/arcade/"..level_nbr[2]..".txt","w")
								file:write(save_lvl)
								file:close()
								-- On lit ensuite la save qui n'est plus un string mais une table puis on le met dans le gros tableau de level
									dofile("levels/arcade/"..level_nbr[2]..".txt")
									level[2][level_nbr[2]] = save_lvl
									save_lvl = nil
								System.message('Creation du niveau reussis.',0)
								main()
							end
						end
					end
				end
			end
		end
		-- Si on est la c'est qui manque le start et/ou le end
		System.message('Il manque le point "start" et/ou "end"!',0)
		pad = Controls.read()
	end
	
	oldpad = pad 
	affichage_end()
	end
end

function liste_level(gt,edit)

	local selection = 1
	oldpad = Controls.read()
	local noir_tab = {Color.new(0,0,0,255),Color.new(0,0,0,205),Color.new(0,0,0,155),Color.new(0,0,0,105),Color.new(0,0,0,55)}

	while true do
		pad = Controls.read()
		screen.startDraw()
		screen.clear(0)
		
		Image.blit(0,0,background)
		
		for x=1,30 do
			for y=1,16 do
				Image.blit((x-1)*8+230, (y-1)*8+115, tile[3][level[gt][selection].code[x][y]].img) -- tile[théme mini][level[game type][selection].code[x][y]]
			end
		end
		screen.print(230,258,text[config.langue].par..level[gt][selection].auteur,0.6,noir_tab[3],0,4)

		for i=1, 4 do
			if selection > i then
				screen.print(10,150-12*i,level[gt][selection-i].titre,0.7,noir_tab[i+1],0,4)
			end
			if selection+i <= level_nbr[gt] then
				screen.print(10,150+12*i,level[gt][selection+i].titre,0.7,noir_tab[i+1],0,4)
			end
		end
		
		screen.print(10,150,level[gt][selection].titre,0.7,noir_tab[1],vert,4)
		screen.print(10,150+12*7,text[config.langue].objectif[2]..level[gt][selection].objectif.frag_max,0.6,bleu,0,4)
		screen.print(10,150+12*8,text[config.langue].objectif[3]..level[gt][selection].objectif.move,0.6,bleu,0,4)
		screen.print(10,150+12*9,text[config.langue].objectif[4]..level[gt][selection].objectif.temps,0.6,bleu,0,4)
		
		if pad:cross() and oldpad ~= pad then
			if not edit then
				level_num = selection
				init_level(level_num,gt)
			else
				editeur(selection)
			end
		end
		if pad:circle() and oldpad ~= pad then
			break
		end
		
		selection = selection_menu(level_nbr[gt],selection)
		
		oldpad = pad 
		affichage_end()
	end
end

function affichage_end()
	screen.endDraw()
	screen.waitVblankStart()
	screen.flipscreen()	
end

function affichage_footer(gt)
	Image.blit(0,256,footer)
	if temps.secondes < 10 then zero = "0" else zero = "" end -- pour avoir toujours 2 chiffres à l'affichage des secondes
	screen.print(2,269,text[config.langue].bombe..perso.bombe.." "..text[config.langue].temps..temps.minutes.."'"..zero..temps.secondes.."'".." MS: "..frag.."/"..level[gt][level_num].objectif.frag.."/"..level[gt][level_num].objectif.frag_max.." Move: "..move.nbr.." FPS: "..fps.fps,0.7,blanc,0,4)
end

-- Pour afficher le menu avec le niveau en arriére plan
function affichage_transparent(gt)

	for y=1,16 do -- on tuile le niveau
		for x=1,30 do
			Image.blit((x-1)*16,(y-1)*16,tile[config.theme][grille[x][y]].img)
		end
	end
	
	if config.particules == 1 and particule[1] ~= nil then
		for i=1,particules_max do -- on affiche les 30 particules
			affichage_particules(i,0.8)
		end
	end
	
	for i=1, bombe_num do
		if bombe[i] ~= nil then
			if bombe[i].compteur > 0 then
				Image.blit((bombe[i].x-1)*16-3*16,(bombe[i].y-1)*16-3*16,explo_anim[bombe[i].compteur])
			end
		end
	end

	color_transparent = Color.new(0,0,0,alpha_transparent)
	Image.clear(background_create,color_transparent)
	Image.blit(0,0,background_create)
	
	affichage_footer(gt)
	
end

dofile("codes/particles.lua")
dofile("codes/clavier.lua")
	
function init_level(level_num,gt) -- A MODIF

	-- Réinitialisation commune à tout les lvl
	for i=1,bombe_num do
		bombe[i] = nil
	end
	bombe_num = 1
	move = {timer = 1, timer_lim = 0, vitesse = 1, nbr = 0}
	temps = {timer = Timer.new(), minutes = 0, secondes = 0, centiemes = 0, mili = 0}
	fps = {timer = Timer.new(), fps = 0, i = 0}
	frag = 0
	ennemis_nbr = 0

	-- On remplie la grille, on cré les bombes, les ennemis et on positione le perso
	grille = level[gt][level_num].code
	perso.bombe = level[gt][level_num].bombe_nbr
	tile_end = level[gt][level_num].fin
	perso.x = level[gt][level_num].begin.x
	perso.y = level[gt][level_num].begin.y
	for x=1,30 do
		for y=1,16 do
			if grille[x][y] == 3 then
				ennemis_nbr = ennemis_nbr + 1
				ennemis[ennemis_nbr] = {x = x,y = y,timer = 1,timeout = math.floor(math.random(30,50)),vitesse = 1,old = 1}
			elseif grille[x][y] == 6 then
				bombe[bombe_num] = {x = x, y = y, compteur = 0, timer = Timer.new()}
				bombe_num = bombe_num + 1
			end
		end
	end
	
	oldpad = Controls.read()
	alpha_transparent = 200
	while true do
		screen.startDraw()
		screen.clear(0) 
		pad = Controls.read()
		affichage_transparent(gt)
		
		screen.print(50,120,level[gt][level_num].titre,1.2,blanc,vert,4)
		screen.print(65,140,text[config.langue].objectif[1]..level[gt][level_num].objectif.frag,0.7,bleu,0,4) 
		screen.print(65,155,text[config.langue].objectif[2]..level[gt][level_num].objectif.frag_max,0.7,blanc,0,4) 
		screen.print(65,170,text[config.langue].objectif[3]..level[gt][level_num].objectif.move,0.7,blanc,0,4) 
		screen.print(65,185,text[config.langue].objectif[4]..level[gt][level_num].objectif.temps,0.7,blanc,0,4) 

		if pad:cross() and oldpad ~= pad then
			game(gt)
		end
		
		oldpad = pad 
		affichage_end()
	end
	
end

function affichage_start() 
	screen.startDraw()
	screen.clear(0)
	Image.blit(0,0,background)
	Image.blit(logo.x+logo.size.x/2,logo.y+logo.size.y/2,logo.img)
	Image.resize(logo.size.x,logo.size.y,logo.img)
	Image.rotate(logo.size.x/2,logo.size.y/2,20,logo.img)
	logo.size.x = logo.size.x + logo.v.x
	logo.size.y = logo.size.y + logo.v.y
	if logo.size.x >= 141 then
		logo.v.x = (-121/18)/5
		logo.v.y = -1/5
	elseif logo.size.x <= 101 then
		logo.v.x = (121/18)/5
		logo.v.y = 1/5
	end
end
		

function main()

oldpad = Controls.read()
System.memclean()

local size = {1.1,0.8}
local noir_tab = {Color.new(0,0,0,255),Color.new(0,0,0,80)}

local function options()

local selection = 1
oldpad = Controls.read()

while true do
affichage_start()
pad = Controls.read()

screen.print(30,120,text[config.langue].options,1.1,noir,vert,4)

screen.print(40,145,text[config.langue].langue,0.8,noir,color_text[selection][1],4)
screen.print(40,145+15,text[config.langue].queue[config.queue],0.8,noir,color_text[selection][2],4)
screen.print(40,145+15*2,text[config.langue].particules[config.particules],0.8,noir,color_text[selection][3],4)
screen.print(40,145+15*3,text[config.langue].theme[config.theme],0.8,noir,color_text[selection][4],4)
screen.print(40,145+15*4,text[config.langue].sons[config.sons],0.8,noir,color_text[selection][5],4)
screen.print(40,145+15*5,text[config.langue].musique[config.musiques],0.8,noir,color_text[selection][6],4)
if debug then screen.print(40,265,"RAM: "..System.getFreeMemory().." octets",0.8,noir,rouge,4) end


if pad:cross() and oldpad ~= pad then
	if selection == 1 then if config.langue == 1 then config.langue = 2 else config.langue = 1 end
	elseif selection == 2 then if config.queue == 1 then config.queue = 2 else config.queue = 1 end
	elseif selection == 3 then if config.particules == 1 then config.particules = 2 else config.particules = 1 end
	elseif selection == 4 then if config.theme < 3 then config.theme = config.theme + 1 else config.theme = 1 end
	elseif selection == 5 then if config.sons == 1 then config.sons = 2 else config.sons = 1 end
	elseif selection == 6 then if config.musiques == 1 then config.musiques = 2 else config.musiques = 1 end end
end

if pad:circle() and oldpad ~= pad then
	selection = 8
	break
end
		
selection = selection_menu(6,selection)

oldpad = pad 
affichage_end()
end

end

local function menu1()
	screen.print(30,130,text[config.langue].aventure,size[1],noir_tab[1],color_text[selection][1],4) 
	screen.print(30,155,text[config.langue].arcade,size[1],noir_tab[1],color_text[selection][2],4)
	screen.print(30,180,text[config.langue].magasin,size[1],noir_tab[1],color_text[selection][3],4)
	screen.print(30,205,text[config.langue].statistiques,size[1],noir_tab[1],color_text[selection][4],4)
end

local function menu2()
	screen.print(100,150,text[config.langue].editeur,size[2],noir_tab[2],color_text[selection][5],4)
	screen.print(100,175,text[config.langue].classement,size[2],noir_tab[2],color_text[selection][6],4)
	screen.print(100,200,text[config.langue].bonus,size[2],noir_tab[2],color_text[selection][7],4)
	screen.print(100,225,text[config.langue].options,size[2],noir_tab[2],color_text[selection][8],4)
end
	
while true do
affichage_start()
pad = Controls.read()

if pad:cross() and oldpad ~= pad then
		if selection == 1 then liste_level(1,false)
	elseif selection == 2 then liste_level(2,false)
	elseif selection == 3 then
	elseif selection == 4 then
	elseif selection == 5 then choix_editeur()
	elseif selection == 6 then
	elseif selection == 7 then
	elseif selection == 8 then options()
	end
end

selection = selection_menu(8,selection)

if pad:right() and selection <= 4 and oldpad ~= pad then
	selection = selection + 4
elseif pad:left() and selection > 4 and oldpad ~= pad then
	selection = selection - 4
end

if selection <= 4 then
	size = {1.1,0.8}
	noir_tab = {Color.new(0,0,0,255),Color.new(0,0,0,80)}
	menu2()
	menu1()
elseif selection > 4 then
	size = {0.8,1.1}
	noir_tab = {Color.new(0,0,0,80),Color.new(0,0,0,255)}
	menu1()
	menu2()
end

oldpad = pad 
affichage_end()
end

end

function game(gt)

	local function ennemis_move()
		local function move_ennemis(x,y,i)
			if tile[1][grille[ennemis[i].x+x][ennemis[i].y+y]].e == 1 then -- Si la case est dispo pour un ennemis
				grille[ennemis[i].x][ennemis[i].y] = ennemis[i].old
				ennemis[i].x = ennemis[i].x + x
				ennemis[i].y = ennemis[i].y + y
				ennemis[i].old = grille[ennemis[i].x][ennemis[i].y]
				grille[ennemis[i].x][ennemis[i].y] = 3
			end
		end
		
		for i=1,ennemis_nbr do
			if ennemis[i] ~= nil then
				local rand = math.random(0,4)
				if grille[ennemis[i].x][ennemis[i].y] ~= 3 then -- Si l'ennemi n'est pas sur une cellule ennemi (3) c'est qu'il y a eu une explosion, on détruit l'ennemis
					ennemis[i] = nil
				else
					if ennemis[i].timer > ennemis[i].timeout then
						if rand < 1 and ennemis[i].x < 30 then 
							move_ennemis(1,0,i)
						elseif rand < 2 and ennemis[i].x > 1 then 
							move_ennemis(-1,0,i)
						elseif rand < 3 and ennemis[i].y > 1 then 
							move_ennemis(0,-1,i)
						elseif rand < 4 and ennemis[i].y < 16 then 
							move_ennemis(0,1,i)
						end
						if ennemis[i].timer > ennemis[i].timeout then -- on réinitialise pour pas avoir de trop grosse valeur
							ennemis[i].timer = 1
						end
					end
					ennemis[i].timer = ennemis[i].timer + ennemis[i].vitesse
				end
			end
		end
	end

	local function detonation(x,y) -- (x et y du personnage)
		for i=1,bombe_num do
			if bombe[i] ~= nil then
				if bombe[i].compteur == 0 then
					if bombe[i].x <= x+deto.po and bombe[i].x >= x-deto.po and bombe[i].y <= y+deto.po and bombe[i].y >= y-deto.po then
						declenchement_explo_cible(i) 
					end
				end
			end
		end
	end
	
	-- Explosion ciblé + réaction en chaine
	function declenchement_explo_cible(i) -- (numéro de la bombe à exploser)
		bombe[i].compteur = 1 -- On fait explosé la bombe cible
		for x=-bombe_po,bombe_po do -- On regarde dans la porté de la bombe cible s'il y a d'autre bombe, si oui on va déclencher leur timer
			for y=-bombe_po+math.abs(x), bombe_po-math.abs(x) do -- Yeah :p
				if bombe[i].x+x <= 30 and bombe[i].x+x >= 1 and bombe[i].y+y <= 16 and bombe[i].y+y >= 1 and tile[1][grille[bombe[i].x+x][bombe[i].y+y]].b == 1 then -- Si la cellule est accessible par l'explosion d'une bombe
					if grille[bombe[i].x+x][bombe[i].y+y] == 6 then -- Si c'est une bombe, on va déclencher le timer
						for n=1, bombe_num do -- On cherche le numéro de la bombe qui est sur cette case
							if bombe[n] ~= nil then -- Si elle existe
								if bombe[n].compteur == 0 then -- Si elle a pas été déclanché
									if bombe[n].x == bombe[i].x+x then
										if bombe[n].y == bombe[i].y+y then
											bombe[n].timer:start() -- On déclenche le timer de la bombe
										end
									end
								end
							end
						end
					else
						grille[bombe[i].x+x][bombe[i].y+y] = 9 -- Si c'est pas une bombe on écrase la cellule (9: break)
					end
				end
			end
		end
	end

	local function poser_bombe(x,y)
		if perso.bombe > 0 then
			if tile[1][grille[perso.x+x][perso.y+y]].p == 1 then
				grille[perso.x+x][perso.y+y] = 6
				perso.bombe = perso.bombe - 1
				bombe[bombe_num] = {x = perso.x+x, y = perso.y+y, compteur = 0, timer = Timer.new()}
				bombe[bombe_num].timer:stop()
				bombe[bombe_num].timer:reset(0)
				bombe_num = bombe_num + 1
			end
		end
	end

	local function pause(gt)

		oldpad = Controls.read()
		local selection = 1
		alpha_transparent = 200
		
		while true do
		screen.startDraw()
		screen.clear(0)
		pad = Controls.read()
		
		affichage_transparent(gt)
		
		screen.print(28,65,text[config.langue].pause,1.2,blanc,vert,4)

		screen.print(40,90,text[config.langue].reprendre,0.8,blanc,color_text[selection][1],4) 
		screen.print(40,90+15,text[config.langue].recommencer,0.8,blanc,color_text[selection][2],4) 
		screen.print(40,90+15*2,text[config.langue].retour,0.8,blanc,color_text[selection][3],4) 
		screen.print(40,90+15*3,text[config.langue].langue,0.8,blanc,color_text[selection][4],4)
		screen.print(40,90+15*4,text[config.langue].queue[config.queue],0.8,blanc,color_text[selection][5],4)
		screen.print(40,90+15*5,text[config.langue].particules[config.particules],0.8,blanc,color_text[selection][6],4)
		screen.print(40,90+15*6,text[config.langue].theme[config.theme],0.8,blanc,color_text[selection][7],4)
		screen.print(40,90+15*7,text[config.langue].sons[config.sons],0.8,blanc,color_text[selection][8],4)
		screen.print(40,90+15*8,text[config.langue].musique[config.musiques],0.8,blanc,color_text[selection][9],4)
		
		if pad:start() and oldpad ~= pad then
			break
		elseif pad:cross() and oldpad ~= pad then
			if selection == 1 then
				break
			elseif selection == 2 then
				init_level(level_num,gt)
				break
			elseif selection == 3 then
				main()
			elseif selection == 4 then if config.langue == 1 then config.langue = 2 else config.langue = 1 end
			elseif selection == 5 then if config.queue == 1 then config.queue = 2 else config.queue = 1 end
			elseif selection == 6 then if config.particules == 1 then config.particules = 2 else config.particules = 1 end
			elseif selection == 7 then if config.theme < 3 then config.theme = config.theme + 1 else config.theme = 1 end
			elseif selection == 8 then if config.sons == 1 then config.sons = 2 else config.sons = 1 end
			elseif selection == 9 then if config.musiques == 1 then config.musiques = 2 else config.musiques = 1 end 
			end
		elseif pad:circle() and oldpad ~= pad then
			break
		end
				
		selection = selection_menu(10,selection)

		oldpad = pad 
		affichage_end()
		end
		
	end
	
	local function graphic_tail(create,x,y)
		local stop = false
		for i=1,4 do
			if create then
				if tail[i] ~= nil then
					tail[i].vie = tail[i].vie - 1
					if tail[i].vie <= 0 then
                        grille[tail[i].x][tail[i].y] = 1
						tail[i] = nil
					end
				end
				if tail[i] == nil and not stop then
					tail[i] = {img = 1, x=x, y=y, vie = 4, timer=Timer.new()}
					tail[i].timer:start() 
					stop = true
				end
			end
			if tail[i] ~= nil then
				grille[tail[i].x][tail[i].y] = 12
				if tail[i].timer:time() >= 800 then
					if grille[tail[i].x][tail[i].y] ~= 3 then -- Si jamais un ennemi est dessus on le supprime pas
                        grille[tail[i].x][tail[i].y] = 1
						tail[i] = nil	
					end
				elseif tail[i].timer:time() >= 400 then
					grille[tail[i].x][tail[i].y] = 13
				end
			end
		end
			
	end

	function perso_move(x,y,gt)

		if tile[1][grille[perso.x+x][perso.y+y]].j == 1 then
			if move.timer > move.timer_lim*20 then
				if config.queue == 1 then
					graphic_tail(true,perso.x,perso.y)
				end
				
				if grille[perso.x][perso.y] == 5 then 
                    frag = frag + 1 -- Si on bouge sur un fragment
				elseif grille[perso.x][perso.y] == 3 then
                    level_end(1,gt) -- Si on bouge sur un ennemis
				elseif grille[perso.x][perso.y] == 4 then
                    level_end(2,gt) -- Si on bouge sur le end
                end
				
				grille[perso.x][perso.y] = 1
				perso.x = perso.x + x
				perso.y = perso.y + y
				grille[perso.x][perso.y] = 11
				move.timer_lim = move.timer_lim + 1
				move.nbr = move.nbr + 1
			end	
			move.timer = move.timer + move.vitesse
		end
	end

	function level_end(resultat,gt)

		oldpad = Controls.read()
		local selection = 1
		alpha_transparent = 0
		ftemps()
		
		while true do
		screen.startDraw()
		screen.clear(0)
		pad = Controls.read()
		
		affichage_transparent(gt)
		
		if alpha_transparent < 200 then
			alpha_transparent = alpha_transparent + 6
		else
			screen.print(50,130,text[config.lanque].fin.titre[i],1.2,blanc,color_end_lvl[i],4)
			
			screen.print(65,150,text[config.lanque].fin.ligne[i],0.8,blanc,color_text[selection][1],4) 
			screen.print(65,165,text[config.lanque].fin.ligne2[i],0.8,blanc,color_text[selection][2],4)
			screen.print(65,180,text[config.lanque].fin.ligne3[i],0.8,blanc,color_text[selection][3],4) 
			screen.print(65,205,text[config.lanque].temps..temps.minutes.."'"..temps.secondes.."'"..temps.mili.."'",0.8,blanc,0,4) 

			if pad:cross() and oldpad ~= pad then
				if resultat == 1 then -- on vient de perdre 
					if selection == 1 then
						init_level(level_num,gt)
					elseif selection == 2 then
						main()
					end
				elseif resultat == 2 then -- on vient de gagner
					if selection == 1 then
						level_num = level_num + 1
						init_level(level_num,gt)
					elseif selection == 2 then
						init_level(level_num,gt)
					elseif selection == 3 then
						main()
					end
				end
			end
					
		selection = selection_menu(resultat+1,selection)
			
		end

		oldpad = pad 
		affichage_end()
		end
		
	end
	
	function ftemps()
		temps.mili = temps.timer:time()
		if temps.mili >= 1000 then
			temps.secondes = temps.secondes + 1
			temps.mili = temps.mili - 1000
			temps.timer:reset(temps.mili)
			temps.timer:start()
		end
		if temps.secondes == 60 then 
			temps.secondes = 0
			temps.minutes = temps.minutes + 1
		end
	end

temps.timer:start() 
fps.timer:start()

System.memclean()

while true do 
screen.startDraw()
screen.clear(0) 
pad = Controls.read()

if debug and pad:select() and oldpad ~= pad then
	if pad:r() and oldpad ~= pad then
		level_end(2,gt)
	elseif pad:l() and oldpad ~= pad then
		level_num = level_num - 2
		level_end(2,gt)
	end
end

for y=1,16 do -- On tuile le niveau
	for x=1,30 do
		Image.blit((x-1)*16,(y-1)*16,tile[config.theme][grille[x][y]].img)
	end
end

if config.queue == 1 then
	graphic_tail(false,0,0)
end

ftemps()

if pad:r() then -- bombe 
	if pad:right() and perso.x ~= 30 then
		poser_bombe(1,0)
	elseif pad:left() and perso.x ~= 1 then
		poser_bombe(-1,0)
	elseif pad:up() and perso.y ~= 1 then
		poser_bombe(0,-1)
	elseif pad:down() and perso.y ~= 16 then
		poser_bombe(0,1)
	end
elseif pad:right() and perso.x ~= 30 then
	perso_move(1,0,gt)
elseif pad:left() and perso.x ~= 1 then
	perso_move(-1,0,gt)
elseif pad:up() and perso.y ~= 1 then
	perso_move(0,-1,gt)
elseif pad:down() and perso.y ~= 16 then
	perso_move(0,1,gt)
else
	move.timer_lim = 0
	move.timer = 1
end

if pad:cross() then
	move.vitesse = 4
elseif move.timer_lim >= 3 then
	move.vitesse = 2
else 
	move.vitesse = 1
end
if pad:start() and oldpad ~= pad then
	fps.timer:stop()
	temps.timer:stop()
	pause(gt)
	fps.timer:start()
	temps.timer:start()
end

ennemis_move()
if grille[perso.x][perso.y] == 3 then level_end(1) end -- Si un ennemis est venu sur le joueur

if pad:l() and not pad:r() then
	Image.blit((perso.x-3)*16,(perso.y-3)*16,deto.img) -- affichage détonateur
	if pad:cross() then
		detonation(perso.x,perso.y)
	end
end

-- Gestion de l'anim des bombes et des réactions timer
for i=1,bombe_num do
	if bombe[i] ~= nil then
		if bombe[i].timer:time() >= explo_temps then -- gestion de l'explosion retardé des bombes
			bombe[i].timer:stop()
			bombe[i].timer:reset(0)
			if bombe[i]. compteur == 0 then
				declenchement_explo_cible(i)
			end
		end
		if change_anim then -- gestion de l'anim des bombes, s'effectue 1 fois sur 2
			if bombe[i].compteur > 0 then
				Image.blit((bombe[i].x-1)*16-3*16,(bombe[i].y-1)*16-3*16,explo_anim[bombe[i].compteur])
				bombe[i].compteur = bombe[i].compteur + 1
				if bombe[i].compteur > 9 then
					grille[bombe[i].x][bombe[i].y] = 1
					bombe[i] = nil
				end
			end
		end
	end
end

if change_anim then change_anim = false else change_anim = true end

if config.particules == 1 then
	particules(particules_max,true,0.8) 
end


if fps.timer:time() >= 1000 then
	fps.fps = fps.i
	fps.i = 0
	fps.timer:reset()
	fps.timer:start()
else
	fps.i = fps.i + 1
end

affichage_footer(gt)

if frag >= level[gt][level_num].objectif.frag then
	grille[tile_end.x][tile_end.y] = 4
end

oldpad = pad 
affichage_end()
end

end

-- Splash screen
	local alpha = 0
	local color = Color.new(0,0,0,alpha)
	local img = Image.load("images/divers/splash_screen.png")
	local x = -math.sqrt(255)
	while x < math.sqrt(255) do -- on utilise un polynome, pour faire plus pro :p
		pad = Controls.read()
		screen.startDraw()
		screen.clear(0)
		Image.blit(0,0,img)
		Image.fillRect(0,272,480,0,color)
		x = x + (math.sqrt(255))/100
		alpha = -x^2 + 255
		color = Color.new(0,0,0,255-alpha)
		affichage_end()
		if pad:cross() then
			x = math.sqrt(255)
		end
	end
	alpha = nil
	color = nil
	img = nil
	x = nil

System.memclean()
main()