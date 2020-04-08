module Klank
    require_relative "deck.rb"
    require_relative "utils.rb"

    class Dungeon
        COUNT = 6

        def initialize(game)
            @game = game
            @deck = Deck.new(game, "dungeon.yml")
            @hand = []

            while @hand.count < COUNT
                if @deck.peek.dragon 
                    @deck.reshuffle!()
                else
                    @hand << @deck.draw(1)[0]
                end
            end
        end

        def danger()
            @hand.select { |c| c.danger }.count
        end

        def replenish()
            count = COUNT - @hand.count

            if count > 0
                @game.broadcast("\nReplenishing the dungeon...")
                attack = false

                cards = @deck.draw(count)
                
                cards.each do |c|
                    c.arrive()
                    if c.dragon
                        attack = true
                    end              
                end
                @hand += cards

                if attack 
                    @game.dragon.attack()
                else 
                    @game.dragon.bank_status()
                end
            end

            dungeon = []
            @hand.each_with_index do |c, i|
                dungeon << c.buy_desc(false)
            end
            @game.broadcast("\nDUNGEON\n#{Klank.table(dungeon)}")
        end

        def buy(player)
            card = nil

            loop do 
                c = menu("BUY A CARD", player)
                break if c == "N"

                if @hand[c.to_i].acquire(player)
                    card = @hand.delete_at(c.to_i)
                    break if (@hand.count == 0) or (player.skill < @hand.map { |c| c.cost }.min)
                end

                player.output("\nSKILL: #{player.skill}")
            end

            card
        end

        def monster(player)
            card = nil

            loop do 
                c = menu("DEFEAT A MONSTER", player)
                break if c == "N"

                if @hand[c.to_i].defeat(player)
                    card = @hand.delete_at(c.to_i)
                    break if (@hand.count == 0) or (player.attack < @hand.map { |c| c.attack }.min)
                end

                player.output("\nATTACK: #{player.attack}")
            end

            card
        end

        def replace_card(player)
            c = menu("REPLACE A CARD", player)
            if c != "N"
                removed = @hand.delete_at(c.to_i)
                added = @deck.draw(1)[0]
                @hand << added
                @game.broadcast("#{player.name} removed #{removed.name} and #{added.name} replaced it!")
            end
        end

        private 

        def menu(title, player)
            options = []
            @hand.each_with_index do |c, i|
                options << [i, c.buy_desc(player.has_played?("Gem Collector"))]
            end
            card = player.menu(title, options, true)
        end
    end
end
