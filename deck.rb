require "yaml"

module Klank
    require_relative "card.rb"
    require_relative "utils.rb"

    class Deck
        
        attr_accessor :stack
        attr_accessor :pile
        attr_accessor :trashed

        def initialize(game, yml)
            @stack = []
            @pile = []
            @trashed = []

            add(game, yml)
        end

        def remaining()
            @stack.count
        end

        def draw(num, player = nil, game = nil)
            hand = []

            num.times do 
                if @stack.count == 0
                    if player != nil
                        game.broadcast("#{player.name} is reshuffling their deck!")
                        player.num_times_shuffled += 1
                    end
                    @stack = Klank.randomize(@pile)
                    @pile = []
                end 
                hand << @stack.shift
            end

            hand
        end

        def add(game, yml)
            YAML.load(File.read(yml)).each do |c|
                (c["count"] || 1).times do 
                    @stack << Card.new(game, c)
                end
            end
            @stack = Klank.randomize(@stack)
        end

        def discard(hand)
            @pile += hand
        end

        def peek(index = 0)
            @stack[index]
        end

        def reshuffle!()
            @stack = Klank.randomize(@stack)
        end

        def active_cards()
            @stack + @pile
        end

        def all()
            @stack + @pile + @trashed
        end

        def view_pile(player)
            cards = []
            @pile.each do |c|
                cards << {"CARD" => c.name}
            end
            player.output("\nDISCARD PILE\n#{Klank.table(cards)}")
        end
    end
end
