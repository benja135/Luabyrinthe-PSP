-- Benja135, Luabyrinthe Revolution, PSP luaplayer HMv2
-- Effet de particules, trajectoire sinuso�dale

particule = {} -- tableau pour les particules

local function create(i)
	particule[i] = 
	{
		x = math.random(0,479),
		y = math.random(0,271),
		dir = {a=math.random(50,200),p=math.random(10,100),o=math.random(80,120)}, -- "dir" pour direction, a=amplitude, p=p�riode, o=ordonn�
		sens = math.random(1,10), -- le sens des particules (on le d�termine apr�s pour choisir qu'entre 1 et -1)
		speed_alpha = math.random(1,20), -- vitesse d'alpha
		speed = math.random(0,1), -- vitesse de d�placement
		alpha = 255
		--size = math.random(size_min,size_max)
	}
	if particule[i].speed <= 0.2 then
		particule[i].speed = 0.1
	elseif particule[i].speed <= 0.6 then
		particule[i].speed = 0.2
	elseif particule[i].speed <= 1 then
		particule[i].speed = 0.3
	end
	if particule[i].sens > 5 then -- on d�termine le sens
		particule[i].sens = 1
	else
		particule[i].sens = -1
	end
end

function affichage_particules(i,size)
	screen.print(particule[i].x,particule[i].y,".",size,Color.new(0,204,255,particule[i].alpha),Color.new(0,204,255,particule[i].alpha),4)
end

function particules(particules_max,death,size) 
	--particules(nombre de particules,particule �ph�m�re(bool�en),taille,une couleur ou 3 en fonction de la vitesse(bool�en))
	
	-- on cr� les particules qui manque
	if particule[particules_max] == nil then
		for i=1,particules_max do
			if particule[i] == nil then
				create(i)
			end
		end
	end
		
	for i=1,particules_max do 
		
		-- on calcule l'ordonn�s des particule, le d�placement est sinuso�dale
		particule[i].y = (particule[i].dir.a)*(math.cos((1/(particule[i].dir.p))*particule[i].x))+(particule[i].dir.o) 
		
		-- on inverse leur sens quand elles atteignent un bord
		if particule[i].x > 480 or particule[i].x < 0 then
			particule[i].sens = (particule[i].sens)*(-1)
		end	

		-- on d�place les particules (abscisse)
		particule[i].x = particule[i].x + (particule[i].speed)*particule[i].sens
		
		affichage_particules(i,size) -- on affiche les particules
		
		if death then	-- si les particules sont �ph�m�res
			particule[i].alpha = particule[i].alpha - particule[i].speed_alpha
			if particule[i].alpha < 0 then -- si une vient de s'�teindre on en repop une autre 
				create(i)
			end
		end
		
	end
end