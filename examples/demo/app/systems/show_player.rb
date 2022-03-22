class ShowPlayer < Draco::System
  filter Tag(:playable), Draco::FSM::StateChanged

  def tick args
    entities.each_with_index do |entity, i|
      if entity.standing?
        entity.state_changed.after(3, :seconds) do
          entity.walk direction: [:left, :right].sample
        end
      elsif entity.walking?
        entity.state_changed.after(1, :seconds) do
          entity.stand
        end
      end

      #puts entity.inspect
      #args.outputs.labels << [10, 500 + (50 * i), entity, 2, 0]
      label = "##{entity.id} #{entity.state} #{entity.triggerable_events.join('|')}"
      args.outputs.labels << [10, 400 + (50 * i), label, 1, 0]
    end
  end
end
