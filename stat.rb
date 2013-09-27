#!/usr/local/bin/ruby
require 'curses'
include Curses



class Stat

  attr_reader :asc_max, :desc_max, :cols, :lines, :vit, :noasc, :nodesc, :sym, :positions
  def initialize
    # initialisation de l'ecran
    Curses.init_screen
    # les touche de clavier ne produise rien a l'ecra
    Curses.noecho

    # utilisation de couleur pour plus de lisibilité
    Curses.start_color
    Curses.init_pair(COLOR_RED,COLOR_RED,COLOR_BLACK) 
    Curses.init_pair(COLOR_GREEN,COLOR_GREEN,COLOR_BLACK)

    Curses.curs_set(0)
    # recuperation du nombre de lignes et colonne du terminal courant
    @lines = Curses.lines
    @cols = Curses.cols

    @vit = 0.5
    @desc_max = 3500
    @asc_max = 150
    @noasc = false
    @nodesc = false
    @sym = "#"
  end

  def run
    reset_screen
    get_params
    if @noasc && @nodesc || !@noasc && !@nodesc
      graph_all
    else
      greph_desc_or_asc
    end
  end

  def greph_desc_or_asc
    max = @desc_max
    indice = 1
    color = COLOR_RED
    if @nodesc
      max = @asc_max
      indice = 2
      color = COLOR_GREEN
    end
    while true
      if @lines != Curses.lines
        @lines = Curses.lines
        @positions = reset_screen
      end
      if @cols != Curses.cols
        @cols = Curses.cols
        @positions = reset_screen
      end
      stat = `ifstat #{vit} 1 | grep "[0-9]*\.[0-9]*"`
      istat = stat.match(/(\d+\.\d+)\ +(\d+\.\d+)/)
      deb = istat[indice]
      nb = (deb.to_f / (max.to_f / @lines).to_f).to_i + 1    
      i = 1
      tmp = [[]]

      i = 0

      while i < @lines
        if i == @lines - 2
          tmp[0].push(@sym)
        elsif i <= @lines - nb
          tmp[0].push(' ')
        else
          tmp[0].push(@sym)
        end
        i += 1
      end
      i = 1
      @positions.each do |pos|
        tmp[i] = pos
        if i >= @positions.length - 1
          break
        end
        i += 1
      end

      @positions = tmp
      i = 1
      @positions.each do |pos|
        j = 0
        pos.each do |x|
          Curses.setpos(j + 1, i)
          Curses.attron(color_pair(color)){
            Curses.addstr(x)
          }
          j += 1
        end
        i += 1
      end
      Curses.setpos(0, 0)
      Curses.attron(color_pair(color)){
        Curses.addstr(" " * @cols)
      }
      Curses.setpos(0, 1)
      Curses.attron(color_pair(color)){
        Curses.addstr("#{deb} Kb")
      }
      Curses.refresh
      break if close_screen
    end
  end

  def graph_all
    # boucle infini pour le moniteur
    while true
      if @lines != Curses.lines
        @lines = Curses.lines
        @positions = reset_screen
      end
      if @cols != Curses.cols
        @cols = Curses.cols
        @positions = reset_screen
      end

      # lit le debit entrant sortant avec l'outil ifstat
      stat = `ifstat #{vit} 1 | grep "[0-9]*\.[0-9]*"`

      # on decoupe le resultat de la commande pour avoir juste les debits
      istat = stat.match(/(\d+\.\d+)\ +(\d+\.\d+)/)
      desc = istat[1]
      nb1 = (desc.to_f / (@desc_max.to_f / @lines).to_f).to_i + 1
      asc = istat[2]
      nb2 = (asc.to_f / (@asc_max.to_f / @lines).to_f).to_i + 1
      
      # initialisation du tableau temporaire
      tmp = [[]]
      i = 0

      # ajout du dernier debit descendant
      while i < @lines
        if i == lines - 2
          tmp[0].push(@sym)
        elsif i <= @lines - nb1
          tmp[0].push(' ')
        else
          tmp[0].push(@sym)
        end
        i += 1
      end

      i = 0
      tmp[@cols / 2] = []
      while i < @lines
        if i == @lines - 2
          tmp[@cols / 2].push(@sym)
        elsif i <= @lines - nb2
          tmp[@cols / 2].push(' ')
        else
          tmp[@cols / 2].push(@sym)
        end
        i += 1
      end 

      # decale tout le tableau pour ajouter les nou
      i = 1
      @positions.each do |pos|
        if i == cols / 2
          i += 1
          next
        end
        tmp[i] = pos
        if i >= @positions.length
          break
        end
        i += 1
      end

      @positions = tmp
      i = 1
      @positions.each do |pos|
        j = 0
        pos.each do |x|
          # place le curseur sur chaqu'une des cases du terminal
          Curses.setpos(j + 1, i)
          # affichage du debit descendant en rouge
          if i < @cols / 2 + 1
            Curses.attron(color_pair(COLOR_RED)){
              Curses.addstr(x)
            }
          # affichage du debit ascendant en vers
          else
            Curses.attron(color_pair(COLOR_GREEN)){
              Curses.addstr(x)
            }
          end 
          j += 1
        end
        i += 1
      end
    
      # vide la premiere ligne
      Curses.setpos(0, 0)
      Curses.attron(color_pair(COLOR_RED)){
        Curses.addstr(" "*cols)
      }
      # affiche le le debit descendant en haut a gauche
      Curses.setpos(0, 1)
      Curses.attron(color_pair(COLOR_RED)){
        Curses.addstr("#{desc} Kb")
      }
      # affiche le debit ascendant en haut au milieu
      Curses.setpos(0, cols / 2 + 1)
      Curses.attron(color_pair(COLOR_GREEN)){
        Curses.addstr("#{asc} Kb")
      }
      Curses.refresh
      break if close_screen
    end
  end

  def reset_screen
    # initialisation du tableau avec des cases vides
    @positions = []
    i = 0
    while i < @cols
      j = 0
      @positions[i] = []
      while j < @lines
        @positions[i].push(' ')
        j += 1
      end
      i += 1
    end
    @positions
  end

  def close_screen
    begin
      key = STDIN.read_nonblock(1)
      if key == 'q'
        Curses.close_screen
        return true
      end
      false
    rescue Errno::EINTR
      false
    rescue Errno::EAGAIN
      false
    rescue EOFError
      Curses.close_screen
      true
    end
  end

  def get_params
    i=0
    # verification des arguments passés
    if !ARGV.empty?
      ARGV.each do |arg|
        if arg.match(/^\-\-vit/)
          arg_vit = arg.match(/\-\-vitesse\=((\d|\.)+)/)
          if !arg_vit.nil?
            @vit = arg_vit[1].to_f
          end
        elsif arg.match(/^\-\-ascendant/)
          arg_asc = arg.match(/\-\-asc\=(\d+)/)
          if !arg_asc.nil?
            @asc_max = arg_asc[1].to_i
          end
        elsif arg.match(/^\-\-desc/)
          arg_desc = arg.match(/\-\-descendant\=(\d+)/)
          if !arg_desc.nil?
            @desc_max = arg_desc[1].to_i
          end
        elsif arg.match(/^\-v/)
          if ARGV[i+1].to_f > 0
            @vit = ARGV[i+1].to_f
          end
        elsif arg.match(/^\-asc/)
          if ARGV[i+1].to_f > 0
            @asc_max = ARGV[i+1].to_f
          end
        elsif arg.match(/^\-desc/)
          if ARGV[i+1].to_f > 0
            @desc_max = ARGV[i+1].to_f
          end
        elsif arg.match(/^\-noasc/) || arg.match(/^\-\-no\-ascendant/)
          @noasc = true
        elsif arg.match(/^\-nodesc/) || arg.match(/^\-\-no\-descendant/)
          @nodesc = true
        elsif arg.match(/^\-s/)
          if ARGV[i+1].length == 1
            @sym = ARGV[i+1]
          end
        elsif arg.match(/^\-\-symbole/)
          arg_sym = arg.match(/^\-\-symbole\=(.)$/)
          if !arg_sym.nil?
            @sym = arg_sym[1]
          end
        elsif arg.match(/^\-\-help/) || arg.match(/^\-h/)
          puts "Utilisation : ruby stat.rb [OPTION]...
Affiche le moniteur des débits montant et descendant.
-asc, --ascendant                 Debit maximum montant
-desc, --desc                     Debit maximum descendant
-noasc, --no-ascendant            N'affiche pas le graphique du debit ascendant
-nodesc, --no-descendant          N'affiche pas le graphique du debit descendant
-s, --symbole                     Modifie le symbole utilisé pour le graphique
-v, --vitesse                   Vitesse du calcul de débit (en seconde)

-h, --help                        Affiche l'aide et quitte
"
          abort    
        end
        i += 1
      end
    end
    true
  end
end

stat = Stat.new
stat.run
