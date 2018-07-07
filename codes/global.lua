-- Benja135 -- Luabyrinthe Revolution B2 -- PSP luaplayer HMv2 --
-- Variables et fonctions globales

-- Couleurs
bleu = Color.new(0,204,255,255)
blanc = Color.new(255,255,255,255)
rouge = Color.new(255,0,0,255)
turquoise = Color.new(0,255,255,255)
noir = Color.new(0,0,0,255)
vert = Color.new(0,255,0,255)
gris = Color.new(51,51,51,255)
beige = Color.new(255,204,153,255)

function selection_menu(maxselection,selection)
  if pad:down() and oldpad ~= pad then
    selection = selection + 1
  elseif pad:up() and oldpad ~= pad then
    selection = selection - 1
  end

  if selection > maxselection then
    selection = 1
  elseif selection < 1 then
    selection = maxselection
  end
  return selection
end
