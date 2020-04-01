module Klank
    require_relative "deck.rb"

    class Player
        FULL_HEALTH = 10

        attr_reader :name

        attr_accessor :skill
        attr_accessor :attack
        attr_accessor :move
        attr_accessor :coins
        attr_accessor :teleport

        def initialize(client)
            @client = client

            @name = input("Name")
            output("Welcome to Klank, #{@name}!")
        end

        def input(msg)
            @client.write "#{msg }: "
            resp = @client.gets.strip

            resp
        end

        def input_num(msg, range)
            n = 0

            loop do 
                n = input("#{msg} [#{range.min}, #{range.max}]")
                break if n =~ /^\d+/ and range.include?(n.to_i)
                output("Oops!")
            end

            return n.to_i
        end

        def output(msg)
            @client.puts "#{msg}"
        end

        def menu(title, options)
            msg = ["\n#{title}"]
            options.each do |o|
                msg << "#{o[0]}: #{o[1]}"
            end
            output(msg.join("\n"))

            choice = ""
            loop do
                choice = input("Choose an option").upcase
                break if options.any? { |o| o[0].to_s.upcase == choice }
                output("Oops!")
            end

            choice
        end

        def score()
            @coins
        end

        def start(game, index)
            @game = game
            @deck = Deck.new("player.yml")
            @coins = 0
            @cubes = 30
            @health = FULL_HEALTH
            @index = index
            @artifact = []
        end

        def draw(count = 5)
            output("\nDrawing cards...")
            cards = @deck.draw(count)
            msg = []
            cards.each_with_index do |c, i|
                msg << c.play_desc
            end
            output(msg.join("\n"))

            @hand += cards
        end

        def turn()
            if !dead?()
                @hand = []
                @played = []
                @skill = 0
                @move = 0
                @attack = 0
                @teleport = 0
                @clank_added = 0
                @clank_remove = 0

                @game.broadcast("HEALTH: #{@health} | CLANK: #{@cubes} | COINS: #{@coins}")

                draw()

                loop do 
                    menu = []

                    if @hand.count != 0
                        menu << ["E", "Equip card(s)"]
                    end

                    if (@game.reserve[:x].remaining > 0) and (@skill >= @game.reserve[:x].peek.cost)
                        menu << ["X", "Buy an explore card"]
                    end

                    if (@game.reserve[:c].remaining > 0) and (@skill >= @game.reserve[:c].peek.cost)
                        menu << ["C", "Buy a mercenary card"]
                    end

                    if (@game.reserve[:t].remaining > 0) and (@skill >= @game.reserve[:t].peek.cost)
                        menu << ["T", "Buy a tome card"]
                    end

                    if @skill > 0
                        menu << ["B", "Buy a card from the dungeon"]
                    end

                    if @move > 0 
                        menu << ["M", "Move"]
                    end

                    if @attack > 0
                        menu << ["A", "Attack a monster from the dungeon"]
                    end

                    if @attack > 1
                        menu << ["G", "Kill the goblin"]
                    end

                    if @hand.count == 0
                        menu << ["D", "End Turn"]
                    end

                    option = menu("ACTION LIST", menu)
                    
                    case option
                    when "E"
                        equip()
                    when "X"
                        x = @game.reserve[:x].draw(1)
                        @deck.discard(x)
                        @skill -= x[0].cost
                    when "C"
                        c = @game.reserve[:c].draw(1)
                        @deck.discard(c)
                        @skill -= c[0].cost
                    when "T"
                        t = @game.reserve[:t].draw(1)
                        @deck.discard(t)
                        @skill -= t[0].cost
                    when "B"
                        card = @game.dungeon.buy(self)
                        if card 
                            @deck.discard([card])
                            @game.broadcast("#{@name} bought #{card.name} from the dungeon!")
                        end
                    when "M"
                    
                    when "A"
                        card = @game.dungeon.monster(self)
                        if card 
                            @game.broadcast("#{@name} killed #{card.name} in the dungeon!")
                        end
                    when "G"
                        @coins += 1
                        @attack -= 2
                    when "D"
                        @deck.discard(@played)
                        break
                    else
                        output("Hmmm... something went wrong")
                    end

                    break if dead?()

                    output_abilities()
                end

                @game.dragon.remove(@index, -1 * @clank_remove)
            end
        end

        def damage(direct = false)
            @health -= 1
            if direct 
                @clank -= 1
            end
        end

        def heal(count = 1)
            @health = [FULL_HEALTH, @health + count].min
        end

        def dead?()
            @health <= 0
        end

        def clank(count = 1)
            if count > 0
                actual = [@cubes, count].min 
                @cubes -= actual 
                @game.dragon.add(@index, actual)
            else
                @clank_remove += count
            end
        end

        def depths?()
            false
        end

        def artifact?()
            @artifact.count > 0
        end

        private 

        def output_abilities()
            string = []

            if @skill != 0
                string << "SKILL: #{@skill}"
            end 

            if @move != 0
                string << "MOVE: #{@move}"
            end 

            if @attack != 0
                string << "ATTACK: #{@attack}"
            end

            if @coins != 0
                string << "COINS: #{@coins}"
            end

            if @teleport != 0
                string << "TELEPORT: #{@teleport}"
            end

            output("\n" + string.join(" | "))
        end

        def equip()
            cards = []
            @hand.each_with_index do |c, i|
                cards << [i, c.play_desc]
            end
            cards << ["A", "All of the cards"]
            cards << ["N", "None of the cards"]
            c = menu("HAND", cards)

            play = []

            if c == "A"
                play = @hand 
                @hand = []
            elsif c == "N"
                # do nothing
            else
                play = [@hand.delete_at(c.to_i)]
            end

            msg = [""]

            play.each do |card|
                card.equip(self)
                msg << "#{@name} played #{card.name}"
            end

            @game.broadcast(msg.join("\n"))

            @played += play
        end
    end
end