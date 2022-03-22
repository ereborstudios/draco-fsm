class GameWorld < Draco::World
  entity Player, as: :player
  entity Player, as: :player2

  systems ShowPlayer
end
