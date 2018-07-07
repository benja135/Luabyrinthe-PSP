local tab = {1,1,1,1,1}

local function test(tab)
  for i=1,5 do
    screen.print(10,10*i,tab(i),0.8,blanc,0,4)
  end
end

while true do
  screen.startDraw()
  screen.clear(0)

  test(tab[])

  screen.endDraw()
  screen.flipscreen()
end

table.foreach({1,"two",3,"four"}

  function(k,v) 
    print(string.rep(v,k)) 
  end

